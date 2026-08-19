# TianKey Code Audit Map

## Purpose

This document records the repository audit state and maps code assets to project memory.

## Audit Phase

Current phase: Code body audit

Flow:

Target documents
→ Project memory
→ Repository audit
→ Code requirement mapping
→ Cleanup / merge / missing features
→ Complete engineering project
→ APK build

## Repository Structure Snapshot

Confirmed top-level assets:

- lib/ : Flutter application source
- docs/ : documentation area
- project_memory/ : project knowledge storage
- assets/ : resources
- pubspec.yaml : Flutter dependency configuration

## Initial Code Mapping

### lib/main.dart

Role:
- Application entry
- Contains vehicle command entry logic
- Contains permission and authorization related logic

Mapped requirements:
- Vehicle operation flow
- User authorization flow

Status:
- Business logic exists
- Needs later refactor into separated services/controllers

### lib/ble_service.dart

Role:
- BLE scan
- Device connection
- GATT discovery

Mapped requirements:
- BLE communication foundation

Status:
- Connection framework exists
- Real command write path requires verification

### lib/ble_protocol_layer.dart

Role:
- Packet/request/response abstraction

Mapped requirements:
- APP and hardware communication protocol layer

Status:
- Protocol framework exists
- Real ESP32 frame specification is not yet mapped

### lib/ble_command_dispatcher.dart

Role:
- Command dispatch abstraction

Mapped requirements:
- Vehicle command routing

Status:
- Dispatcher framework exists
- Real sender implementation requires verification

## Current Known Gaps

1. APP command to BLE write path
2. ESP32 command frame definition
3. Hardware execution feedback loop
4. Requirement-to-file complete matrix

## Audit Rule

Every future audit step must update this map:

File
→ Function
→ Requirement
→ Current state
→ Missing part
→ Next action
