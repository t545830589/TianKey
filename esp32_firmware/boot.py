from machine import Pin, WDT, ADC
import time
import bluetooth
import struct
import gc
import hashlib
import os
import machine
try:
    import json
except ImportError:
    import ujson as json

# ===================== 配置 =====================
PIN_LOCK_DEFAULT    = 14
PIN_UNLOCK_DEFAULT  = 33
PIN_TRUNK_DEFAULT   = 4
DEFAULT_NAME = "陕A0P92Y"
DEFAULT_PWD  = "123456789"
AUTH_TIMEOUT = 10
LOCK_DEFAULT_DURATION = 200
TRUNK_DEFAULT_DURATION = 4000
UNLOCK_DURATION = 200
WINDOW_DURATION = 4000
AUTH_FAILURE = 10000
TEMP_VALID = 6 * 3600
CONFIG_FILE = "config.json"
RSSI_LOCK_THRESHOLD = -80
VOLTAGE_MIN = 3300

wdt = WDT(timeout=8000)

LOCK_PIN = PIN_LOCK_DEFAULT
UNLOCK_PIN = PIN_UNLOCK_DEFAULT
TRUNK_PIN = PIN_TRUNK_DEFAULT

lock_pin = None
unlock_pin = None
trunk_pin = None
safe_state = False
gpio_busy = False
voltage_adc = None

LOCK_DURATION = LOCK_DEFAULT_DURATION
TRUNK_DURATION = TRUNK_DEFAULT_DURATION
AUTO_LOCK_ENABLED = 1
sleep_minutes = 0
sleep_enabled = False
wake_minutes = 30
wake_start = 0
admin_device_id = None
borrow_code = None
borrow_expiry = 0

pending_actions = []
config_dirty = False
connected = False
authenticated = False
temp_auth = False
temp_expire = 0
conn_handle = None
auth_start = 0
lock_until = 0
tx = None
rx = None
adv_fail_count = 0
last_adv_ok = 0
last_rssi_check = 0
ble_error_count = 0
last_cmd_time = 0
HEARTBEAT_TIMEOUT = 30000

def init_pins():
    global lock_pin, unlock_pin, trunk_pin
    if lock_pin is not None:
        lock_pin.init(Pin.IN)
    if unlock_pin is not None:
        unlock_pin.init(Pin.IN)
    if trunk_pin is not None:
        trunk_pin.init(Pin.IN)
    lock_pin = Pin(LOCK_PIN, Pin.OUT, value=1)
    unlock_pin = Pin(UNLOCK_PIN, Pin.OUT, value=1)
    trunk_pin = Pin(TRUNK_PIN, Pin.OUT, value=1)

def safe_pins():
    global safe_state
    try:
        lock_pin.value(1)
    except:
        pass
    try:
        unlock_pin.value(1)
    except:
        pass
    try:
        trunk_pin.value(1)
    except:
        pass
    safe_state = False

def act_lock():
    global gpio_busy
    if not safe_state:
        return
    gpio_busy = True
    lock_pin.value(0)
    time.sleep_ms(LOCK_DURATION)
    lock_pin.value(1)
    gpio_busy = False

def act_unlock():
    global gpio_busy
    if not safe_state:
        return
    gpio_busy = True
    unlock_pin.value(0)
    time.sleep_ms(UNLOCK_DURATION)
    unlock_pin.value(1)
    gpio_busy = False

def act_trunk():
    global gpio_busy
    if not safe_state:
        return
    gpio_busy = True
    trunk_pin.value(0)
    time.sleep_ms(TRUNK_DURATION)
    trunk_pin.value(1)
    gpio_busy = False

def act_chuangsheng():
    global gpio_busy
    if not safe_state:
        return
    gpio_busy = True
    lock_pin.value(0)
    time.sleep_ms(WINDOW_DURATION)
    lock_pin.value(1)
    gpio_busy = False

def act_chuangjiang():
    global gpio_busy
    if not safe_state:
        return
    gpio_busy = True
    unlock_pin.value(0)
    time.sleep_ms(WINDOW_DURATION)
    unlock_pin.value(1)
    gpio_busy = False

def read_voltage():
    global voltage_adc
    try:
        if voltage_adc is None:
            voltage_adc = ADC(Pin(34))
            voltage_adc.atten(ADC.ATTN_11DB)
            voltage_adc.width(ADC.WIDTH_12BIT)
        raw = voltage_adc.read()
        if raw == 0:
            return 4200
        mv = raw * 3300 // 4095
        return mv
    except:
        return 4200

