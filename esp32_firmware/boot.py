# This file is executed on every boot
import ujson
import ubinascii
import utime as time
import gc
import sys
import struct
import machine
from machine import Pin, WDT
from bluetooth import BLE, UUID

# ==================== BLE库 ====================
UART_SERVICE_UUID = UUID('6E400001-B5A3-F393-E0A9-E50E24DCCA9E')
UART_TX_CHAR_UUID = UUID('6E400003-B5A3-F393-E0A9-E50E24DCCA9E')
UART_RX_CHAR_UUID = UUID('6E400002-B5A3-F393-E0A9-E50E24DCCA9E')

class BLEClient:
    def __init__(self, ble_server):
        self._ble = ble_server
    @property
    def is_connected(self):
        return self._ble.is_connected
    def send(self, data):
        self._ble.send(data)

class BLEServer:
    def __init__(self, name):
        self.name = name
        self._ble = BLE()
        self._connected = False
        self._on_connect = None
        self._on_disconnect = None
        self._on_rx = None
        self._conn_handle = None
        self._tx_handle = None
        self._rx_handle = None
        self.scanning = False
        self._init_ble()

    @property
    def is_connected(self):
        return self._connected

    def _init_ble(self):
        try:
            self._ble.active(False)
            time.sleep_ms(200)
            self._ble.active(True)
            time.sleep_ms(100)
            self._ble.irq(self._irq_handler)
            ((self._tx_handle, self._rx_handle),) = self._ble.gatts_register_services((
                (UART_SERVICE_UUID, (
                    (UART_TX_CHAR_UUID, 0x0010),
                    (UART_RX_CHAR_UUID, 0x000C),
                )),
            ))
            try:
                self._ble.gatts_set_buffer(self._rx_handle, 128)
            except:
                pass
            self._ble.config(gap_name=self.name)
            print('[BLE] BLE初始化完成')
        except Exception as e:
            print('[BLE] BLE初始化失败:', e)

    def _gen_adv(self):
        adv = struct.pack('BBB', 2, 1, 6)
        name = self.name.encode()
        adv += struct.pack('BB', len(name) + 1, 9) + name
        return adv

    def start_advertising(self):
        self.scanning = True
        try:
            self._ble.gap_advertise(None)
            time.sleep_ms(20)
            self._ble.gap_advertise(100, self._gen_adv())
            print('[BLE] 广播已启动')
        except Exception as e:
            print('[BLE] 广播启动失败:', e)
            self.scanning = False

    def stop_advertising(self):
        self.scanning = False
        try:
            self._ble.gap_advertise(None)
        except:
            pass

    def ble_reset(self):
        try:
            self._ble.active(False)
            time.sleep_ms(200)
            self._ble.active(True)
            time.sleep_ms(100)
            self._ble.irq(self._irq_handler)
            ((self._tx_handle, self._rx_handle),) = self._ble.gatts_register_services((
                (UART_SERVICE_UUID, (
                    (UART_TX_CHAR_UUID, 0x0010),
                    (UART_RX_CHAR_UUID, 0x000C),
                )),
            ))
            try:
                self._ble.gatts_set_buffer(self._rx_handle, 128)
            except:
                pass
            self._ble.config(gap_name=self.name)
            self._connected = False
            self._conn_handle = None
            self.scanning = False
            self.start_advertising()
            print('[BLE] BLE协议栈已重置')
        except Exception as e:
            print('[BLE] 重置失败:', e)

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
            self.scanning = False
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
            print('[BLE] BLE协议栈已重置')
        except Exception as e:
            print('[BLE] 重置失败:', e)

# ==================== 配置 ====================
CONFIG_FILE = 'config.json'
DEFAULT_PASSWORD = '123456789'
DEFAULT_DEVICE_NAME = '陕A0P92Y'
DEFAULT_GPIO_LOCK = 14
DEFAULT_GPIO_UNLOCK = 33
DEFAULT_GPIO_TRUNK = 4
WDT_TIMEOUT_MS = 60000

# ==================== 功耗配置 ====================
# OBD持续供电，但BLE广播仍耗电~80mA
# 档位1: 全速运行（BLE已连接）
# 档位2: 待机广播（BLE断开，保持广播等连接）
# 档位3: 深度睡眠（断开超过10分钟，省电模式）
POWER_MODE_FULL = 0
POWER_MODE_IDLE = 1
POWER_MODE_DEEP_SLEEP = 2

