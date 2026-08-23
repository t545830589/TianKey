from machine import Pin, WDT
import time
import bluetooth
import struct
import gc
import hashlib
import os
import machine

# ===================== 配置区 =====================
PIN_LOCK       = 14
PIN_UNLOCK     = 33
PIN_TRUNK      = 4
PIN_LED        = 2

DEFAULT_NAME   = "陕A0P92Y"
DEFAULT_PWD    = "13092991951"
AUTH_TIMEOUT   = 10
AUTH_FAILURE   = 10000

LOCK_PULSE_MS  = 200
UNLOCK_PULSE_MS = 200
TRUNK_HOLD_MS  = 7000
WINDOW_HOLD_MS = 7000
FIND_CAR_PULSE_MS = 200
FIND_CAR_GAP_MS   = 200

TEMP_VALID     = 6 * 3600
CONFIG_FILE    = "tiankey.cfg"
LOG_FILE       = "tiankey.log"
MAX_LOG_LINES  = 200
LOG_MAX_AGE_DAYS = 7
# =================================================

wdt = WDT(timeout=8000)

lock_pin   = None
unlock_pin = None
trunk_pin  = None
led_pin    = Pin(PIN_LED, Pin.OUT, value=0)

AUTO_LOCK_ENABLED = 1
ADMIN_DEVICE = ""
pending_actions = []


def init_pins():
    global lock_pin, unlock_pin, trunk_pin
    if lock_pin is not None:
        lock_pin.init(Pin.IN)
    if unlock_pin is not None:
        unlock_pin.init(Pin.IN)
    if trunk_pin is not None:
        trunk_pin.init(Pin.IN)
    lock_pin   = Pin(PIN_LOCK, Pin.OUT, value=1)
    unlock_pin = Pin(PIN_UNLOCK, Pin.OUT, value=1)
    trunk_pin  = Pin(PIN_TRUNK, Pin.OUT, value=1)


# ===================== LED状态指示 =====================
def led_blink(count, interval_ms):
    """LED闪烁指定次数"""
    for _ in range(count):
        led_pin.value(1)
        time.sleep_ms(interval_ms)
        led_pin.value(0)
        time.sleep_ms(interval_ms)


def led_connected():
    """连接成功：快闪3次"""
    led_blink(3, 100)


def led_command():
    """指令执行：闪1次"""
    led_pin.value(1)
    time.sleep_ms(200)
    led_pin.value(0)


def led_auth_ok():
    """认证通过：常亮1秒后灭"""
    led_pin.value(1)
    time.sleep_ms(1000)
    led_pin.value(0)


def led_auth_fail():
    """认证失败：快闪5次"""
    led_blink(5, 80)


def led_advertising():
    """广播中：每秒闪1次（非阻塞，在主循环调用）"""
    led_pin.value(1)
    time.sleep_ms(50)
    led_pin.value(0)


# ===================== GPIO动作 =====================
def act_lock():
    lock_pin.value(0)
    time.sleep_ms(LOCK_PULSE_MS)
    lock_pin.value(1)


def act_unlock():
    unlock_pin.value(0)
    time.sleep_ms(UNLOCK_PULSE_MS)
    unlock_pin.value(1)


def act_trunk():
    trunk_pin.value(0)
    time.sleep_ms(TRUNK_HOLD_MS)
    trunk_pin.value(1)


def act_find_car():
    lock_pin.value(0)
    time.sleep_ms(FIND_CAR_PULSE_MS)
    lock_pin.value(1)
    time.sleep_ms(FIND_CAR_GAP_MS)
    lock_pin.value(0)
    time.sleep_ms(FIND_CAR_PULSE_MS)
    lock_pin.value(1)


def act_window_up():
    lock_pin.value(0)
    time.sleep_ms(WINDOW_HOLD_MS)
    lock_pin.value(1)


def act_window_down():
    unlock_pin.value(0)
    time.sleep_ms(WINDOW_HOLD_MS)
    unlock_pin.value(1)


