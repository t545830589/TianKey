# TianKey Scenario Database

## Purpose

Record complete user journeys, not isolated buttons.

Every development task should map to one or more scenarios.

## Scenario Format

Each scenario contains:

- Trigger
- User action
- APP state
- BLE state
- Permission result
- Expected result
- Exception handling

## Initial Scenario Index

### SC-001 Vehicle Approach Auto Connection

Trigger:
User approaches vehicle.

Flow:
APP detects available vehicle -> BLE connection -> identity check -> control availability.

### SC-002 First Authorization

Trigger:
New device connection.

Flow:
Pairing -> permission verification -> authorized state.

### SC-003 Administrator Operation

Trigger:
Administrator enters management mode.

Flow:
Authentication -> management functions -> record operation.

### SC-004 Temporary Vehicle Access

Trigger:
Temporary user needs vehicle access.

Flow:
Temporary credential -> validation -> limited access.

### SC-005 Connection Failure Recovery

Trigger:
BLE disconnect or connection failure.

Flow:
Detect failure -> notify user -> retry/reconnect -> record result.

## Rule

The final application must cover normal and abnormal scenarios.
