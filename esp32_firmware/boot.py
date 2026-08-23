# This file is executed on every boot
import ujson
import ubinascii
import utime as time
import gc
import sys
from machine import Pin, WDT
from bluetooth import BLE, UUID

# ==================== BLE库 ====================
UART_SERVICE_UUID = UUID('6E400001-B5A3-F393-E0A9-E50E24DCCA9E')
UART_TX_CHAR_UUID = UUID('6E400003-B5A3-F393-E0A9-E50E24DCCA9E')
UART_RX_CHAR_UUID = UUID('6E400002-B5A3-F393-E0A9-E50E24DCCA9E')

class BLEClient:
    def __init__(self, ble):
        self._ble = ble
        self.is_connected = False
    def send(self, data):
        self._ble.send(data)

class BLE:
    def __init__(self, name):
        self.name = name
        self._ble = BLE()
        self._ble.active(False)
        self._ble.config(gap_name=name)
        self._connected = False
        self._on_connect = None
        self._on_disconnect = None
        self._on_rx = None
        self._conn_handle = None
        self._tx_handle = None
        self._rx_handle = None
        self.scanning = False
        self._services_registered = False

    @property
    def is_connected(self):
        return self._connected

    def start_advertising(self):
        self.scanning = True
        try:
            self._ble.active(True)
            if not self._services_registered:
                self._register_services()
            self._ble.gap_advertise(100 * 1000, adv_data=bytes([0x02, 0x01, 0x06, 0x03, 0x03, 0x00, 0x40, 0x6E]), scan_rsp=None)
            self._ble.irq(self._irq_handler)
        except Exception as e:
            print('[BLE] 广播启动失败:', e)

    def stop_advertising(self):
        self.scanning = False
        try:
            self._ble.gap_advertise(None)
        except:
            pass

    def _register_services(self):
        try:
            services = (
                (UART_SERVICE_UUID, (
                    (UART_TX_CHAR_UUID, 0x0012),
                    (UART_RX_CHAR_UUID, 0x0008),
                )),
            )
            ((self._tx_handle, self._rx_handle),) = self._ble.gatts_register_services(services)
            self._services_registered = True
        except Exception as e:
            print('[BLE] 服务注册失败:', e)

    def _irq_handler(self, event, data):
        if event == 1:
            self._conn_handle = data[0]
            self._connected = True
            self.scanning = False
            if self._on_connect:
                self._on_connect()
        elif event == 2:
            self._connected = False
            self._conn_handle = None
            if self._on_disconnect:
                self._on_disconnect()
        elif event == 3:
            if self._on_rx:
                value = self._ble.gatts_read(self._rx_handle)
                self._on_rx(value)

    def on_connect(self, callback):
        self._on_connect = callback
    def on_disconnect(self, callback):
        self._on_disconnect = callback
    def on_rx(self, callback):
        self._on_rx = callback
    def send(self, data):
        if self._connected and self._tx_handle is not None:
            try:
                self._ble.gatts_notify(self._conn_handle, self._tx_handle, data)
            except Exception as e:
                print('[BLE] 发送失败:', e)
    def reset(self):
        try:
            self._ble.active(False)
            time.sleep_ms(200)
            self._connected = False
            self._conn_handle = None
            self._services_registered = False
            print('[BLE] BLE协议栈已重置')
        except Exception as e:
            print('[BLE] 重置失败:', e)

# ==================== 配置 ====================
CONFIG_FILE = 'config.json'
DEFAULT_PASSWORD = '13092991951'
DEFAULT_DEVICE_NAME = '陕A0P92Y'
DEFAULT_GPIO_LOCK = 14
DEFAULT_GPIO_UNLOCK = 33
DEFAULT_GPIO_TRUNK = 4
WDT_TIMEOUT_MS = 30000

# ==================== 状态 ====================
admin_password = DEFAULT_PASSWORD
admin_device = None
admin_last_seen = 0
device_name = DEFAULT_DEVICE_NAME
auto_lock = True
borrow_code = None
borrow_expiry_epoch = 0
ble_error_count = 0
last_ble_error = 0

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
    global device_name, auto_lock
    try:
        with open(CONFIG_FILE, 'r') as f:
            cfg = ujson.load(f)
        admin_password = cfg.get('admin_password', DEFAULT_PASSWORD)
        admin_device = cfg.get('admin_device', None)
        borrow_code = cfg.get('borrow_code', None)
        borrow_expiry_epoch = cfg.get('borrow_expiry_epoch', 0)
        device_name = cfg.get('device_name', DEFAULT_DEVICE_NAME)
        auto_lock = cfg.get('auto_lock', True)
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
            'device_name': device_name,
            'auto_lock': auto_lock,
        }
        with open(CONFIG_FILE, 'w') as f:
            ujson.dump(cfg, f)
        print('[CONFIG] 已保存')
    except Exception as e:
        print('[CONFIG] 保存失败:', e)

# ==================== 日志（问题2: 200条+2天清理） ====================
LOG_MAX = 200
LOG_MAX_AGE = 7 * 24 * 3600
log_entries = []

