// ==================== TianKey Arduino版 ====================
// 功能：CPU睡觉 + 蓝牙一直广播（BLE Modem Sleep）
// 硬件：ESP32 + 3路继电器（锁车/解锁/后备箱）
// 编译：Arduino IDE + ESP32 Board Package

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>
#include <SPIFFS.h>
#include <ESP.h>
#include <driver/rtc_io.h>
#include <esp_pm.h>
#include <esp_task_wdt.h>
#include <time.h>
#include <sys/time.h>

// ==================== 引脚定义 ====================
#define PIN_LOCK      14
#define PIN_UNLOCK    33
#define PIN_TRUNK     4
#define PIN_LED       2

// ==================== 默认配置 ====================
#define DEFAULT_NAME       "陕A0P92Y"
#define DEFAULT_PWD        "123456789"
#define AUTH_TIMEOUT       10000
#define LOCK_DURATION      200
#define UNLOCK_DURATION    200
#define TRUNK_DURATION     4000
#define WINDOW_DURATION    4000
#define AUTH_FAILURE       10000
#define TEMP_VALID         (6 * 3600)
#define RSSI_LOCK_THRESHOLD -80
#define HEARTBEAT_TIMEOUT  30000
#define WDT_TIMEOUT        8000

// ==================== BLE UUID ====================
#define SERVICE_UUID       "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define TX_CHAR_UUID       "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define RX_CHAR_UUID       "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

// ==================== 全局变量 ====================
Preferences prefs;
BLEServer *pServer = NULL;
BLEService *pService = NULL;
BLECharacteristic *pTxChar = NULL;
BLECharacteristic *pRxChar = NULL;
bool deviceConnected = false;
bool oldConnected = false;
uint16_t connHandle = 0;

// 配置
String deviceName = DEFAULT_NAME;
String password = DEFAULT_PWD;
String adminDeviceId = "";
String borrowCode = "";
unsigned long borrowExpiry = 0;
int lockPin = PIN_LOCK;
int unlockPin = PIN_UNLOCK;
int trunkPin = PIN_TRUNK;
int lockDuration = LOCK_DURATION;
int trunkDuration = TRUNK_DURATION;
int autoLockEnabled = 1;
bool cpuSleepEnabled = true;
esp_pm_lock_handle_t cpuLock = NULL;

// 状态
bool authenticated = false;
bool tempAuth = false;
unsigned long tempExpire = 0;
int authLevel = 0;
bool safeState = false;
bool gpioBusy = false;
unsigned long authStart = 0;
unsigned long lockUntil = 0;
unsigned long lastCmdTime = 0;
bool configDirty = false;

// ==================== GPIO操作 ====================

// LED已关闭，省电。所有状态反馈改在APK里显示。

void initPins() {
    pinMode(lockPin, OUTPUT);
    pinMode(unlockPin, OUTPUT);
    pinMode(trunkPin, OUTPUT);
    digitalWrite(lockPin, HIGH);
    digitalWrite(unlockPin, HIGH);
    digitalWrite(trunkPin, HIGH);
    pinMode(PIN_LED, OUTPUT);
    digitalWrite(PIN_LED, LOW);  // LED始终关闭，省电
}

void safePins() {
    digitalWrite(lockPin, HIGH);
    digitalWrite(unlockPin, HIGH);
    digitalWrite(trunkPin, HIGH);
    safeState = false;
}

void actLock() {
    if (!safeState) return;
    gpioBusy = true;
    digitalWrite(lockPin, LOW);
    delay(lockDuration);
    digitalWrite(lockPin, HIGH);
    gpioBusy = false;
}

void actUnlock() {
    if (!safeState) return;
    gpioBusy = true;
    digitalWrite(unlockPin, LOW);
    delay(UNLOCK_DURATION);
    digitalWrite(unlockPin, HIGH);
    gpioBusy = false;
}

void actTrunk() {
    if (!safeState) return;
    gpioBusy = true;
    digitalWrite(trunkPin, LOW);
    delay(trunkDuration);
    digitalWrite(trunkPin, HIGH);
    gpioBusy = false;
}

