# TianKey File Map

## Responsibility

This file only records **directory and file location mapping**.

It answers:

> Where is the code located?

It does not define:

- feature completion status
- code verification result
- requirement completion

Those belong to:

- FEATURE_PROGRESS.md
- REAL_CODE_AUDIT.md
- CODE_AUDIT_MAP.md

## Flutter Structure

- lib/: application source
- pages/: page layer
- widgets/: UI component layer
- services/: service logic layer
- models/: data model layer

## BLE Structure

Record locations for:

- scan
- connection
- GATT
- characteristic
- notify
- data parsing

## Mapping Rule

Final mapping chain:

Requirement
→ Feature
→ File Location
→ Real Code Audit
→ Current State
→ Missing Part
→ Next Action