def log(msg):
    ts = time.time()
    t = time.localtime()
    tstr = '{:04d}-{:02d}-{:02d} {:02d}:{:02d}:{:02d}'.format(t[0], t[1], t[2], t[3], t[4], t[5])
    log_entries.append({'time': ts, 'text': '[{}] {}'.format(tstr, msg)})
    _clean_logs()
    print('[{}] {}'.format(tstr, msg))
    gc.collect()

def _clean_logs():
    now = time.time()
    log_entries[:] = [e for e in log_entries if now - e['time'] < LOG_MAX_AGE]
    while len(log_entries) > LOG_MAX:
        log_entries.pop(0)

def log_get_all():
    gc.collect()
    return '\n'.join(['[{}] {}'.format(e['text'].split('] ')[0] + ']', e['text'].split('] ')[1] if '] ' in e['text'] else e['text']) for e in log_entries[-50:]]) if log_entries else '无日志'

# ==================== 安全保护 ====================
def safety_lock_all():
    try:
        gpio_lock.value(0)
        gpio_unlock.value(0)
        gpio_trunk.value(0)
        log('安全保护: 所有GPIO已锁定')
    except Exception as e:
        log('安全保护失败: ' + str(e))

def auto_lock_action():
    if auto_lock:
        safety_lock_all()
        log('自动落锁: 已执行')
    else:
        log('自动落锁: 未开启，跳过')

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
    global device_name, auto_lock
    cmd = cmd_str.strip()
    log('处理命令: ' + cmd)

    if cmd == 'suoche':
        gpio_pulse(gpio_lock)
        return 'OK suoche'
    elif cmd == 'jiesuo':
        gpio_pulse(gpio_unlock)
        return 'OK jiesuo'
    elif cmd == 'xunche':
        gpio_pulse(gpio_lock, 300)
        gpio_pulse(gpio_lock, 300)
        return 'OK xunche'
    elif cmd == 'chuangsheng':
        gpio_hold(gpio_lock, 7)
        return 'OK chuangsheng'
    elif cmd == 'chuangjiang':
        gpio_hold(gpio_unlock, 7)
        return 'OK chuangjiang'
    elif cmd == 'houbeixiang':
        gpio_hold(gpio_trunk, 7)
        return 'OK houbeixiang'
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
    elif cmd == '!TIMEREQ':
        return 'OK TIMEREQ'
    elif cmd.startswith('!PWD '):
        pwd = cmd.split(' ', 1)[1]
        if len(pwd) >= 6:
            admin_password = pwd
            save_config()
            log('密码已更新')
            return 'OK PWD'
        return 'ERR PWD_LEN'
    elif cmd.startswith('!NAME '):
        name = cmd.split(' ', 1)[1]
        device_name = name
        try:
            ble._ble.config(gap_name=name)
        except:
            pass
        save_config()
        log('设备名已更新: ' + name)
        return 'OK NAME'
    elif cmd.startswith('!BORROW '):
        parts = cmd.split(' ')
        if len(parts) >= 3:
            borrow_code = parts[1]
            try:
                borrow_expiry_epoch = int(parts[2])
            except:
                borrow_expiry_epoch = time.time() + 3600 * 24
            save_config()
            log('临时密码已设置: ' + borrow_code + ' 过期: ' + str(borrow_expiry_epoch))
            return 'OK BORROW'
        return 'ERR BORROW_FMT'
    elif cmd == '!BORROWCLEAR':
        borrow_code = None
        borrow_expiry_epoch = 0
        save_config()
        log('临时密码已清除')
        return 'OK BORROWCLEAR'
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
        log('临时密码验证通过')
        return 'OK VERIFYBORROW'
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
        device_name = DEFAULT_DEVICE_NAME
        auto_lock = True
        save_config()
        log('已恢复出厂设置')
        return 'OK RESET'
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
    global ble_error_count
    ble_error_count = 0
    led_blink(2, 100)
    led_on()
    log('BLE已连接')
    if ble_client and ble_client.is_connected():
        try:
            ble_client.send(b'!TIMEREQ')
            log('已请求APP同步时间')
        except:
            pass

def on_disconnect():
    led_off()
    auto_lock_action()
    log('BLE已断开，执行安全保护')

# ==================== 主程序 ====================
load_config()
log('系统启动')
log('管理员密码: ' + admin_password[:4] + '****')
log('管理员设备: ' + str(admin_device))

ble = BLE(device_name)
ble_client = BLEClient(ble)
ble.on_connect(on_connect)
ble.on_disconnect(on_disconnect)
ble.on_rx(on_rx)
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
        ble_error_count += 1
        last_ble_error = time.time()
        if ble_error_count >= 5:
            log('BLE异常次数过多，重置BLE协议栈')
            try:
                ble.reset()
                time.sleep_ms(500)
                ble = BLE(device_name)
                ble_client = BLEClient(ble)
                ble.on_connect(on_connect)
                ble.on_disconnect(on_disconnect)
                ble.on_rx(on_rx)
                ble_error_count = 0
                log('BLE协议栈已恢复')
            except Exception as e2:
                print('[MAIN] BLE恢复失败:', e2)
        time.sleep(1)
        gc.collect()