# ===================== 日志系统 =====================
def log_add(msg):
    ts = _get_timestamp()
    line = "[{}] {}".format(ts, msg)
    try:
        lines = []
        if LOG_FILE in os.listdir():
            with open(LOG_FILE, "r") as f:
                lines = f.read().strip().split("\n")
        lines.append(line)
        if len(lines) > MAX_LOG_LINES:
            lines = lines[-MAX_LOG_LINES:]
        cleaned = []
        cutoff = time.time() - LOG_MAX_AGE_DAYS * 86400
        for l in lines:
            try:
                ts_part = l.split("]")[0].lstrip("[")
                log_time = _parse_timestamp(ts_part)
                if log_time >= cutoff:
                    cleaned.append(l)
            except:
                cleaned.append(l)
        if len(cleaned) < 20:
            cleaned = lines[-20:]
        with open(LOG_FILE, "w") as f:
            f.write("\n".join(cleaned))
    except Exception as e:
        print("[ERR] log_add:", e)


def _get_timestamp():
    try:
        t = time.localtime()
        return "{:04d}-{:02d}-{:02d} {:02d}:{:02d}:{:02d}".format(
            t[0], t[1], t[2], t[3], t[4], t[5])
    except:
        return "0000-00-00 00:00:00"


def _parse_timestamp(s):
    try:
        parts = s.strip().split(" ")
        d = parts[0].split("-")
        t = parts[1].split(":")
        return time.mktime((int(d[0]), int(d[1]), int(d[2]),
                            int(t[0]), int(t[1]), int(t[2]), 0, 0, 0))
    except:
        return 0


def log_get_all():
    try:
        if LOG_FILE in os.listdir():
            with open(LOG_FILE, "r") as f:
                return f.read().strip()
    except:
        pass
    return ""


def log_clear():
    try:
        if LOG_FILE in os.listdir():
            os.remove(LOG_FILE)
    except:
        pass


# ===================== 配置持久化 =====================
def load_config():
    global AUTO_LOCK_ENABLED, ADMIN_DEVICE
    name = DEFAULT_NAME
    pwd = DEFAULT_PWD
    try:
        if CONFIG_FILE in os.listdir():
            with open(CONFIG_FILE, "r") as f:
                cfg = {}
                for line in f.read().strip().split("\n"):
                    if "=" in line:
                        k, v = line.split("=", 1)
                        cfg[k.strip()] = v.strip()
                name = cfg.get("name", DEFAULT_NAME)
                pwd = cfg.get("pwd", DEFAULT_PWD)
                AUTO_LOCK_ENABLED = int(cfg.get("auto_lock", "1"))
                ADMIN_DEVICE = cfg.get("admin_device", "")
    except Exception as e:
        print("[ERR] load_config:", e)
    return name, pwd


def save_config(name, pwd):
    try:
        with open(CONFIG_FILE, "w") as f:
            f.write("name={}\npwd={}\nauto_lock={}\nadmin_device={}\n".format(
                name, pwd, AUTO_LOCK_ENABLED, ADMIN_DEVICE))
    except Exception as e:
        print("[ERR] save_config:", e)


DEVICE_NAME, PASSWORD = load_config()
init_pins()


