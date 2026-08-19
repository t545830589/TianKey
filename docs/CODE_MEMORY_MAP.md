# TianKey Code Memory Map

## Purpose

This file connects repository code with project requirements and prevents AI context loss.

Format:

Code file -> Responsibility -> Requirement -> Status -> Missing -> Next action

---

# BLE Module

## lib/ble_service.dart

Responsibility:
- BLE scanning
- Device connection lifecycle
- GATT service discovery

Requirement mapping:
- REQ-BLE-DISCOVERY
- REQ-BLE-CONNECTION
- REQ-BLE-GATT

Status:
- BLE foundation implemented
- ESP32 vehicle protocol not connected

Missing:
- TianKey UUID mapping
- Vehicle command binding

---

## lib/ble_connection_state.dart

Responsibility:
- BLE connection lifecycle state model

Requirement mapping:
- REQ-BLE-CONNECTION

Status:
- Connection state model exists

Missing:
- Full reconnect strategy
- Recovery callbacks

---

## lib/ble_device_profile.dart

Responsibility:
- BLE device structure model
- Service and characteristic description

Requirement mapping:
- REQ-BLE-DEVICE-DISCOVERY

Status:
- Device discovery model exists

Missing:
- ESP32 hardware identity mapping

---

## lib/ble_protocol_layer.dart

Responsibility:
- BLE packet abstraction
- Request/response protocol framework

Requirement mapping:
- REQ-BLE-PROTOCOL

Status:
- Protocol foundation exists

Missing:
- ESP32 command frames
- CRC/check rules
- Vehicle data parsing

---

## lib/ble_state_cache.dart

Responsibility:
- BLE state storage

Requirement mapping:
- REQ-BLE-STATE

Status:
- Basic cache exists

Missing:
- Vehicle state storage

---

## lib/ble_state_sync.dart

Responsibility:
- State synchronization layer

Requirement mapping:
- REQ-BLE-STATE-SYNC

Status:
- Basic sync exists

Missing:
- Real vehicle state synchronization

---

# Architecture Issues

## BLE State Management Duplication

Related files:
- ble_connection_state.dart
- ble_state_cache.dart
- ble_state_sync.dart
- possible state definitions inside other BLE files

Decision:
Do not delete yet.

Future action:
Merge into unified state manager after audit completion.

---

# Current Blocking Items

1. ESP32 communication protocol definition
2. Vehicle command layer
3. Vehicle state parsing
4. Complete code-to-requirement mapping

---

# Audit Rule

Every scanned file must update this map before moving to the next module.
