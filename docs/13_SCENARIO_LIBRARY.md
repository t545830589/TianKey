# TianKey Scenario Library

## Purpose

Record complete user flows, not isolated buttons.

## Scenario 1: Vehicle Approach

Flow:

User approaches vehicle

→ APP starts

→ BLE discovery

→ Connection attempt

→ Permission check

→ Enter available control state

## Scenario 2: Administrator Flow

Flow:

Admin authentication

→ Permission confirmation

→ Management functions

→ Settings and authorization management

## Scenario 3: Temporary Vehicle Access

Flow:

Temporary password

→ Verification

→ Limited access

→ Expiration handling

## Scenario 4: Connection Failure

Flow:

Connection lost

→ Detect failure

→ Retry connection

→ Show status

→ Record event log

## Scenario 5: ESP32 Transition

Simulation layer

→ Replace BLE transport

→ Replace simulated commands

→ Verify real hardware communication

## Rule

Every important user scenario must define:

- UI state
- Permission state
- Connection state
- Error state
- Recovery path