# ===================== BLE =====================
UART_UUID = bluetooth.UUID("6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
TX_UUID   = bluetooth.UUID("6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
RX_UUID   = bluetooth.UUID("6E400002-B5A3-F393-E0A9-E50E24DCCA9E")

ble = bluetooth.BLE()
connected = False
authenticated = False
temp_auth = False
temp_expire = 0
conn_handle = None
auth_start = 0
lock_until = 0
tx = None
rx = None
led_blink_timer = 0


def process_pending_actions():
    global pending_actions, DEVICE_NAME, PASSWORD
    if not pending_actions:
        return
    actions = pending_actions
    pending_actions = []
    for action_type, data in actions:
        try:
            if action_type == "save_and_notify":
                save_config(DEVICE_NAME, PASSWORD)
                init_pins()
                if conn_handle is not None and connected:
                    ble.gatts_notify(conn_handle, tx, data)
            elif action_type == "notify_only":
                if conn_handle is not None and connected:
                    ble.gatts_notify(conn_handle, tx, data)
        except Exception as e:
            print("[ERR] process_action:", e)
    gc.collect()


def disconnect_and_cleanup():
    global connected, authenticated, temp_auth, temp_expire, conn_handle
    if connected and conn_handle is not None:
        try:
            ble.gap_disconnect(conn_handle)
        except:
            pass
    if authenticated:
        led_connected()
        if AUTO_LOCK_ENABLED:
            act_lock()
            log_add("断开连接，自动落锁")
    connected = False
    authenticated = False
    temp_auth = False
    temp_expire = 0
    conn_handle = None
    gc.collect()
    start_adv()


def start_adv():
    global connected
    if connected:
        return True
    try:
        ble.gap_advertise(None)
        time.sleep_ms(20)
        ble.gap_advertise(50, gen_adv())
        return True
    except Exception as e:
        print("[ERR] start_adv:", e)
        return False


def gen_adv():
    adv = struct.pack("BBB", 2, 1, 6)
    adv += struct.pack("BBH", 3, 0x18, 0x18)
    name = DEVICE_NAME.encode()
    adv += struct.pack("BB", len(name)+1, 9) + name
    return adv


def ble_reset():
    global connected, authenticated, conn_handle, temp_auth, temp_expire, tx, rx
    try:
        ble.active(False)
        time.sleep_ms(100)
        ble.active(True)
        ble.irq(ble_cb)
        ((tx, rx),) = ble.gatts_register_services(((UART_UUID, (
            (TX_UUID, bluetooth.FLAG_NOTIFY),
            (RX_UUID, bluetooth.FLAG_WRITE),
        )),))
        connected = False
        authenticated = False
        temp_auth = False
        temp_expire = 0
        conn_handle = None
        start_adv()
    except Exception as e:
        print("[ERR] ble_reset:", e)
        wdt.feed()


def verify_temp_code(code):
    now = time.time()
    window_now = int(now) // TEMP_VALID
    if code == _temp_code_for_window(window_now):
        return True, (window_now + 1) * TEMP_VALID
    window_prev = window_now - 1
    if code == _temp_code_for_window(window_prev):
        return True, window_now * TEMP_VALID
    return False, 0


def _temp_code_for_window(window):
    secret = PASSWORD + str(window)
    h = hashlib.sha256(secret.encode()).digest()
    val = int.from_bytes(h[:4], "big") % 1000000
    return "{:06d}".format(val)


# ===================== BLE回调 =====================
def ble_cb(event, data):
    global connected, authenticated, conn_handle, auth_start, lock_until, tx, rx
    global temp_auth, temp_expire, DEVICE_NAME, PASSWORD, AUTO_LOCK_ENABLED
    global ADMIN_DEVICE
    try:
        if event == 1:  # 连接
            if len(data) < 1:
                return
            h = data[0]
            now_ticks = time.ticks_ms()
            if lock_until > 0 and time.ticks_diff(now_ticks, lock_until) < 0:
                try:
                    ble.gap_disconnect(h)
                except:
                    pass
                return
            conn_handle = h
            connected = True
            authenticated = False
            temp_auth = False
            temp_expire = 0
            auth_start = now_ticks
            led_connected()
            log_add("设备已连接")

        elif event == 2:  # 断开
            log_add("设备已断开")
            disconnect_and_cleanup()

        elif event == 3:  # 接收数据
            if not connected or len(data) < 2:
                return
            h, val_handle = data[0], data[1]
            if h != conn_handle:
                return
            buf = ble.gatts_read(rx)
            if buf is None:
                return
            cmd = buf.decode().strip()

            # ===== 未认证：验证密码 =====
            if not authenticated:
                # 临时码（6位数字）
                if len(cmd) == 6 and cmd.isdigit():
                    ok, expire_time = verify_temp_code(cmd)
                    if ok:
                        authenticated = True
                        temp_auth = True
                        temp_expire = expire_time
                        led_auth_ok()
                        log_add("临时密码验证通过")
                        pending_actions.append(("notify_only", "AUTOLOCK:{}".format(AUTO_LOCK_ENABLED).encode()))
                        return
                # 管理员密码
                if cmd == PASSWORD:
                    authenticated = True
                    temp_auth = False
                    temp_expire = 0
                    # 记录管理员设备ID（从后续!DEVID命令获取）
                    led_auth_ok()
                    log_add("管理员验证通过")
                    pending_actions.append(("notify_only", "AUTOLOCK:{}".format(AUTO_LOCK_ENABLED).encode()))
                    return
                # 验证失败
                log_add("密码验证失败：{}".format(cmd))
                led_auth_fail()
                lock_until = time.ticks_add(time.ticks_ms(), AUTH_FAILURE)
                disconnect_and_cleanup()
                return

            # ===== 已认证：检查临时码过期 =====
            if temp_auth and time.time() > temp_expire:
                log_add("临时密码已过期")
                led_auth_fail()
                act_lock()
                disconnect_and_cleanup()
                return

            # ===== 车辆控制指令 =====
            if cmd == "suoche":
                act_lock()
                led_command()
                log_add("执行：锁车 → GPIO{} 脉冲".format(PIN_LOCK))
            elif cmd == "jiesuo":
                act_unlock()
                led_command()
                log_add("执行：解锁 → GPIO{} 脉冲".format(PIN_UNLOCK))
            elif cmd == "xunche":
                act_find_car()
                led_command()
                log_add("执行：寻车 → GPIO{} 双脉冲".format(PIN_LOCK))
            elif cmd == "chuangsheng":
                act_window_up()
                led_command()
                log_add("执行：车窗升 → GPIO{} 保持7秒".format(PIN_LOCK))
            elif cmd == "chuangjiang":
                act_window_down()
                led_command()
                log_add("执行：车窗降 → GPIO{} 保持7秒".format(PIN_UNLOCK))
            elif cmd == "houbeixiang":
                act_trunk()
                led_command()
                log_add("执行：后备箱 → GPIO{} 保持7秒".format(PIN_TRUNK))

            # ===== 管理指令（仅管理员） =====
            elif cmd.startswith("!NAME "):
                if temp_auth:
                    return
                new_name = cmd[6:].strip()
                if new_name:
                    DEVICE_NAME = new_name
                    log_add("设备名称已更新：{}".format(new_name))
                    pending_actions.append(("save_and_notify", b"NAME OK"))
            elif cmd.startswith("!PWD "):
                if temp_auth:
                    return
                new_pwd = cmd[5:].strip()
                if new_pwd:
                    PASSWORD = new_pwd
                    log_add("密码已修改")
                    pending_actions.append(("save_and_notify", b"PWD OK"))
            elif cmd == "!RESET":
                if temp_auth:
                    return
                DEVICE_NAME = DEFAULT_NAME
                PASSWORD = DEFAULT_PWD
                AUTO_LOCK_ENABLED = 1
                ADMIN_DEVICE = ""
                log_add("恢复出厂设置")
                pending_actions.append(("save_and_notify", b"RESET OK"))
            elif cmd.startswith("!TIME "):
                if temp_auth:
                    return
                try:
                    ts = int(cmd[6:].strip())
                    rtc = machine.RTC()
                    tm = time.localtime(ts)
                    rtc.datetime((tm[0], tm[1], tm[2], tm[6], tm[3], tm[4], tm[5], 0))
                    log_add("时间同步成功")
                    pending_actions.append(("notify_only", b"TIME OK"))
                except Exception as e:
                    print("[ERR] !TIME:", e)
            elif cmd == "!AUTOLOCK?" or cmd == "!AUTOLOCK":
                pending_actions.append(("notify_only", "AUTOLOCK:{}".format(AUTO_LOCK_ENABLED).encode()))
            elif cmd.startswith("!AUTOLOCK "):
                if temp_auth:
                    return
                try:
                    val = int(cmd[10:].strip())
                    if val in (0, 1):
                        AUTO_LOCK_ENABLED = val
                        log_add("自动落锁：{}".format("开启" if val else "关闭"))
                        pending_actions.append(("save_and_notify", b"AUTOLOCK OK"))
                except:
                    pass
            elif cmd == "!LOG":
                log_data = log_get_all()
                pending_actions.append(("notify_only", log_data.encode() if log_data else b"NO LOG"))
            elif cmd == "!LOGCLEAR":
                if temp_auth:
                    return
                log_clear()
                log_add("日志已清除")
                pending_actions.append(("notify_only", b"LOGCLEAR OK"))
            elif cmd.startswith("!DEVID "):
                if temp_auth:
                    return
                new_id = cmd[7:].strip()
                if new_id:
                    ADMIN_DEVICE = new_id
                    log_add("管理员设备ID已记录：{}".format(new_id))
                    pending_actions.append(("save_and_notify", b"DEVID OK"))
            elif cmd == "!DEVID?":
                pending_actions.append(("notify_only", "DEVID:{}".format(ADMIN_DEVICE).encode()))

    except Exception as e:
        print("[ERR] ble_cb:", e)
        wdt.feed()


# ===================== 初始化BLE =====================
ble.active(False)
time.sleep_ms(100)
ble.active(True)
ble.irq(ble_cb)

try:
    ((tx, rx),) = ble.gatts_register_services(((UART_UUID, (
        (TX_UUID, bluetooth.FLAG_NOTIFY),
        (RX_UUID, bluetooth.FLAG_WRITE),
    )),))
except AttributeError:
    ((tx, rx),) = ble.gatts_register_services(((UART_UUID, (
        (TX_UUID, 0x0010),
        (RX_UUID, 0x0008),
    )),))
except Exception as e:
    print("[ERR] init services:", e)

adv_success = start_adv()
last_adv_ok = time.ticks_ms() if adv_success else 0
adv_fail_count = 0 if adv_success else 1
RESET_THRESHOLD = 3
last_gc = time.ticks_ms()
last_led_blink = time.ticks_ms()

log_add("ESP32 TianKey 固件启动")
log_add("设备名称：{}".format(DEVICE_NAME))

# ===================== 主循环 =====================
while True:
    now = time.ticks_ms()

    process_pending_actions()

    # 广播中LED慢闪指示
    if not connected:
        if time.ticks_diff(now, last_led_blink) > 1000:
            led_advertising()
            last_led_blink = now

    if not connected and time.ticks_diff(now, last_gc) > 30000:
        gc.collect()
        last_gc = now

    if not connected:
        if time.ticks_diff(now, last_adv_ok) > 30000:
            if start_adv():
                adv_fail_count = 0
                last_adv_ok = time.ticks_ms()
            else:
                adv_fail_count += 1
                if adv_fail_count >= RESET_THRESHOLD:
                    ble_reset()
                    adv_fail_count = 0
                    last_adv_ok = time.ticks_ms()
        else:
            adv_fail_count = 0
    else:
        last_adv_ok = now
        adv_fail_count = 0

    if lock_until > 0:
        if time.ticks_diff(now, lock_until) >= 0:
            lock_until = 0
            if not connected:
                start_adv()

    if connected and not authenticated:
        if time.ticks_diff(now, auth_start) >= AUTH_TIMEOUT * 1000:
            log_add("认证超时，断开连接")
            led_auth_fail()
            lock_until = time.ticks_add(now, AUTH_FAILURE)
            disconnect_and_cleanup()

    wdt.feed()
    if not connected:
        time.sleep_ms(300)
    else:
        time.sleep_ms(100)
