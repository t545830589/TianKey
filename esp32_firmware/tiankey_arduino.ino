/*
 * TianKey ESP32 BLE Car Key Firmware v2.0
 * Mazda Axela - BLE NUS Car Key System
 * Single Admin Mode with Auto-Auth
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>
#include <esp_pm.h>
#include <esp_sleep.h>

// ==================== PIN CONFIGURATION ====================
#define PIN_LOCK        25
#define PIN_UNLOCK      26
#define PIN_FINDCAR     27
#define PIN_WINDOW_UP   14
#define PIN_WINDOW_DOWN 33
#define PIN_TRUNK       2

// ==================== BLE NUS UUIDs ====================
#define SERVICE_UUID        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define TX_CHAR_UUID        "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define RX_CHAR_UUID        "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

// ==================== CONSTANTS ====================
#define FIRMWARE_VERSION    "2.0"
#define DEVICE_NAME_DEFAULT "TianKey"
#define ADMIN_PWD_DEFAULT   "123456"
#define INVALID_CONN_HANDLE 0xFFFF

#define PULSE_DURATION_MS   150
#define FINDCAR_HOLD_MS     500
#define FINDCAR_OFF_MS      500
#define HEARTBEAT_INTERVAL  10000
#define HEARTBEAT_TIMEOUT   60000
#define DISCONNECT_LOCK_DELAY 500
#define WINDOW_HOLD_MS      5000

// ==================== NVS KEYS ====================
#define NVS_NAMESPACE       "tiankey"
#define NVS_ADMIN_PWD       "admin_pwd"
#define NVS_DEVICE_NAME     "dev_name"
#define NVS_SAVED_TIME      "saved_time"
#define NVS_CPU_SLEEP       "cpu_sleep"
#define NVS_CONN_COUNT      "conn_cnt"
#define NVS_LOCK_COUNT      "lock_cnt"
#define NVS_UNLOCK_COUNT    "unlock_cnt"
#define NVS_FINDCAR_COUNT   "findcar_cnt"
#define NVS_FIRST_AUTH_PWD  "first_auth"

// Old keys to clean
#define NVS_OLD_ADMIN_DEV   "admin_device"
#define NVS_OLD_BORROW_CODE "borrow_code"
#define NVS_OLD_BORROW_EXP  "borrow_expiry"
#define NVS_OLD_AUTO_LOCK   "auto_lock"

// ==================== GLOBALS ====================
Preferences prefs;
BLEServer *pServer = NULL;
BLECharacteristic *pTxChar = NULL;
BLECharacteristic *pRxChar = NULL;

uint16_t connHandle = INVALID_CONN_HANDLE;
bool deviceConnected = false;
bool wasAuthenticated = false;
String adminPassword = ADMIN_PWD_DEFAULT;
String deviceName = DEVICE_NAME_DEFAULT;
uint32_t savedTime = 0;
bool cpuSleepEnabled = true;
String firstAuthPwd = "";

uint32_t connCount = 0;
uint32_t lockCount = 0;
uint32_t unlockCount = 0;
uint32_t findcarCount = 0;

unsigned long lastHeartbeat = 0;

unsigned long commandStartTime = 0;
bool commandActive = false;
int activeCommandPin = -1;

// ==================== FUNCTION DECLARATIONS ====================
void loadConfig();
void saveConfig();
void cleanOldNvsKeys();
void setupPins();
void setupBLE();
void processCommand(String cmd);
void sendResponse(String msg);
void pulsePin(int pin, int duration);
void executeFindCar();
void executeLock();
void executeUnlock();
void executeTrunk();
void factoryReset();
uint32_t getUnixTime();
void enterLightSleep();
void handleDisconnect();

// ==================== BLE CALLBACKS ====================
class ServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer *pServer, esp_ble_gatts_cb_param_t *param) {
        connHandle = param->connect.conn_id;
        deviceConnected = true;
        wasAuthenticated = false;
        lastHeartbeat = millis();
        connCount++;
        prefs.begin(NVS_NAMESPACE, false);
        prefs.putUInt(NVS_CONN_COUNT, connCount);
        prefs.end();
        Serial.printf("[BLE] Connected, handle=%d\n", connHandle);
    }

    void onDisconnect(BLEServer *pServer) {
        Serial.println("[BLE] Disconnected");
        handleDisconnect();
        connHandle = INVALID_CONN_HANDLE;
        deviceConnected = false;
        wasAuthenticated = false;
        commandActive = false;
        activeCommandPin = -1;
        pServer->startAdvertising();
        Serial.println("[BLE] Advertising restarted");
    }
};

class RxCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        std::string value = pCharacteristic->getValue();
        if (value.length() > 0) {
            String cmd = String(value.c_str());
            cmd.trim();
            Serial.printf("[RX] %s\n", cmd.c_str());
            processCommand(cmd);
        }
    }
};

ServerCallbacks serverCallbacks;
RxCallbacks rxCallbacks;

// ==================== SETUP ====================
void setup() {
    Serial.begin(115200);
    Serial.println("\n=== TianKey v2.0 Starting ===");

    loadConfig();
    setupPins();
    setupBLE();

    Serial.printf("Name: %s\n", deviceName.c_str());
    Serial.printf("CPU Sleep: %s\n", cpuSleepEnabled ? "ON" : "OFF");
    Serial.println("=== Setup Complete ===\n");
}

// ==================== MAIN LOOP ====================
void loop() {
    unsigned long now = millis();

    // Handle active vehicle command timeout (safety)
    if (commandActive && (now - commandStartTime > WINDOW_HOLD_MS)) {
        digitalWrite(activeCommandPin, HIGH);
        commandActive = false;
        activeCommandPin = -1;
        Serial.println("[CMD] Command timeout - pin released");
    }

    // Heartbeat check - phone sends !HEARTBEAT every 10s
    // If no heartbeat received within 60s, disconnect
    if (deviceConnected && connHandle != INVALID_CONN_HANDLE) {
        if (now - lastHeartbeat >= HEARTBEAT_TIMEOUT) {
            Serial.println("[HB] Timeout - disconnecting");
            pServer->disconnect(connHandle);
        }
    }

    // CPU sleep
    if (cpuSleepEnabled && deviceConnected) {
        enterLightSleep();
    } else {
        delay(10);
    }
}

// ==================== CONFIGURATION ====================
void loadConfig() {
    prefs.begin(NVS_NAMESPACE, true);

    String loadedPwd = prefs.getString(NVS_ADMIN_PWD, ADMIN_PWD_DEFAULT);
    adminPassword = loadedPwd.length() > 0 ? loadedPwd : ADMIN_PWD_DEFAULT;

    String loadedName = prefs.getString(NVS_DEVICE_NAME, DEVICE_NAME_DEFAULT);
    deviceName = loadedName.length() > 0 ? loadedName : DEVICE_NAME_DEFAULT;

    savedTime = prefs.getUInt(NVS_SAVED_TIME, 0);
    cpuSleepEnabled = prefs.getBool(NVS_CPU_SLEEP, true);
    firstAuthPwd = prefs.getString(NVS_FIRST_AUTH_PWD, "");

    connCount = prefs.getUInt(NVS_CONN_COUNT, 0);
    lockCount = prefs.getUInt(NVS_LOCK_COUNT, 0);
    unlockCount = prefs.getUInt(NVS_UNLOCK_COUNT, 0);
    findcarCount = prefs.getUInt(NVS_FINDCAR_COUNT, 0);

    prefs.end();

    cleanOldNvsKeys();

    Serial.println("[NVS] Config loaded");
}

void saveConfig() {
    prefs.begin(NVS_NAMESPACE, false);
    prefs.putString(NVS_ADMIN_PWD, adminPassword);
    prefs.putString(NVS_DEVICE_NAME, deviceName);
    prefs.putUInt(NVS_SAVED_TIME, savedTime);
    prefs.putBool(NVS_CPU_SLEEP, cpuSleepEnabled);
    prefs.putString(NVS_FIRST_AUTH_PWD, firstAuthPwd);
    prefs.putUInt(NVS_CONN_COUNT, connCount);
    prefs.putUInt(NVS_LOCK_COUNT, lockCount);
    prefs.putUInt(NVS_UNLOCK_COUNT, unlockCount);
    prefs.putUInt(NVS_FINDCAR_COUNT, findcarCount);
    prefs.end();
}

void cleanOldNvsKeys() {
    prefs.begin(NVS_NAMESPACE, false);
    prefs.remove(NVS_OLD_ADMIN_DEV);
    prefs.remove(NVS_OLD_BORROW_CODE);
    prefs.remove(NVS_OLD_BORROW_EXP);
    prefs.remove(NVS_OLD_AUTO_LOCK);
    prefs.end();
}

// ==================== PIN SETUP ====================
void setupPins() {
    pinMode(PIN_LOCK, OUTPUT);
    pinMode(PIN_UNLOCK, OUTPUT);
    pinMode(PIN_FINDCAR, OUTPUT);
    pinMode(PIN_WINDOW_UP, OUTPUT);
    pinMode(PIN_WINDOW_DOWN, OUTPUT);
    pinMode(PIN_TRUNK, OUTPUT);

    digitalWrite(PIN_LOCK, HIGH);
    digitalWrite(PIN_UNLOCK, HIGH);
    digitalWrite(PIN_FINDCAR, HIGH);
    digitalWrite(PIN_WINDOW_UP, HIGH);
    digitalWrite(PIN_WINDOW_DOWN, HIGH);
    digitalWrite(PIN_TRUNK, HIGH);

    Serial.println("[GPIO] All pins initialized HIGH (inactive)");
}

// ==================== BLE SETUP ====================
void setupBLE() {
    BLEDevice::init(deviceName.c_str());

    esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_DEFAULT, ESP_PWR_LVL_P9);
    esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_ADV, ESP_PWR_LVL_P9);
    esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_SCAN, ESP_PWR_LVL_P9);

    pServer = BLEDevice::createServer();
    pServer->setCallbacks(&serverCallbacks);

    BLEService *pService = pServer->createService(SERVICE_UUID);

    pTxChar = pService->createCharacteristic(
        TX_CHAR_UUID,
        BLECharacteristic::PROPERTY_NOTIFY
    );
    BLE2902 *pTxDesc = new BLE2902();
    pTxDesc->setNotifications(true);
    pTxChar->addDescriptor(pTxDesc);

    pRxChar = pService->createCharacteristic(
        RX_CHAR_UUID,
        BLECharacteristic::PROPERTY_WRITE
    );
    pRxChar->setCallbacks(&rxCallbacks);

    pService->start();

    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println("[BLE] NUS service started, advertising...");
}

// ==================== COMMAND PROCESSOR ====================
void processCommand(String cmd) {
    if (cmd.length() == 0 || cmd[0] != '!') {
        return;
    }

    cmd.remove(0, 1);
    cmd.trim();

    int spaceIdx = cmd.indexOf(' ');
    String command;
    String args = "";
    if (spaceIdx > 0) {
        command = cmd.substring(0, spaceIdx);
        args = cmd.substring(spaceIdx + 1);
        args.trim();
    } else {
        command = cmd;
    }
    command.toUpperCase();

    // ===== AUTH =====
    if (command == "AUTH") {
        int pwdEnd = args.indexOf(' ');
        if (pwdEnd < 0) {
            sendResponse("ERR");
            return;
        }
        String pwd = args.substring(0, pwdEnd);
        String timeStr = args.substring(pwdEnd + 1);
        timeStr.trim();

        uint32_t timestamp = 0;
        if (timeStr.length() > 0) {
            timestamp = strtoul(timeStr.c_str(), NULL, 10);
        }

        if (pwd == adminPassword) {
            wasAuthenticated = true;
            // 校准：savedTime = 期望时间 - 已运行时间，使 getUnixTime() 返回正确时间
            savedTime = timestamp - (millis() / 1000);

            if (firstAuthPwd.length() == 0) {
                firstAuthPwd = pwd;
            }

            prefs.begin(NVS_NAMESPACE, false);
            prefs.putUInt(NVS_SAVED_TIME, savedTime);
            prefs.putString(NVS_FIRST_AUTH_PWD, firstAuthPwd);
            prefs.end();

            sendResponse("OK TIME");
            Serial.printf("[AUTH] Success, time=%lu\n", timestamp);
        } else {
            wasAuthenticated = false;
            firstAuthPwd = "";
            prefs.begin(NVS_NAMESPACE, false);
            prefs.putString(NVS_FIRST_AUTH_PWD, firstAuthPwd);
            prefs.end();
            sendResponse("ERR");
            Serial.println("[AUTH] Failed");
        }
        return;
    }

    // ===== TIME =====
    if (command == "TIME") {
        sendResponse("OK TIME " + String(getUnixTime()));
        return;
    }

    // ===== LOCK =====
    if (command == "LOCK") {
        executeLock();
        return;
    }

    // ===== UNLOCK =====
    if (command == "UNLOCK") {
        executeUnlock();
        return;
    }

    // ===== FINDCAR =====
    if (command == "FINDCAR") {
        executeFindCar();
        return;
    }

    // ===== WINDOWUP =====
    if (command == "WINDOWUP") {
        digitalWrite(PIN_WINDOW_UP, LOW);
        commandActive = true;
        activeCommandPin = PIN_WINDOW_UP;
        commandStartTime = millis();
        Serial.println("[CMD] Window Up");
        return;
    }

    // ===== WINDOWDOWN =====
    if (command == "WINDOWDOWN") {
        digitalWrite(PIN_WINDOW_DOWN, LOW);
        commandActive = true;
        activeCommandPin = PIN_WINDOW_DOWN;
        commandStartTime = millis();
        Serial.println("[CMD] Window Down");
        return;
    }

    // ===== TRUNK =====
    if (command == "TRUNK") {
        executeTrunk();
        return;
    }

    // ===== HEARTBEAT (no response) =====
    if (command == "HEARTBEAT") {
        lastHeartbeat = millis();
        return;
    }

    // ===== RSSI? (no response) =====
    if (command == "RSSI?") {
        return;
    }

    // ===== SNR? (no response) =====
    if (command == "SNR?") {
        return;
    }

    // ===== NAME (set/query) =====
    if (command == "NAME") {
        if (args.length() == 0) {
            sendResponse("OK NAME " + deviceName);
        } else {
            if (args.length() > 31) {
                sendResponse("ERR");
                return;
            }
            deviceName = args;
            prefs.begin(NVS_NAMESPACE, false);
            prefs.putString(NVS_DEVICE_NAME, deviceName);
            prefs.end();
            sendResponse("OK NAME " + deviceName);
            Serial.printf("[NAME] Changed to: %s\n", deviceName.c_str());
        }
        return;
    }

    // ===== NAME? (query) =====
    if (command == "NAME?") {
        sendResponse("OK NAME " + deviceName);
        return;
    }

    // ===== STAT (no response) =====
    if (command == "STAT") {
        return;
    }

    // ===== STAT? (query) =====
    if (command == "STAT?") {
        String resp = "OK STAT conn=" + String(connCount)
                    + " lock=" + String(lockCount)
                    + " unlock=" + String(unlockCount)
                    + " findcar=" + String(findcarCount);
        sendResponse(resp);
        return;
    }

    // ===== PING (no response) =====
    if (command == "PING") {
        return;
    }

    // ===== MAC? =====
    if (command == "MAC?") {
        String mac = BLEDevice::getAddress().toString().c_str();
        mac.toLowerCase();
        sendResponse("OK MAC " + mac);
        return;
    }

    // ===== VER? =====
    if (command == "VER?") {
        sendResponse("OK VER " + String(FIRMWARE_VERSION));
        return;
    }

    // ===== PWD =====
    if (command == "PWD") {
        int pwdSpace = args.indexOf(' ');
        if (pwdSpace < 0) {
            sendResponse("ERR");
            return;
        }
        String oldPwd = args.substring(0, pwdSpace);
        String newPwd = args.substring(pwdSpace + 1);
        newPwd.trim();

        if (oldPwd != adminPassword) {
            sendResponse("ERR");
            Serial.println("[PWD] Wrong old password");
            return;
        }
        if (newPwd.length() == 0 || newPwd.length() > 31) {
            sendResponse("ERR");
            return;
        }
        adminPassword = newPwd;
        prefs.begin(NVS_NAMESPACE, false);
        prefs.putString(NVS_ADMIN_PWD, adminPassword);
        prefs.end();
        sendResponse("OK");
        Serial.printf("[PWD] Changed successfully\n");
        return;
    }

    // ===== CPUSLEEP =====
    if (command == "CPUSLEEP") {
        if (args == "0") {
            cpuSleepEnabled = false;
        } else if (args == "1") {
            cpuSleepEnabled = true;
        } else {
            sendResponse("ERR");
            return;
        }
        prefs.begin(NVS_NAMESPACE, false);
        prefs.putBool(NVS_CPU_SLEEP, cpuSleepEnabled);
        prefs.end();
        sendResponse("OK CPUSLEEP");
        Serial.printf("[CPUSLEEP] Set to %s\n", cpuSleepEnabled ? "ON" : "OFF");
        return;
    }

    // ===== CPUSLEEP? (query) =====
    if (command == "CPUSLEEP?") {
        sendResponse("CPUSLEEP:" + String(cpuSleepEnabled ? "1" : "0"));
        return;
    }

    // ===== UNLOCKED? =====
    if (command == "UNLOCKED?") {
        sendResponse("OK UNLOCKED 0");
        return;
    }

    // ===== RESET =====
    if (command == "RESET") {
        factoryReset();
        return;
    }

    Serial.printf("[CMD] Unknown: %s\n", command.c_str());
}

// ==================== RESPONSE ====================
void sendResponse(String msg) {
    if (!deviceConnected || connHandle == INVALID_CONN_HANDLE) return;
    if (!pTxChar) return;

    pTxChar->setValue(msg.c_str());
    pTxChar->notify();
    Serial.printf("[TX] %s\n", msg.c_str());
}

// ==================== VEHICLE COMMANDS ====================
void pulsePin(int pin, int duration) {
    digitalWrite(pin, LOW);
    delay(duration);
    digitalWrite(pin, HIGH);
}

void executeLock() {
    pulsePin(PIN_LOCK, PULSE_DURATION_MS);
    lockCount++;
    prefs.begin(NVS_NAMESPACE, false);
    prefs.putUInt(NVS_LOCK_COUNT, lockCount);
    prefs.end();
    Serial.println("[CMD] Lock pulse");
}

void executeUnlock() {
    pulsePin(PIN_UNLOCK, PULSE_DURATION_MS);
    unlockCount++;
    prefs.begin(NVS_NAMESPACE, false);
    prefs.putUInt(NVS_UNLOCK_COUNT, unlockCount);
    prefs.end();
    Serial.println("[CMD] Unlock pulse");
}

void executeFindCar() {
    digitalWrite(PIN_FINDCAR, LOW);
    delay(FINDCAR_HOLD_MS);
    digitalWrite(PIN_FINDCAR, HIGH);
    delay(FINDCAR_OFF_MS);
    digitalWrite(PIN_FINDCAR, LOW);
    delay(FINDCAR_HOLD_MS);
    digitalWrite(PIN_FINDCAR, HIGH);

    findcarCount++;
    prefs.begin(NVS_NAMESPACE, false);
    prefs.putUInt(NVS_FINDCAR_COUNT, findcarCount);
    prefs.end();
    Serial.println("[CMD] FindCar executed");
}

void executeTrunk() {
    pulsePin(PIN_TRUNK, PULSE_DURATION_MS);
    Serial.println("[CMD] Trunk pulse");
}

// ==================== FACTORY RESET ====================
void factoryReset() {
    Serial.println("[RESET] Factory reset...");

    prefs.begin(NVS_NAMESPACE, false);
    prefs.clear();
    prefs.end();

    sendResponse("OK RESET");
    delay(100);
    ESP.restart();
}

// ==================== TIME ====================
uint32_t getUnixTime() {
    return (uint32_t)(millis() / 1000) + savedTime;
}

// ==================== CPU SLEEP ====================
esp_pm_lock_handle_t pmLock = NULL;

void enterLightSleep() {
    if (pmLock == NULL) {
        esp_pm_lock_create(ESP_PM_NO_LIGHT_SLEEP, 0, "nls_lock", &pmLock);
    }
    esp_pm_lock_acquire(pmLock);
    esp_sleep_enable_timer_wakeup(10000);
    esp_light_sleep_start();
    esp_pm_lock_release(pmLock);
}

// ==================== DISCONNECT HANDLER ====================
void handleDisconnect() {
    if (commandActive && activeCommandPin >= 0) {
        digitalWrite(activeCommandPin, HIGH);
        commandActive = false;
        activeCommandPin = -1;
    }

    if (wasAuthenticated) {
        Serial.println("[DISC] Auto double-lock engaged");
        pulsePin(PIN_LOCK, PULSE_DURATION_MS);
        delay(DISCONNECT_LOCK_DELAY);
        pulsePin(PIN_LOCK, PULSE_DURATION_MS);
        Serial.println("[DISC] Double-lock complete");
    }
}