DEEP_SLEEP_TIMEOUT = 600       # 断开多久后深度睡眠（秒）= 10分钟
SLEEP_WAKE_WINDOW = 120        # 深度睡眠唤醒后广播多久（秒）= 2分钟

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
session_authenticated = False
session_is_borrower = False
power_mode = POWER_MODE_IDLE
disconnect_time = None
waking_from_sleep = False
wake_start_time = None

# ==================== GPIO ====================
try:
    gpio_lock = Pin(DEFAULT_GPIO_LOCK, Pin.OUT, value=0)
    gpio_unlock = Pin(DEFAULT_GPIO_UNLOCK, Pin.OUT, value=0)
    gpio_trunk = Pin(DEFAULT_GPIO_TRUNK, Pin.OUT, value=0)
except Exception as e:
    print('[INIT] GPIO配置失败:', e)

# ==================== WDT ====================
wdt = None

def feed_wdt():
    if wdt: wdt.feed()

# ==================== 功耗管理 ====================
def set_power_mode(new_mode):
    global power_mode, disconnect_time
    if new_mode == power_mode:
        return
    power_mode = new_mode
    if new_mode == POWER_MODE_FULL:
        print('[POWER] 全速运行')
        disconnect_time = None
    elif new_mode == POWER_MODE_IDLE:
        print('[POWER] 待机广播')
        ble.start_advertising()
        disconnect_time = time.time()
    elif new_mode == POWER_MODE_DEEP_SLEEP:
        print('[POWER] 深度睡眠')
        safety_lock_all()
        time.sleep_ms(100)
        sleep_us = SLEEP_WAKE_WINDOW * 1000 * 1000
        machine.deepsleep(sleep_us)

def check_power_transition():
    global power_mode, waking_from_sleep
    if ble.is_connected:
        set_power_mode(POWER_MODE_FULL)
        return
    if power_mode == POWER_MODE_FULL:
        set_power_mode(POWER_MODE_IDLE)
        return
    if power_mode == POWER_MODE_IDLE and disconnect_time is not None:
        elapsed = time.time() - disconnect_time
        if elapsed >= DEEP_SLEEP_TIMEOUT:
            set_power_mode(POWER_MODE_DEEP_SLEEP)

def detect_wake_source():
    global waking_from_sleep, wake_start_time
    try:
        cause = machine.reset_cause()
        if cause == 4:
            waking_from_sleep = True
            wake_start_time = time.time()
            print('[SLEEP] 从深度睡眠唤醒，广播', SLEEP_WAKE_WINDOW, '秒')
        else:
            waking_from_sleep = False
    except:
        waking_from_sleep = False

def check_wake_window():
    global waking_from_sleep
    if not waking_from_sleep or wake_start_time is None:
        return
    if time.time() - wake_start_time >= SLEEP_WAKE_WINDOW:
        print('[SLEEP] 唤醒窗口结束，重新深度睡眠')
        safety_lock_all()
        time.sleep_ms(100)
        machine.deepsleep(SLEEP_WAKE_WINDOW * 1000 * 1000)

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

config_dirty = False

def save_config():
    global config_dirty
    if not config_dirty:
        return
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
        config_dirty = False
        print('[CONFIG] 已保存')
    except Exception as e:
        print('[CONFIG] 保存失败:', e)

# ==================== 安全保护 ====================
def safety_lock_all():
    try:
        gpio_lock.value(0)
        gpio_unlock.value(0)
        gpio_trunk.value(0)
        print('安全保护: 所有GPIO已锁定(低电平)')
    except Exception as e:
        print('安全保护失败: ' + str(e))

def auto_lock_action():
    if auto_lock:
        gpio_pulse(gpio_lock, 150)
        time.sleep_ms(100)
        gpio_pulse(gpio_lock, 150)
        print('自动落锁: 已执行两次锁车脉冲')
    else:
        print('自动落锁: 未开启，跳过')

# ==================== GPIO控制 ====================
hold_pin = None
hold_end_time = 0

def gpio_pulse(pin, ms=200):
    try:
        pin.value(1); time.sleep_ms(ms); pin.value(0)
        print('GPIO脉冲完成')
    except Exception as e:
        print('GPIO脉冲失败: ' + str(e))

def gpio_hold_start(pin, seconds=7):
    global hold_pin, hold_end_time
    try:
        pin.value(1)
        hold_pin = pin
        hold_end_time = time.time() + seconds
        print('GPIO保持开始:', seconds, '秒')
    except Exception as e:
        print('GPIO保持失败: ' + str(e))

def gpio_hold_check():
    global hold_pin, hold_end_time
    if hold_pin is not None and time.time() >= hold_end_time:
        hold_pin.value(0)
        print('GPIO保持完成')
        hold_pin = None

