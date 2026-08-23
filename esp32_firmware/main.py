import ujson
import ubinascii
import utime as time
import gc
import sys
from machine import Pin, WDT
from ble_simple_peripheral import BLE, BLEClient

# ==================== 配置 ====================
CONFIG_FILE = 'config.json'
DEFAULT_PASSWORD = '13092991951'
DEFAULT_DEVICE_NAME = '陕A0P92Y'
DEFAULT_GPIO_LOCK = 14
DEFAULT_GPIO_UNLOCK = 33
DEFAULT_GPIO_TRUNK = 4
ADMIN_TTL = 3600 * 24
WDT_TIMEOUT_MS = 30000

# ==================== 状态 ====================
admin_password = DEFAULT_PASSWORD
admin_device = None
admin_last_seen = 0
borrow_code = None
borrow_expiry_epoch = 0
pending_actions = []

# ==================== GPIO ====================
try:
    gpio_lock = Pin(DEFAULT_GPIO_LOCK, Pin.OUT, value=0)
    gpio_unlock = Pin(DEFAULT_GPIO_UNLOCK, Pin.OUT, value=0)
    gpio_trunk = Pin(DEFAULT_GPIO_TRUNK, Pin.OUT, value=0)
except Exception as e:
    print('[INIT] GPIO配置失败:', e)

# ==================== LED ====================
try:
    led = Pin(2, Pin.OUT, value=0)
except:
    led = None

def led_blink(times, interval=200):
    if not led: return
    for _ in range(times):
        led.value(1); time.sleep_ms(interval); led.value(0); time.sleep_ms(interval)

def led_on():
    if led: led.value(1)

def led_off():
    if led: led.value(0)

# ==================== WDT ====================
try:
    wdt = WDT(timeout=WDT_TIMEOUT_MS)
except:
    wdt = None

def feed_wdt():
    if wdt: wdt.feed()

# ==================== 配置持久化 ====================
def load_config():
    global admin_password, admin_device, borrow_code, borrow_expiry_epoch
    try:
        with open(CONFIG_FILE, 'r') as f:
            cfg = ujson.load(f)
        admin_password = cfg.get('admin_password', DEFAULT_PASSWORD)
        admin_device = cfg.get('admin_device', None)
        borrow_code = cfg.get('borrow_code', None)
        borrow_expiry_epoch = cfg.get('borrow_expiry_epoch', 0)
        print('[CONFIG] 加载成功')
    except:
        print('[CONFIG] 无配置或损坏，使用默认值')
        save_config()

def save_config():
    try:
        cfg = {
            'admin_password': admin_password,
            'admin_device': admin_device,
            'borrow_code': borrow_code,
            'borrow_expiry_epoch': borrow_expiry_epoch,
        }
        with open(CONFIG_FILE, 'w') as f:
            ujson.dump(cfg, f)
        print('[CONFIG] 已保存')
    except Exception as e:
        print('[CONFIG] 保存失败:', e)

# ==================== 日志 ====================
LOG_MAX = 30
log_lines = []
def log(msg):
    ts = time.localtime()
    t = '{:02d}:{:02d}:{:02d}'.format(ts[3], ts[4], ts[5])
    line = '[{}] {}'.format(t, msg)
    log_lines.append(line)
    if len(log_lines) > LOG_MAX:
        log_lines.pop(0)
    print(line)
    gc.collect()

def log_get_all():
    gc.collect()
    return '\n'.join(log_lines) if log_lines else '无日志'

# ==================== GPIO控制 ====================
def gpio_pulse(pin, ms=500):
    try:
        pin.value(1); time.sleep_ms(ms); pin.value(0)
        log('GPIO脉冲完成')
    except Exception as e:
        log('GPIO脉冲失败: ' + str(e))

def gpio_hold(pin, seconds=7):
    try:
        pin.value(1); time.sleep(seconds); pin.value(0)
        log('GPIO保持完成')
    except Exception as e:
        log('GPIO保持失败: ' + str(e))

