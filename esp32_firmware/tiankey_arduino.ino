/*
 * TianKey ESP32 BLE Car Key Firmware v3.0
 * Mazda Axela - BLE NUS Car Key System
 * Single Admin Mode with Auto-Auth
 *
 * GPIO Mapping (from old boot.py):
 *   Lock:      GPIO14, LOW 200ms
 *   Unlock:    GPIO33, LOW 200ms
 *   Trunk:     GPIO4,  LOW 4000ms
 *   WindowUp:  GPIO14, LOW 4000ms (same pin as Lock)
 *   WindowDown:GPIO33, LOW 4000ms (same pin as Unlock)
 *   FindCar:   GPIO14, two lock pulses (200ms LOW, 100ms gap, 200ms LOW)
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>
#include <esp_pm.h>
#include <esp_sleep.h>

// ==================== PIN CONFIGURATION ====================
// From old boot.py: Lock=14, Unlock=33, Trunk=4
// WindowUp uses same pin as Lock (GPIO14)
// WindowDown uses same pin as Unlock (GPIO33)
#define PIN_LOCK        14
#define PIN_UNLOCK      33
#define PIN_TRUNK       4

// ==================== BLE NUS UUIDs ====================
#define SERVICE_UUID        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define TX_CHAR_UUID        "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define RX_CHAR_UUID        "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

// ==================== CONSTANTS ====================
#define FIRMWARE_VERSION    "3.0"
#define DEVICE_NAME_DEFAULT "TianKey"
#define ADMIN_PWD_DEFAULT   "123456"
#define INVALID_CONN_HANDLE 0xFFFF

// Action timing (from old boot.py)
#define LOCK_PULSE_MS       200
#define TRUNK_HOLD_MS       4000
#define WINDOW_HOLD_MS      4000
#define FINDCAR_PULSE_MS    200
#define FINDCAR_GAP_MS      100

#define HEARTBEAT_TIMEOUT   60000
#define DISCONNECT_LOCK_DELAY 500

// ==================== NVS KEYS ====================
#define NVS_NAMESPACE       "tiankey"
#define NVS_ADMIN_PWD       "admin_pwd"
#define NVS_DEVICE_NAME     "dev_name"
#define NVS_SAVED_TIME      "saved_time"
#define NVS_CPU_SLEEP       "cpu_sleep"
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

unsigned long lastHeartbeat = 0;

// ==================== VEHICLE ACTION STATE MACHINE ====================
// Non-blocking: tracks which pin is active and when to release it
enum VehicleAction {
    ACTION_NONE,
    ACTION_LOCK_PULSE,       // 200ms pulse
    ACTION_UNLOCK_PULSE,     // 200ms pulse
    ACTION_TRUNK_HOLD,       // 4000ms hold
    ACTION_FINDCAR_STEP1,    // first pulse 200ms
    ACTION_FINDCAR_GAP,      // gap 100ms
    ACTION_FINDCAR_STEP2,    // second pulse 200ms
};

VehicleAction currentAction = ACTION_NONE;
unsigned long actionStartTime = 0;
bool vehicleBusy = false;  // prevent concurrent GPIO actions

// ==================== FUNCTION DECLARATIONS ====================
void loadConfig();
void cleanOldNvsKeys();
void setupPins();
void setupBLE();
void processCommand(String cmd);
void sendResponse(String msg);
void factoryReset();
uint32_t getUnixTime();
void handleDisconnect();
void releaseAllPins();
void startVehicleAction(VehicleAction action);
void updateVehicleAction();

// ==================== BLE CALLBACKS ====================
class ServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer *pServer, esp_ble_gatts_cb_param_t *param) {
        connHandle = param->connect.conn_id;
        deviceConnected = true;
        wasAuthenticated = false;
        lastHeartbeat = millis();
        Serial.printf("[BLE] Connected, handle=%d\n", connHandle);
    }

    void onDisconnect(BLEServer *pServer) {
        Serial.println("[BLE] Disconnected");
        handleDisconnect();
        connHandle = INVALID_CONN_HANDLE;
        deviceConnected = false;
        wasAuthenticated = false;
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
    Serial.println("\n=== TianKey v3.0 Starting ===");

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

    // Update vehicle action state machine (non-blocking)
    updateVehicleAction();

    // Heartbeat check - phone sends !HEARTBEAT every 10s
    // If no heartbeat received within 60s, disconnect
    if (deviceConnected && connHandle != INVALID_CONN_HANDLE) {
        if (now - lastHeartbeat >= HEARTBEAT_TIMEOUT) {
            Serial.println("[HB] Timeout - disconnecting");
            pServer->disconnect(connHandle);
        }
    }

    // CPU sleep - works in both connected and advertising states
    // BLE stack keeps running during light sleep
    if (cpuSleepEnabled && !vehicleBusy) {
        // Light sleep for 10ms, BLE stack continues
        esp_sleep_enable_timer_wakeup(10000);  // 10ms
        esp_light_sleep_start();
    } else {
        delay(1);
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

    prefs.end();

    cleanOldNvsKeys();

    Serial.println("[NVS] Config loaded");
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
    pinMode(PIN_TRUNK, OUTPUT);

    digitalWrite(PIN_LOCK, HIGH);
    digitalWrite(PIN_UNLOCK, HIGH);
    digitalWrite(PIN_TRUNK, HIGH);

    Serial.println("[GPIO] All pins initialized HIGH (inactive)");
}

// ==================== BLE SETUP ====================
void setupBLE() {
    BLEDevice::init(deviceName.c_str());

    // Maximum TX power P9
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

    // ===== LOCK =====
    if (command == "LOCK") {
        if (vehicleBusy) { sendResponse("BUSY"); return; }
        startVehicleAction(ACTION_LOCK_PULSE);
        Serial.println("[CMD] Lock");
        return;
    }

    // ===== UNLOCK =====
    if (command == "UNLOCK") {
        if (vehicleBusy) { sendResponse("BUSY"); return; }
        startVehicleAction(ACTION_UNLOCK_PULSE);
        Serial.println("[CMD] Unlock");
        return;
    }

    // ===== FINDCAR =====
    if (command == "FINDCAR") {
        if (vehicleBusy) { sendResponse("BUSY"); return; }
        startVehicleAction(ACTION_FINDCAR_STEP1);
        Serial.println("[CMD] FindCar");
        return;
    }

    // ===== WINDOWUP (uses same pin as LOCK: GPIO14, 4000ms hold) =====
    if (command == "WINDOWUP") {
        if (vehicleBusy) { sendResponse("BUSY"); return; }
        releaseAllPins();
        currentAction = ACTION_TRUNK_HOLD;
        actionStartTime = millis();
        digitalWrite(PIN_LOCK, LOW);
        vehicleBusy = true;
        windowHoldPin = PIN_LOCK;
        Serial.println("[CMD] Window Up (GPIO14 LOW 4s)");
        return;
    }

    // ===== WINDOWDOWN (uses same pin as UNLOCK: GPIO33, 4000ms hold) =====
    if (command == "WINDOWDOWN") {
        if (vehicleBusy) { sendResponse("BUSY"); return; }
        releaseAllPins();
        currentAction = ACTION_TRUNK_HOLD;
        actionStartTime = millis();
        digitalWrite(PIN_UNLOCK, LOW);
        vehicleBusy = true;
        windowHoldPin = PIN_UNLOCK;
        Serial.println("[CMD] Window Down (GPIO33 LOW 4s)");
        return;
    }

    // ===== TRUNK =====
    if (command == "TRUNK") {
        if (vehicleBusy) { sendResponse("BUSY"); return; }
        releaseAllPins();
        currentAction = ACTION_TRUNK_HOLD;
        actionStartTime = millis();
        digitalWrite(PIN_TRUNK, LOW);
        vehicleBusy = true;
        windowHoldPin = -1;  // trunk, not window
        Serial.println("[CMD] Trunk (GPIO4 LOW 4s)");
        return;
    }

    // ===== HEARTBEAT (no response) =====
    if (command == "HEARTBEAT") {
        lastHeartbeat = millis();
        return;
    }

    // ===== NAME (set and restart to apply) =====
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
            Serial.printf("[NAME] Changed to: %s, restarting...\n", deviceName.c_str());
            delay(200);
            ESP.restart();
        }
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

// ==================== VEHICLE ACTION STATE MACHINE ====================
// Tracks which pin we're using for window hold
static int windowHoldPin = -1;

void releaseAllPins() {
    digitalWrite(PIN_LOCK, HIGH);
    digitalWrite(PIN_UNLOCK, HIGH);
    digitalWrite(PIN_TRUNK, HIGH);
    currentAction = ACTION_NONE;
    vehicleBusy = false;
    windowHoldPin = -1;
    Serial.println("[GPIO] All pins released HIGH");
}

void startVehicleAction(VehicleAction action) {
    releaseAllPins();  // Ensure previous action is fully released
    currentAction = action;
    actionStartTime = millis();
    vehicleBusy = true;

    switch (action) {
        case ACTION_LOCK_PULSE:
            digitalWrite(PIN_LOCK, LOW);
            break;
        case ACTION_UNLOCK_PULSE:
            digitalWrite(PIN_UNLOCK, LOW);
            break;
        case ACTION_TRUNK_HOLD:
            digitalWrite(PIN_TRUNK, LOW);
            break;
        case ACTION_FINDCAR_STEP1:
            digitalWrite(PIN_LOCK, LOW);
            break;
        default:
            break;
    }
}

void updateVehicleAction() {
    if (!vehicleBusy || currentAction == ACTION_NONE) return;

    unsigned long elapsed = millis() - actionStartTime;

    switch (currentAction) {
        case ACTION_LOCK_PULSE:
            if (elapsed >= LOCK_PULSE_MS) {
                digitalWrite(PIN_LOCK, HIGH);
                currentAction = ACTION_NONE;
                vehicleBusy = false;
                Serial.println("[GPIO] Lock pulse complete");
            }
            break;

        case ACTION_UNLOCK_PULSE:
            if (elapsed >= LOCK_PULSE_MS) {
                digitalWrite(PIN_UNLOCK, HIGH);
                currentAction = ACTION_NONE;
                vehicleBusy = false;
                Serial.println("[GPIO] Unlock pulse complete");
            }
            break;

        case ACTION_TRUNK_HOLD:
            if (elapsed >= TRUNK_HOLD_MS) {
                // Check which pin is active
                if (windowHoldPin == PIN_LOCK) {
                    digitalWrite(PIN_LOCK, HIGH);
                    Serial.println("[GPIO] Window Up complete");
                } else if (windowHoldPin == PIN_UNLOCK) {
                    digitalWrite(PIN_UNLOCK, HIGH);
                    Serial.println("[GPIO] Window Down complete");
                } else {
                    digitalWrite(PIN_TRUNK, HIGH);
                    Serial.println("[GPIO] Trunk hold complete");
                }
                currentAction = ACTION_NONE;
                vehicleBusy = false;
                windowHoldPin = -1;
            }
            break;

        case ACTION_FINDCAR_STEP1:
            if (elapsed >= FINDCAR_PULSE_MS) {
                digitalWrite(PIN_LOCK, HIGH);
                currentAction = ACTION_FINDCAR_GAP;
                actionStartTime = millis();
                Serial.println("[GPIO] FindCar gap");
            }
            break;

        case ACTION_FINDCAR_GAP:
            if (elapsed >= FINDCAR_GAP_MS) {
                digitalWrite(PIN_LOCK, LOW);
                currentAction = ACTION_FINDCAR_STEP2;
                actionStartTime = millis();
                Serial.println("[GPIO] FindCar step2");
            }
            break;

        case ACTION_FINDCAR_STEP2:
            if (elapsed >= FINDCAR_PULSE_MS) {
                digitalWrite(PIN_LOCK, HIGH);
                currentAction = ACTION_NONE;
                vehicleBusy = false;
                Serial.println("[GPIO] FindCar complete");
            }
            break;

        default:
            currentAction = ACTION_NONE;
            vehicleBusy = false;
            break;
    }
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

// ==================== DISCONNECT HANDLER ====================
void handleDisconnect() {
    // Release all vehicle GPIOs first
    releaseAllPins();

    // Double-lock if authenticated
    if (wasAuthenticated) {
        Serial.println("[DISC] Auto double-lock engaged");
        digitalWrite(PIN_LOCK, LOW);
        delay(LOCK_PULSE_MS);
        digitalWrite(PIN_LOCK, HIGH);
        delay(DISCONNECT_LOCK_DELAY);
        digitalWrite(PIN_LOCK, LOW);
        delay(LOCK_PULSE_MS);
        digitalWrite(PIN_LOCK, HIGH);
        Serial.println("[DISC] Double-lock complete");
    }
}
