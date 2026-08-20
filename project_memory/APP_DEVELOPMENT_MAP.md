# TianKey APP Development Map

## Purpose

This file maps the real APP development chain so a new AI can understand the project without relying on previous chat history.

## Development Chain

Target Requirement
↓
Feature Module
↓
UI/Page
↓
Code Location
↓
Current Status
↓
Next Action

## Current Mapping Status

### APP Goal

TianKey is a Flutter APP + BLE + ESP32 smart vehicle control system.

### Known Modules

| Module | Mapping Source | Status |
|---|---|---|
| UI Pages | UI_MAPPING.md | Need continuous verification with target design |
| Features | FEATURE_PROGRESS.md | Need continuous verification |
| BLE | BLE_STATUS.md | Need continuous verification |
| Code | FILE_MAP.md / REAL_CODE_AUDIT.md | Need continuous verification |

## Rules

- This file is a connection map, not a replacement for detailed records.
- Real code status must come from repository inspection.
- Every major development change must update the related mapping and CHANGE_LOG.

## Closure Requirement

A feature is considered closed only when:

1. Requirement is identified.
2. UI location is mapped.
3. Code location is mapped.
4. Actual implementation status is verified.
5. Next action is clear.