void actChuangsheng() {
    if (!safeState) return;
    gpioBusy = true;
    digitalWrite(lockPin, LOW);
    delay(WINDOW_DURATION);
    digitalWrite(lockPin, HIGH);
    gpioBusy = false;
}

void actChuangjiang() {
    if (!safeState) return;
    gpioBusy = true;
    digitalWrite(unlockPin, LOW);
    delay(WINDOW_DURATION);
    digitalWrite(unlockPin, HIGH);
    gpioBusy = false;
}


// ==================== 配置读写 ====================
void loadConfig() {
    prefs.begin("tiankey", true);
    deviceName = prefs.getString("name", DEFAULT_NAME);
    password = prefs.getString("pwd", DEFAULT_PWD);
    adminDeviceId = prefs.getString("admin_device", "");
    borrowCode = prefs.getString("borrow_code", "");
    borrowExpiry = prefs.getULong("borrow_expiry", 0);
    autoLockEnabled = prefs.getInt("auto_lock", 1);
    lockPin = prefs.getInt("lock_pin", PIN_LOCK);
    unlockPin = prefs.getInt("unlock_pin", PIN_UNLOCK);
    trunkPin = prefs.getInt("trunk_pin", PIN_TRUNK);
    lockDuration = prefs.getInt("lock_dur", LOCK_DURATION);
    trunkDuration = prefs.getInt("trunk_dur", TRUNK_DURATION);
    cpuSleepEnabled = prefs.getBool("cpu_sleep_en", true);
    prefs.end();
}

void saveConfig() {
    prefs.begin("tiankey", false);
    prefs.putString("name", deviceName);
    prefs.putString("pwd", password);
    prefs.putString("admin_device", adminDeviceId);
    prefs.putString("borrow_code", borrowCode);
    prefs.putULong("borrow_expiry", borrowExpiry);
    prefs.putInt("auto_lock", autoLockEnabled);
    prefs.putInt("lock_pin", lockPin);
    prefs.putInt("unlock_pin", unlockPin);
    prefs.putInt("trunk_pin", trunkPin);
    prefs.putInt("lock_dur", lockDuration);
    prefs.putInt("trunk_dur", trunkDuration);
    prefs.putBool("cpu_sleep_en", cpuSleepEnabled);
    prefs.end();
    configDirty = false;
}

// ==================== 临时密码验证 ====================
String tempCodeForWindow(int window) {
    String secret = password + String(window);
    // 简化版SHA256 - 用ESP32内置
    uint8_t hash[32];
    esp_sha(SHA256, (const uint8_t*)secret.c_str(), secret.length(), hash);
    unsigned long val = ((unsigned long)hash[0] << 24) | ((unsigned long)hash[1] << 16) | ((unsigned long)hash[2] << 8) | hash[3];
    val = val % 1000000;
    char buf[7];
    snprintf(buf, sizeof(buf), "%06lu", val);
    return String(buf);
}

bool verifyTempCode(String code, unsigned long &expireTime) {
    time_t now = time(NULL);
    if (now < 1000000000) {
        // 时间还没同步，用millis做临时替代
        now = millis() / 1000;
    }
    int windowNow = now / TEMP_VALID;
    if (code == tempCodeForWindow(windowNow)) {
        expireTime = (windowNow + 1) * TEMP_VALID;
        return true;
    }
    int windowPrev = windowNow - 1;
    if (code == tempCodeForWindow(windowPrev)) {
        expireTime = (windowNow + 1) * TEMP_VALID;
        return true;
    }
    return false;
}

// ==================== BLE回调 ====================
void resetAuth() {
    authenticated = false;
    tempAuth = false;
    tempExpire = 0;
    authLevel = 0;
}

void notifyBLE(String data) {
    if (deviceConnected && pTxChar != NULL) {
        pTxChar->setValue((uint8_t*)data.c_str(), data.length());
        pTxChar->notify();
    }
}

