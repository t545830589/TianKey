# TianKey Requirement Database

## Purpose

This document is the permanent requirement source for TianKey.

The goal is to prevent future AI models from reducing the project into a simple BLE button demo.

## Product Definition

TianKey is a personal BLE mobile vehicle key system.

Core direction:

- Flutter mobile application
- BLE communication
- ESP32 vehicle-side controller
- Complete application scenario simulation before final hardware integration

## Requirement Tracking Rule

Every feature must have:

1. Requirement ID
2. Scenario reference
3. Implementation location
4. Current status
5. Verification status

## Requirement Groups

### APP Flow

REQ-APP-001 Startup flow

REQ-APP-002 Vehicle discovery

REQ-APP-003 BLE connection state

REQ-APP-004 Automatic connection

REQ-APP-005 Vehicle control interface

### Permission System

REQ-AUTH-001 Administrator mode

REQ-AUTH-002 User authorization

REQ-AUTH-003 Temporary vehicle access

### Security And State

REQ-STATE-001 Connection state management

REQ-STATE-002 Permission validation

REQ-STATE-003 Error handling

REQ-STATE-004 Operation logging

## Development Rule

No feature is considered complete only because the UI exists. The related state, scenario and abnormal process must also exist.