# ==================== 命令处理 ====================
def process_command(cmd_str):
    global admin_password, admin_device, admin_last_seen
    global borrow_code, borrow_expiry_epoch
    global device_name, auto_lock
    global session_authenticated, session_is_borrower
    cmd = cmd_str.strip()
    print('处理命令: ' + cmd)

    # ===== 无需认证的指令 =====
    if cmd.startswith('!AUTH '):
        parts = cmd.split(' ', 2)
        if len(parts) >= 3:
            pwd = parts[1]
            device_id = parts[2]
            if pwd == admin_password:
                admin_device = device_id
                admin_last_seen = time.time()
                session_authenticated = True
                session_is_borrower = False
                config_dirty = True
                save_config()
                print('管理员认证成功: ' + device_id)
                return 'OK AUTH'
            else:
                print('管理员认证失败')
                return 'ERR AUTH_FAIL'
        return 'ERR AUTH_FMT'
    elif cmd.startswith('!VERIFYBORROW '):
        pwd = cmd.split(' ', 1)[1]
        if borrow_code is None:
            print('临时密码验证失败: 无临时密码')
            return 'ERR NO_BORROW'
        if pwd != borrow_code:
            print('临时密码验证失败: 密码不匹配')
            return 'ERR BORROW_FAIL'
        if borrow_expiry_epoch > 0 and time.time() > borrow_expiry_epoch:
            print('临时密码验证失败: 已过期')
            borrow_code = None
            borrow_expiry_epoch = 0
            config_dirty = True
            save_config()
            return 'ERR BORROW_EXPIRED'
        session_authenticated = True
        session_is_borrower = True
        print('临时密码验证通过')
        return 'OK VERIFYBORROW'
    elif cmd.startswith('!DEVID '):
        device_id = cmd.split(' ', 1)[1] if len(cmd.split(' ')) > 1 else ''
        if admin_device and (device_id.startswith(admin_device) or admin_device.startswith(device_id)):
            admin_last_seen = time.time()
            session_authenticated = True
            session_is_borrower = False
            print('管理员设备确认: ' + device_id)
            return 'OK DEVID'
        elif admin_device is None:
            print('无管理员绑定，需通过!AUTH认证: ' + device_id)
            return 'ERR NO_ADMIN'
        else:
            print('非管理员设备: ' + device_id + ' (管理员: ' + str(admin_device) + ')')
            return 'ERR NOT_ADMIN'
    elif cmd.startswith('!TIME '):
        try:
            ts = int(cmd.split(' ', 1)[1])
            rtc = machine.RTC()
            tm = time.localtime(ts)
            rtc.init((tm[0], tm[1], tm[2], tm[6], tm[3], tm[4], tm[5], 0))
            print('时间同步: ' + str(ts))
            return 'OK TIME'
        except Exception as e:
            return 'ERR TIME: ' + str(e)
    elif cmd == '!TIMEREQ':
        return 'OK TIMEREQ'

    # ===== 以下指令需要已认证 =====
    if not session_authenticated:
        print('未认证，拒绝执行: ' + cmd)
        return 'ERR NOT_AUTH'

    # 临时借车不能执行以下管理指令
    if session_is_borrower:
        if cmd.startswith('!PWD ') or cmd.startswith('!NAME ') or cmd.startswith('!BORROW ') or cmd == '!BORROWCLEAR' or cmd == '!RESET' or cmd.startswith('!AUTOLOCK'):
            print('临时借车无权执行管理指令: ' + cmd)
            return 'ERR NO_PERM'

    # ===== 车辆控制指令（需认证） =====
    if cmd == 'suoche':
        gpio_pulse(gpio_lock)
        return 'OK suoche'
    elif cmd == 'jiesuo':
        gpio_pulse(gpio_unlock)
        return 'OK jiesuo'
    elif cmd == 'xunche':
        gpio_pulse(gpio_lock, 150)
        time.sleep_ms(100)
        gpio_pulse(gpio_lock, 150)
        return 'OK xunche'
    elif cmd == 'chuangsheng':
        gpio_hold_start(gpio_lock, 7)
        return 'OK chuangsheng'
    elif cmd == 'chuangjiang':
        gpio_hold_start(gpio_unlock, 7)
        return 'OK chuangjiang'
    elif cmd == 'houbeixiang':
        gpio_hold_start(gpio_trunk, 7)
        return 'OK houbeixiang'

    # ===== 管理指令（仅管理员） =====
    elif cmd.startswith('!PWD '):
        pwd = cmd.split(' ', 1)[1]
        if len(pwd) >= 6:
            admin_password = pwd
            config_dirty = True
            save_config()
            print('密码已更新')
            return 'OK PWD'
        return 'ERR PWD_LEN'
    elif cmd.startswith('!NAME '):
        name = cmd.split(' ', 1)[1]
        device_name = name
        config_dirty = True
        save_config()
        try:
            ble.stop_advertising()
            time.sleep_ms(100)
            ble.start_advertising()
        except:
            pass
        print('设备名已更新: ' + name)
        return 'OK NAME'
    elif cmd.startswith('!BORROW '):
        parts = cmd.split(' ')
        if len(parts) >= 3:
            borrow_code = parts[1]
            try:
                borrow_expiry_epoch = int(parts[2])
            except:
                borrow_expiry_epoch = time.time() + 3600 * 24
            config_dirty = True
            save_config()
            print('临时密码已设置: ' + borrow_code + ' 过期: ' + str(borrow_expiry_epoch))
            return 'OK BORROW'
        return 'ERR BORROW_FMT'
    elif cmd == '!BORROWCLEAR':
        borrow_code = None
        borrow_expiry_epoch = 0
        config_dirty = True
        save_config()
        print('临时密码已清除')
        return 'OK BORROWCLEAR'
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
        session_authenticated = False
        session_is_borrower = False
        config_dirty = True
        save_config()
        print('已恢复出厂设置')
        return 'OK RESET'
    else:
        print('未知命令: ' + cmd)
        return 'ERR UNKNOWN'