void disconnectAndCleanup() {
    if (deviceConnected && connHandle != 0) {
        pServer->disconnect(connHandle);
    }
    gpioBusy = false;
    if (authenticated) {
        actLock();
        delay(100);
        actLock();
    }
    deviceConnected = false;
    resetAuth();
    safeState = false;
    connHandle = 0;
    gpioBusy = false;
}

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t *param) {
        deviceConnected = true;
        connHandle = param->connect.conn_id;
        authenticated = false;
        tempAuth = false;
        tempExpire = 0;
        authLevel = 0;
        authStart = millis();
        lastCmdTime = millis();
        Serial.println("手机已连接");
    }

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        connHandle = 0;
        resetAuth();
        safeState = false;
        // 断开后立刻重新广播，等待手机回来自动连接
        delay(500);
        pServer->startAdvertising();
        Serial.println("已断开，重新广播中...");
    }
};

// ==================== 命令处理 ====================
void processCommand(String cmd) {
    lastCmdTime = millis();
    cmd.trim();

    if (!authenticated) {
        if (cmd.startsWith("!AUTH ")) {
            int space1 = cmd.indexOf(' ');
            int space2 = cmd.indexOf(' ', space1 + 1);
            if (space2 > 0) {
                String pwd = cmd.substring(space1 + 1, space2);
                String devId = cmd.substring(space2 + 1);
                if (pwd == password) {
                    adminDeviceId = devId;
                    configDirty = true;
                    authenticated = true;
                    tempAuth = false;
                    authLevel = 2;
                    safeState = true;
                    lockUntil = 0;
                    notifyBLE("OK AUTH");
                    return;
                }
                notifyBLE("ERR AUTH_FAIL");
                return;
            }
            notifyBLE("ERR AUTH_FMT");
            return;
        }
        if (cmd.startsWith("!DEVID ")) {
            String devId = cmd.substring(7);
            if (adminDeviceId.length() == 0) {
                notifyBLE("ERR NO_ADMIN");
            } else if (adminDeviceId == devId) {
                authenticated = true;
                tempAuth = false;
                authLevel = 2;
                safeState = true;
                lockUntil = 0;
                notifyBLE("OK DEVID");
            } else {
                notifyBLE("ERR NOT_ADMIN");
            }
            return;
        }
        if (cmd.startsWith("!VERIFYBORROW ")) {
            String code = cmd.substring(14);
            if (borrowCode.length() == 0) {
                notifyBLE("ERR NO_BORROW");
                return;
            }
            if (code != borrowCode) {
                notifyBLE("ERR BORROW_FAIL");
                return;
            }
            if (borrowExpiry > 0 && time(NULL) > borrowExpiry) {
                borrowCode = "";
                borrowExpiry = 0;
                configDirty = true;
                notifyBLE("ERR BORROW_EXPIRED");
                return;
            }
            authenticated = true;
            tempAuth = false;
            authLevel = 1;
            safeState = true;
            lockUntil = 0;
            notifyBLE("OK VERIFYBORROW");
            return;
        }
        if (cmd.length() == 6) {
            bool allDigit = true;
            for (int i = 0; i < 6; i++) {
                if (!isDigit(cmd[i])) { allDigit = false; break; }
            }
            if (allDigit) {
                unsigned long expireTime;
                if (verifyTempCode(cmd, expireTime)) {
                    authenticated = true;
                    tempAuth = true;
                    tempExpire = expireTime;
                    authLevel = 1;
                    safeState = true;
                    lockUntil = 0;
                    notifyBLE("AUTOLOCK:" + String(autoLockEnabled));
                    return;
                }
            }
        }
        if (cmd == password) {
            authenticated = true;
            tempAuth = false;
            tempExpire = 0;
            authLevel = 2;
            safeState = true;
            lockUntil = 0;
            notifyBLE("AUTOLOCK:" + String(autoLockEnabled));
            return;
        }
        lockUntil = millis() / 1000 + AUTH_FAILURE / 1000;
        disconnectAndCleanup();
        return;
    }

    if (tempAuth && time(NULL) > tempExpire) {
        disconnectAndCleanup();
        return;
    }

    String cmdUpper = cmd;
    cmdUpper.toUpperCase();

    if (gpioBusy) {
        notifyBLE("ERR BUSY");
        return;
    }

    if (cmdUpper == "L" || cmdUpper == "SUOCHE") {
        actLock();
    } else if (cmdUpper == "U" || cmdUpper == "JIESUO") {
        actUnlock();
    } else if (cmdUpper == "T" || cmdUpper == "HOUBEIXIANG") {
        actTrunk();
    } else if (cmdUpper == "XUNCHE") {
        actLock();
        delay(100);
        actLock();
    } else if (cmdUpper == "CHUANGSHENG") {
        actChuangsheng();
    } else if (cmdUpper == "CHUANGJIANG") {
        actChuangjiang();
    } else if (cmdUpper.startsWith("!NAME ")) {
        if (tempAuth || authLevel < 2) return;
        String newName = cmd.substring(6);
        newName.trim();
        if (newName.length() > 0) {
            deviceName = newName;
            configDirty = true;
            notifyBLE("NAME OK");
        }
    } else if (cmdUpper.startsWith("!PWD ")) {
        if (tempAuth || authLevel < 2) return;
        String newPwd = cmd.substring(5);
        newPwd.trim();
        if (newPwd.length() > 0) {
            password = newPwd;
            configDirty = true;
            notifyBLE("PWD OK");
        }
    } else if (cmdUpper.startsWith("!TIME ")) {
        if (authLevel < 1) return;
        // 真正设置RTC时间 - 解析手机发来的时间戳
        String tsStr = cmd.substring(6);
        tsStr.trim();
        long epoch = tsStr.toInt();
        if (epoch > 1000000000) {
            struct timeval tv;
            tv.tv_sec = epoch;
            tv.tv_usec = 0;
            settimeofday(&tv, NULL);
            notifyBLE("TIME OK");
            Serial.printf("时间已同步: %ld\n", epoch);
        } else {
            notifyBLE("ERR TIME_FMT");
        }
    } else if (cmdUpper == "!AUTOLOCK?") {
        notifyBLE("AUTOLOCK:" + String(autoLockEnabled));
    } else if (cmdUpper.startsWith("!AUTOLOCK")) {
        if (tempAuth || authLevel < 2) return;
        int val = cmdUpper.substring(10).toInt();
        if (val == 0 || val == 1) {
            autoLockEnabled = val;
            configDirty = true;
            notifyBLE("AUTOLOCK OK");
        }
    } else if (cmdUpper.startsWith("!BORROW ") && !tempAuth) {
        if (authLevel < 2) return;
        int space1 = cmd.indexOf(' ');
        int space2 = cmd.indexOf(' ', space1 + 1);
        if (space2 > 0) {
            String code = cmd.substring(space1 + 1, space2);
            int hours = cmd.substring(space2 + 1).toInt();
            long borrowSecs;
            if (hours == 0) {
                borrowSecs = 300;  // 5分钟
            } else {
                borrowSecs = hours * 3600L;
            }
            if (borrowSecs >= 300) {
                borrowCode = code;
                borrowExpiry = time(NULL) + borrowSecs;
                configDirty = true;
                notifyBLE("OK BORROW");
            } else {
                notifyBLE("ERR BORROW_FMT");
            }
        } else {
            notifyBLE("ERR BORROW_FMT");
        }
    } else if (cmdUpper == "!BORROWCLEAR" && !tempAuth) {
        if (authLevel < 2) return;
        borrowCode = "";
        borrowExpiry = 0;
        configDirty = true;
        notifyBLE("OK BORROWCLEAR");
    } else if (cmdUpper == "!RESET" && !tempAuth) {
        if (authLevel < 2) return;
        deviceName = DEFAULT_NAME;
        password = DEFAULT_PWD;
        lockPin = PIN_LOCK;
        unlockPin = PIN_UNLOCK;
        trunkPin = PIN_TRUNK;
        autoLockEnabled = 1;
        adminDeviceId = "";
        borrowCode = "";
        borrowExpiry = 0;
        configDirty = true;
        initPins();
        notifyBLE("OK RESET");
    } else if (cmdUpper == "!DEVICEID?") {
        if (authLevel >= 2) {
            notifyBLE("DEVICEID:" + (adminDeviceId.length() > 0 ? adminDeviceId : "NONE"));
        }
    } else if (cmdUpper == "!RSSI?") {
        if (deviceConnected && connHandle != 0) {
            int rssi = esp_ble_get_conn_rssi(connHandle);
            notifyBLE("RSSI:" + String(rssi));
        } else {
            notifyBLE("RSSI:0");
        }
    } else if (cmdUpper.startsWith("!CPUSLEEP")) {
        if (tempAuth || authLevel < 2) return;
        if (cmdUpper == "!CPUSLEEP?") {
            notifyBLE("CPUSLEEP:" + String(cpuSleepEnabled ? 1 : 0));
            return;
        }
        int val = cmdUpper.substring(10).toInt();
        if (val == 0 || val == 1) {
            cpuSleepEnabled = (val == 1);
            if (cpuSleepEnabled) {
                esp_pm_lock_release(cpuLock);
            } else {
                esp_pm_lock_acquire(cpuLock);
            }
            configDirty = true;
            notifyBLE("OK CPUSLEEP");
        }
    }
}

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        String value = pCharacteristic->getValue();
        if (value.length() > 0 && value.length() <= 128) {
            processCommand(value);
        }
    }
};