def load_config():
    global LOCK_DURATION, TRUNK_DURATION, AUTO_LOCK_ENABLED
    global LOCK_PIN, UNLOCK_PIN, TRUNK_PIN
    global admin_device_id, borrow_code, borrow_expiry
    global DEVICE_NAME, PASSWORD
    global sleep_minutes, sleep_enabled, wake_minutes
    try:
        with open(CONFIG_FILE, "r") as f:
            cfg = json.loads(f.read())
        DEVICE_NAME = cfg.get("name", DEFAULT_NAME)
        PASSWORD = cfg.get("pwd", DEFAULT_PWD)
        admin_device_id = cfg.get("admin_device", None)
        borrow_code = cfg.get("borrow_code", None)
        borrow_expiry = int(cfg.get("borrow_expiry", 0))
        AUTO_LOCK_ENABLED = int(cfg.get("auto_lock", 1))
        LOCK_PIN = int(cfg.get("lock_pin", PIN_LOCK_DEFAULT))
        UNLOCK_PIN = int(cfg.get("unlock_pin", PIN_UNLOCK_DEFAULT))
        TRUNK_PIN = int(cfg.get("trunk_pin", PIN_TRUNK_DEFAULT))
        LOCK_DURATION = int(cfg.get("lock_dur", LOCK_DEFAULT_DURATION))
        TRUNK_DURATION = int(cfg.get("trunk_dur", TRUNK_DEFAULT_DURATION))
        sleep_minutes = int(cfg.get("sleep_min", 0))
        sleep_enabled = bool(cfg.get("sleep_en", 0))
        wake_minutes = int(cfg.get("wake_min", 30))
        return
    except:
        pass
    try:
        with open("door.cfg", "r") as f:
            lines = f.read().strip().split("\n")
            d = {}
            for line in lines:
                if "=" in line:
                    k, v = line.split("=", 1)
                    d[k.strip()] = v.strip()
        DEVICE_NAME = d.get("name", DEFAULT_NAME)
        PASSWORD = d.get("pwd", DEFAULT_PWD)
        LOCK_DURATION = int(d.get("lock_dur", str(LOCK_DEFAULT_DURATION)))
        TRUNK_DURATION = int(d.get("trunk_dur", str(TRUNK_DEFAULT_DURATION)))
        AUTO_LOCK_ENABLED = int(d.get("auto_lock", "1"))
        LOCK_PIN = int(d.get("lock_pin", str(PIN_LOCK_DEFAULT)))
        UNLOCK_PIN = int(d.get("unlock_pin", str(PIN_UNLOCK_DEFAULT)))
        TRUNK_PIN = int(d.get("trunk_pin", str(PIN_TRUNK_DEFAULT)))
        admin_device_id = d.get("admin_device", None)
        borrow_code = d.get("borrow_code", None)
        borrow_expiry = int(d.get("borrow_expiry", "0"))
        save_config()
        try:
            os.remove("door.cfg")
        except:
            pass
        return
    except:
        pass

def save_config():
    try:
        cfg = {
            "name": DEVICE_NAME,
            "pwd": PASSWORD,
            "lock_dur": LOCK_DURATION,
            "trunk_dur": TRUNK_DURATION,
            "auto_lock": AUTO_LOCK_ENABLED,
            "lock_pin": LOCK_PIN,
            "unlock_pin": UNLOCK_PIN,
            "trunk_pin": TRUNK_PIN,
            "admin_device": admin_device_id if admin_device_id else None,
            "borrow_code": borrow_code if borrow_code else None,
            "borrow_expiry": borrow_expiry,
            "sleep_min": sleep_minutes,
            "sleep_en": 1 if sleep_enabled else 0,
            "wake_min": wake_minutes
        }
        with open(CONFIG_FILE, "w") as f:
            f.write(json.dumps(cfg))
    except:
        pass

DEVICE_NAME = DEFAULT_NAME
PASSWORD = DEFAULT_PWD
load_config()
init_pins()

def _temp_code_for_window(window):
    secret = PASSWORD + str(window)
    h = hashlib.sha256(secret.encode()).digest()
    val = int.from_bytes(h[:4], "big") % 1000000
    return "{:06d}".format(val)

def verify_temp_code(code):
    now = time.time()
    window_now = int(now) // TEMP_VALID
    if code == _temp_code_for_window(window_now):
        return True, (window_now + 1) * TEMP_VALID
    window_prev = window_now - 1
    if code == _temp_code_for_window(window_prev):
        return True, window_now * TEMP_VALID
    return False, 0