# ==================== 命令处理 ====================
def process_command(cmd_str):
    global admin_password, admin_device, admin_last_seen
    global borrow_code, borrow_expiry_epoch
    cmd = cmd_str.strip()
    log('处理命令: ' + cmd)

    # 锁车
    if cmd == 'suoche':
        gpio_pulse(gpio_lock)
        return 'OK suoche'
    # 解锁
    elif cmd == 'jiesuo':
        gpio_pulse(gpio_unlock)
        return 'OK jiesuo'
    # 寻车
    elif cmd == 'xunche':
        gpio_pulse(gpio_lock, 300)
        time.sleep_ms(200)
        gpio_pulse(gpio_lock, 300)
        return 'OK xunche'
    # 车窗升
    elif cmd == 'chuangsheng':
        gpio_hold(gpio_lock, 7)
        return 'OK chuangsheng'
    # 车窗降
    elif cmd == 'chuangjiang':
        gpio_hold(gpio_unlock, 7)
        return 'OK chuangjiang'
    # 后备箱
    elif cmd == 'houbeixiang':
        gpio_hold(gpio_trunk, 7)
        return 'OK houbeixiang'
    # 管理员认证
    elif cmd.startswith('!AUTH '):
        parts = cmd.split(' ', 2)
        if len(parts) >= 3:
            pwd = parts[1]
            device_id = parts[2]
            if pwd == admin_password:
                admin_device = device_id
                admin_last_seen = time.time()
                save_config()
                log('管理员认证成功: ' + device_id)
                return 'OK AUTH'
            else:
                log('管理员认证失败')
                return 'ERR AUTH_FAIL'
        return 'ERR AUTH_FMT'
    # 设备ID注册
    elif cmd.startswith('!DEVID '):
        device_id = cmd.split(' ', 1)[1] if len(cmd.split(' ')) > 1 else ''
        if admin_device == device_id:
            admin_last_seen = time.time()
            log('管理员设备确认: ' + device_id)
            return 'OK DEVID'
        elif admin_device is None:
            admin_device = device_id
            admin_last_seen = time.time()
            save_config()
            log('首次绑定管理员: ' + device_id)
            return 'OK DEVID'
        else:
            log('非管理员设备: ' + device_id)
            return 'ERR NOT_ADMIN'
    # 时间同步
    elif cmd.startswith('!TIME '):
        try:
            ts = int(cmd.split(' ', 1)[1])
            import machine
            rtc = machine.RTC()
            tm = time.localtime(ts)
            rtc.init((tm[0], tm[1], tm[2], tm[6], tm[3], tm[4], tm[5], 0))
            log('时间同步: ' + str(ts))
            return 'OK TIME'
        except Exception as e:
            return 'ERR TIME: ' + str(e)
    # 修改密码
    elif cmd.startswith('!PWD '):
        pwd = cmd.split(' ', 1)[1]
        if len(pwd) >= 6:
            admin_password = pwd
            save_config()
            log('密码已更新')
            return 'OK PWD'
        return 'ERR PWD_LEN'
    # 修改设备名
    elif cmd.startswith('!NAME '):
        name = cmd.split(' ', 1)[1]
        save_config()
        log('设备名已更新: ' + name)
        return 'OK NAME'
    # 临时借车密码
    elif cmd.startswith('!BORROW '):
        parts = cmd.split(' ')
        if len(parts) >= 3:
            borrow_code = parts[1]
            try:
                borrow_expiry_epoch = int(parts[2])
            except:
                borrow_expiry_epoch = time.time() + 3600 * 24
            save_config()
            log('临时密码已设置: ' + borrow_code + ' 过期时间戳: ' + str(borrow_expiry_epoch))
            return 'OK BORROW'
        return 'ERR BORROW_FMT'
    # 清除临时借车密码
    elif cmd == '!BORROWCLEAR':
        borrow_code = None
        borrow_expiry_epoch = 0
        save_config()
        log('临时密码已清除')
        return 'OK BORROWCLEAR'
    # 临时密码验证
    elif cmd.startswith('!VERIFYBORROW '):
        pwd = cmd.split(' ', 1)[1]
        if borrow_code is None:
            log('临时密码验证失败: 无临时密码')
            return 'ERR NO_BORROW'
        if pwd != borrow_code:
            log('临时密码验证失败: 密码不匹配')
            return 'ERR BORROW_FAIL'
        if borrow_expiry_epoch > 0 and time.time() > borrow_expiry_epoch:
            log('临时密码验证失败: 已过期')
            borrow_code = None
            borrow_expiry_epoch = 0
            save_config()
            return 'ERR BORROW_EXPIRED'
        admin_last_seen = time.time()
        log('临时密码验证通过')
        return 'OK VERIFYBORROW'
    # 恢复出厂
    elif cmd == '!RESET':
        try:
            import os
            os.remove(CONFIG_FILE)
        except:
            pass
        admin_password = DEFAULT_PASSWORD
        admin_device = None
        borrow_code = None
        borrow_expiry_epoch = 0
        save_config()
        log('已恢复出厂设置')
        return 'OK RESET'
    # 查询日志
    elif cmd == '!LOG':
        return log_get_all()
    else:
        log('未知命令: ' + cmd)
        return 'ERR UNKNOWN'

# ==================== BLE回调 ====================
def on_rx(data):
    try:
        cmd_str = data.decode('utf-8').strip()
        result = process_command(cmd_str)
        if result and ble_client and ble_client.is_connected():
            ble_client.send(result.encode('utf-8'))
            log('已回复: ' + result)
    except Exception as e:
        log('命令处理异常: ' + str(e))

def on_connect():
    led_blink(2, 100)
    led_on()
    log('BLE已连接')

def on_disconnect():
    led_off()
    log('BLE已断开，执行安全保护')

# ==================== 主程序 ====================
load_config()
log('系统启动')
log('管理员密码: ' + admin_password[:4] + '****')
log('管理员设备: ' + str(admin_device))

ble = BLE(DEFAULT_DEVICE_NAME)
ble_client = None
gc.collect()

print('[MAIN] 启动BLE广播...')
print('[MAIN] 等待连接...')

while True:
    try:
        feed_wdt()
        if not ble.is_connected():
            if ble.scanning:
                pass
            else:
                ble.start_advertising()
                print('[MAIN] 开始广播...')
        gc.collect()
        time.sleep_ms(100)
    except KeyboardInterrupt:
        print('[MAIN] 用户中断')
        break
    except Exception as e:
        print('[MAIN] 主循环异常:', e)
        time.sleep(1)
        gc.collect()