// ==================== BLE初始化 ====================
void initBLE() {
    BLEDevice::init(deviceName.c_str());

    // 配置电源管理 - BLE Modem Sleep
    esp_pm_config_esp32_t pmConfig;
    pmConfig.max_freq_mhz = 80;
    pmConfig.min_freq_mhz = 80;
    pmConfig.light_sleep_enable = true;
    esp_pm_configure(&pmConfig);

    // 创建PM锁（必须先create再acquire）
    esp_pm_lock_create(ESP_PM_CPU_FREQ_MAX, 0, "cpuLock", &cpuLock);

    // CPU低功耗开关：关闭时获取锁，禁止Light Sleep
    if (!cpuSleepEnabled) {
        esp_pm_lock_acquire(cpuLock);
    } else {
        esp_pm_lock_release(cpuLock);
    }

    // 设置BLE Modem Sleep模式 - CPU可以休眠，BLE保持广播
    esp_ble_sleep_mode_set(ESP_BLE_SLEEP_MODE_MODEM);

    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    pService = pServer->createService(SERVICE_UUID);

    // TX特征（ESP32→手机，通知）
    pTxChar = pService->createCharacteristic(
        TX_CHAR_UUID,
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pTxChar->addDescriptor(new BLE2902());

    // RX特征（手机→ESP32，写入）
    pRxChar = pService->createCharacteristic(
        RX_CHAR_UUID,
        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
    );
    pRxChar->setCallbacks(new MyCallbacks());

    pService->start();

    // 开始广播
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();
}

// ==================== 主循环 ====================
void setup() {
    Serial.begin(115200);

    // 初始化看门狗
    esp_task_wdt_init(WDT_TIMEOUT / 1000, true);
    esp_task_wdt_add(NULL);

    // 加载配置
    loadConfig();
    initPins();

    // 初始化BLE
    initBLE();

    Serial.println("TianKey Arduino启动完成");
}

void loop() {
    unsigned long now = millis();

    // 保存配置
    if (configDirty) {
        saveConfig();
    }

    // 断开后重新广播
    if (!deviceConnected && oldConnected) {
        delay(500);
        pServer->startAdvertising();
        oldConnected = false;
        Serial.println("已断开，重新广播中...");
    }
    if (deviceConnected && !oldConnected) {
        oldConnected = true;
    }

    // 认证超时
    if (deviceConnected && !authenticated) {
        if (millis() - authStart > AUTH_TIMEOUT) {
            lockUntil = millis() / 1000 + AUTH_FAILURE / 1000;
            disconnectAndCleanup();
        }
    }

    // 锁定超时
    if (lockUntil > 0 && millis() / 1000 >= lockUntil) {
        lockUntil = 0;
        if (!deviceConnected) {
            pServer->startAdvertising();
        }
    }

    // 心跳超时
    if (deviceConnected && authenticated) {
        if (lastCmdTime > 0 && millis() - lastCmdTime > HEARTBEAT_TIMEOUT) {
            disconnectAndCleanup();
        }
    }

    // ==================== 核心：CPU睡觉 + BLE广播 ====================
    if (deviceConnected) {
        delay(100);
    } else {
        if (cpuSleepEnabled) {
            // CPU低功耗开启：delay让CPU进入Light Sleep，BLE保持广播
            delay(500);
        } else {
            // CPU低功耗关闭：CPU全速运行，BLE照常广播
            delay(10);
        }
    }

    esp_task_wdt_reset();
}