def reset_auth():
    global auth_level, authenticated, temp_auth, temp_expire
    auth_level = 0
    authenticated = False
    temp_auth = False
    temp_expire = 0

auth_level = 0

# ==================== BLE ====================
UART_UUID = bluetooth.UUID("6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
TX_UUID = bluetooth.UUID("6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
RX_UUID = bluetooth.UUID("6E400002-B5A3-F393-E0A9-E50E24DCCA9E")

ble = bluetooth.BLE()

def gen_adv():
    adv = struct.pack("BBB", 2, 1, 6)
    adv += struct.pack("BBH", 3, 0x18, 0x18)
    name = DEVICE_NAME.encode()
    adv += struct.pack("BB", len(name) + 1, 9) + name
    return adv

def start_adv():
    global connected
    if connected:
        return True
    try:
        ble.gap_advertise(None)
        time.sleep_ms(20)
        ble.gap_advertise(50, gen_adv())
        return True
    except:
        return False

def ble_reset():
    global connected, conn_handle, tx, rx, ble_error_count, safe_state
    try:
        ble.active(False)
        time.sleep_ms(100)
        ble.active(True)
        ble.irq(ble_cb)
        try:
            ((tx, rx),) = ble.gatts_register_services(((UART_UUID, (
                (TX_UUID, 0x0010),
                (RX_UUID, 0x000C),
            )),))
        except:
            pass
        connected = False
        conn_handle = None
        reset_auth()
        safe_state = False
        ble_error_count = 0
        start_adv()
    except:
        ble_error_count += 1
        if ble_error_count >= 5:
            machine.reset()

def notify(data):
    try:
        if conn_handle is not None and connected:
            ble.gatts_notify(conn_handle, tx, data)
    except:
        pass

def disconnect_and_cleanup():
    global connected, conn_handle, safe_state, gpio_busy
    if connected and conn_handle is not None:
        try:
            ble.gap_disconnect(conn_handle)
        except:
            pass
    if authenticated:
        try:
            act_lock()
            time.sleep_ms(100)
            wdt.feed()
            act_lock()
        except:
            pass
    connected = False
    reset_auth()
    safe_state = False
    conn_handle = None
    gpio_busy = False
    gc.collect()
    start_adv()

def check_rssi():
    global last_rssi_check
    now = time.ticks_ms()
    if time.ticks_diff(now, last_rssi_check) < 3000:
        return
    last_rssi_check = now
    if not connected or conn_handle is None or not authenticated:
        return
    try:
        rssi = ble.gap_readRSSI(conn_handle)
        if rssi < RSSI_LOCK_THRESHOLD:
            disconnect_and_cleanup()
    except:
        pass

def process_command(cmd):
    global connected, conn_handle, auth_start, lock_until
    global authenticated, temp_auth, temp_expire, auth_level, safe_state
    global admin_device_id, borrow_code, borrow_expiry, config_dirty
    global DEVICE_NAME, PASSWORD, AUTO_LOCK_ENABLED
    global wake_minutes, last_cmd_time

    last_cmd_time = time.ticks_ms()

    if not authenticated:
        if cmd.upper().startswith("!AUTH "):
            parts = cmd.split(" ", 2)
            if len(parts) >= 3:
                pwd = parts[1]
                device_id = parts[2]
                if pwd == PASSWORD:
                    admin_device_id = device_id
                    config_dirty = True
                    authenticated = True
                    temp_auth = False
                    auth_level = 2
                    safe_state = True
                    lock_until = 0
                    notify(b"OK AUTH")
                    return
                notify(b"ERR AUTH_FAIL")
                lock_until = time.ticks_add(time.ticks_ms(), AUTH_FAILURE)
                return
            notify(b"ERR AUTH_FMT")
            lock_until = time.ticks_add(time.ticks_ms(), AUTH_FAILURE)
            return
        if cmd.upper().startswith("!DEVID "):
            device_id = cmd.split(" ", 1)[1] if len(cmd.split(" ")) > 1 else ""
            if admin_device_id is None:
                notify(b"ERR NO_ADMIN")
            elif admin_device_id == device_id:
                authenticated = True
                temp_auth = False
                auth_level = 2
                safe_state = True
                lock_until = 0
                notify(b"OK DEVID")
            else:
                notify(b"ERR NOT_ADMIN")
            return
        if cmd.upper().startswith("!VERIFYBORROW "):
            code = cmd.split(" ", 1)[1] if len(cmd.split(" ")) > 1 else ""
            if borrow_code is None:
                notify(b"ERR NO_BORROW")
                return
            if code != borrow_code:
                notify(b"ERR BORROW_FAIL")
                return
            if borrow_expiry > 0 and time.time() > borrow_expiry:
                borrow_code = None
                borrow_expiry = 0
                config_dirty = True
                notify(b"ERR BORROW_EXPIRED")
                return
            authenticated = True
            temp_auth = False
            auth_level = 1
            safe_state = True
            lock_until = 0
            notify(b"OK VERIFYBORROW")
            return
        if len(cmd) == 6 and cmd.isdigit():
            ok, expire_time = verify_temp_code(cmd)
            if ok:
                authenticated = True
                temp_auth = True
                temp_expire = expire_time
                auth_level = 1
                safe_state = True
                lock_until = 0
                notify("AUTOLOCK:{}".format(AUTO_LOCK_ENABLED).encode())
                return
        if cmd == PASSWORD:
            authenticated = True
            temp_auth = False
            temp_expire = 0
            auth_level = 2
            safe_state = True
            lock_until = 0
            notify("AUTOLOCK:{}".format(AUTO_LOCK_ENABLED).encode())
            return
        lock_until = time.ticks_add(time.ticks_ms(), AUTH_FAILURE)
        disconnect_and_cleanup()
        return

    if temp_auth and time.time() > temp_expire:
        disconnect_and_cleanup()
        return

    cmd_upper = cmd.upper()

    if gpio_busy:
        notify(b"ERR BUSY")
        return

    if cmd_upper == "L" or cmd_upper == "SUOCHE":
        act_lock()
    elif cmd_upper == "U" or cmd_upper == "JIESUO":
        act_unlock()
    elif cmd_upper == "T" or cmd_upper == "HOUBEIXIANG":
        act_trunk()
    elif cmd_upper == "XUNCHE":
        act_lock()
        time.sleep_ms(100)
        act_lock()
    elif cmd_upper == "CHUANGSHENG":
        act_chuangsheng()
    elif cmd_upper == "CHUANGJIANG":
        act_chuangjiang()
    elif cmd_upper.startswith("!NAME "):
        if temp_auth or auth_level < 2:
            return
        new_name = cmd[6:].strip()
        if new_name:
            DEVICE_NAME = new_name
            pending_actions.append(("save_restart_adv", None))
            notify(b"NAME OK")
    elif cmd_upper.startswith("!PWD "):
        if temp_auth or auth_level < 2:
            return
        new_pwd = cmd[5:].strip()
        if new_pwd:
            PASSWORD = new_pwd
            config_dirty = True
            notify(b"PWD OK")
    elif cmd_upper.startswith("!TIME "):
        if auth_level < 1:
            return
        try:
            ts = int(cmd[6:].strip())
            rtc = machine.RTC()
            tm = time.localtime(ts)
            rtc.datetime((tm[0], tm[1], tm[2], tm[6], tm[3], tm[4], tm[5], 0))
            notify(b"TIME OK")
        except:
            notify(b"ERR TIME")
    elif cmd_upper.startswith("!BORROW ") and not temp_auth:
        if auth_level < 2:
            return
        parts_borrow = cmd.split(" ")
        if len(parts_borrow) >= 3:
            borrow_code = parts_borrow[1]
            try:
                hours = int(parts_borrow[2])
                borrow_expiry = int(time.time()) + hours * 3600
            except:
                borrow_expiry = 0
            config_dirty = True
            notify(b"OK BORROW")
        else:
            notify(b"ERR BORROW_FMT")
    elif cmd_upper == "!BORROWCLEAR" and not temp_auth:
        if auth_level < 2:
            return
        borrow_code = None
        borrow_expiry = 0
        config_dirty = True
        notify(b"OK BORROWCLEAR")
    elif cmd_upper == "!RESET" and not temp_auth:
        if auth_level < 2:
            return
        DEVICE_NAME = DEFAULT_NAME
        PASSWORD = DEFAULT_PWD
        LOCK_PIN = PIN_LOCK_DEFAULT
        UNLOCK_PIN = PIN_UNLOCK_DEFAULT
        TRUNK_PIN = PIN_TRUNK_DEFAULT
        AUTO_LOCK_ENABLED = 1
        admin_device_id = None
        borrow_code = None
        borrow_expiry = 0
        config_dirty = True
        init_pins()
        notify(b"OK RESET")
    elif cmd_upper.startswith("!SLEEP"):
        if temp_auth or auth_level < 2:
            return
        if cmd_upper == "!SLEEP?":
            notify("SLEEP:{}:{}".format(1 if sleep_enabled else 0, sleep_minutes).encode())
            return
        try:
            val = int(cmd_upper[7:].strip())
            if val <= 0:
                sleep_enabled = False
                sleep_minutes = 0
            else:
                sleep_enabled = True
                sleep_minutes = val
            config_dirty = True
            notify(b"OK SLEEP")
        except:
            notify(b"ERR SLEEP_FMT")
    elif cmd_upper.startswith("!WAKE"):
        if temp_auth or auth_level < 2:
            return
        if cmd_upper == "!WAKE?":
            notify("WAKE:{}".format(wake_minutes).encode())
            return
        try:
            val = int(cmd_upper[6:].strip())
            if val < 1:
                val = 1
            wake_minutes = val
            config_dirty = True
            notify(b"OK WAKE")
        except:
            notify(b"ERR WAKE_FMT")
    elif cmd_upper == "!RSSI?":
        if connected and conn_handle is not None:
            try:
                rssi = ble.gap_readRSSI(conn_handle)
                notify("RSSI:{}".format(rssi).encode())
            except:
                notify(b"RSSI:0")
        else:
            notify(b"RSSI:0")

def ble_cb(event, data):
    global connected, conn_handle, auth_start, lock_until, ble_error_count
    global authenticated, temp_auth, temp_expire, safe_state
    try:
        if event == 1:
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
            last_cmd_time = now_ticks

        elif event == 2:
            disconnect_and_cleanup()

        elif event == 3:
            if not connected or len(data) < 2:
                return
            h = data[0]
            if h != conn_handle:
                return
            buf = ble.gatts_read(rx)
            if buf is None:
                return
            process_command(buf.decode().strip())

    except:
        ble_error_count += 1
        if ble_error_count >= 5:
            machine.reset()

# ==================== 初始化 ====================
ble.active(False)
time.sleep_ms(100)
ble.active(True)
ble.irq(ble_cb)

try:
    ((tx, rx),) = ble.gatts_register_services(((UART_UUID, (
        (TX_UUID, 0x0010),
        (RX_UUID, 0x000C),
    )),))
except:
    pass

adv_success = start_adv()
last_adv_ok = time.ticks_ms() if adv_success else 0
adv_fail_count = 0 if adv_success else 1
wake_start = time.ticks_ms()

# ==================== 主循环 ====================
while True:
    now = time.ticks_ms()

    if pending_actions:
        actions = pending_actions
        pending_actions = []
        for action_type, data in actions:
            if action_type == "save_restart_adv":
                save_config()
                init_pins()
                start_adv()
        gc.collect()

    if config_dirty:
        save_config()
        config_dirty = False

    if not connected:
        if time.ticks_diff(now, last_adv_ok) > 30000:
            if start_adv():
                adv_fail_count = 0
                last_adv_ok = time.ticks_ms()
            else:
                adv_fail_count += 1
                if adv_fail_count >= 3:
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
            lock_until = time.ticks_add(now, AUTH_FAILURE)
            disconnect_and_cleanup()

    gc.collect()
    wdt.feed()
    if connected:
        try:
            check_rssi()
        except:
            pass
        if authenticated and last_cmd_time > 0 and time.ticks_diff(now, last_cmd_time) > HEARTBEAT_TIMEOUT:
            disconnect_and_cleanup()
        machine.lightsleep(100)
    else:
        mv = read_voltage()
        wdt.feed()
        if mv < VOLTAGE_MIN:
            try:
                ble.active(False)
            except:
                pass
            for _ in range(5):
                wdt.feed()
                time.sleep_ms(2000)
            try:
                machine.reset()
            except:
                pass
        elif sleep_enabled and sleep_minutes > 0:
            wake_elapsed_ms = time.ticks_diff(now, wake_start)
            if wake_minutes > 0 and wake_elapsed_ms < wake_minutes * 60 * 1000:
                machine.lightsleep(500)
            else:
                if config_dirty:
                    save_config()
                    config_dirty = False
                try:
                    ble.active(False)
                except:
                    pass
                time.sleep_ms(100)
                wdt.feed()
                machine.deepsleep(sleep_minutes * 60 * 1000)
        else:
            ble_error_count = 0
            machine.lightsleep(500)
