# TianKey Requirement Traceability

## Purpose

This document connects the final product requirements to implementation status.

The goal is to prevent incomplete development where only simple controls are implemented.

## Final Product Rule

TianKey is a personal BLE vehicle key system:

Flutter APP
↕
BLE
↕
ESP32
↕
Vehicle control circuit

The first development stage must complete a full APP simulation before replacing simulated communication with real ESP32 communication.

## Requirement Tracking

| Feature Area | Requirement | Status |
|---|---|---|
| Startup | Application startup flow | Pending audit |
| Bluetooth | Scan and discover vehicle | Pending audit |
| Connection | Connect and reconnect flow | Pending audit |
| Automatic connection | Vehicle proximity connection logic | Pending audit |
| Administrator | Admin mode and management | Pending audit |
| Temporary access | Temporary vehicle access flow | Pending audit |
| Authentication | Password and permission checks | Pending audit |
| Authorization | First authorization and permission state | Pending audit |
| Time sync | Normal and failure simulation | Pending audit |
| Vehicle control | Lock/unlock/find simulation | Pending audit |
| Settings | User configuration | Pending audit |
| Logs | Event logging and cleanup | Pending audit |
| Exceptions | Disconnect and abnormal states | Pending audit |
| ESP32 | Replace simulation with real BLE | Phase 2 |

## Rule

No feature is considered complete only because a button exists.

Completion requires:

- UI state
- Logic state
- Permission state
- Exception handling
- Test verification