# ==================== BLE回调 ====================
pending_commands = []
pending_disconnect = False
pending_connect = False

def on_rx(data):
    global pending_commands
    try:
        cmd_str = data.decode('utf-8').strip()
        pending_commands.append(cmd_str)
    except Exception as e:
        print('[BLE] 数据解析异常:', e)

def on_connect():
    global ble_error_count, pending_connect, power_mode, disconnect_time
    ble_error_count = 0
    pending_connect = True
    disconnect_time = None
    power_mode = POWER_MODE_FULL
    print('[BLE] 已连接 → 全速运行')

def on_disconnect():
    global pending_disconnect, session_authenticated, session_is_borrower
    pending_disconnect = True
    session_authenticated = False
    session_is_borrower = False

# ==================== 主程序 ====================
detect_wake_source()
load_config()
print('系统启动')
print('管理员密码: ' + admin_password[:4] + '****')
print('管理员设备: ' + str(admin_device))
print('[POWER] 功耗管理: 全速→待机→深度睡眠')
print('[POWER] 深度睡眠超时:', DEEP_SLEEP_TIMEOUT, '秒')

ble = BLEServer(device_name)
ble_client = BLEClient(ble)
ble.on_connect(on_connect)
ble.on_disconnect(on_disconnect)
ble.on_rx(on_rx)

if waking_from_sleep:
    ble.start_advertising()
    power_mode = POWER_MODE_FULL
    print('[SLEEP] 唤醒后广播', SLEEP_WAKE_WINDOW, '秒')
else:
    ble.start_advertising()
    power_mode = POWER_MODE_IDLE
    disconnect_time = time.time()

gc.collect()
print('[MAIN] 等待连接...')

while True:
    try:
        feed_wdt()
        gpio_hold_check()

        if not ble.is_connected:
            if pending_disconnect:
                pending_disconnect = False
                auto_lock_action()
                print('[BLE] 已断开')
                if power_mode == POWER_MODE_FULL:
                    set_power_mode(POWER_MODE_IDLE)

            check_power_transition()
            check_wake_window()
        else:
            if power_mode != POWER_MODE_FULL:
                set_power_mode(POWER_MODE_FULL)

        if ble.is_connected and pending_connect:
            pending_connect = False
        if ble.is_connected and pending_commands:
            cmd_str = pending_commands.pop(0)
            result = process_command(cmd_str)
            if result and ble_client and ble_client.is_connected:
                ble_client.send(result.encode('utf-8'))
                print('[BLE] 已回复:', result)
        gc.collect()
        time.sleep_ms(30 if ble.is_connected else 500)
    except KeyboardInterrupt:
        print('[MAIN] 用户中断')
        break
    except Exception as e:
        print('[MAIN] 主循环异常:', e)
        ble_error_count += 1
        last_ble_error = time.time()
        if ble_error_count >= 5:
            print('[MAIN] BLE异常次数过多，重置BLE协议栈')
            try:
                ble.ble_reset()
                ble_error_count = 0
                print('[MAIN] BLE协议栈已恢复')
            except Exception as e2:
                print('[MAIN] BLE恢复失败:', e2)
        time.sleep(1)
        gc.collect()
