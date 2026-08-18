# TianKey Project Context

## Project Goal
Build TianKey real vehicle control Flutter application based on provided UI design.

## UI Rules
- Final UI image is the acceptance target.
- Do not redesign.
- Use provided visual assets as the base layer.
- Flutter widgets provide interaction and real state binding.

## Development Rules
- No fake vehicle data.
- BLE functions must connect to real device protocol.
- Every batch must pass Flutter analysis/build before continuing.

## Architecture Direction
UI:
assets/background + Flutter widgets + BLE state

BLE flow:
scan -> connect -> discover services -> characteristic read/write -> notify -> parse -> update UI

## Current Focus
Batch development: homepage component system.

## Required Modules
- Home vehicle display
- Bluetooth connection
- Lock/unlock
- Window controls
- Trunk control
- Find vehicle
- Admin authorization
- Temporary borrowing
- Settings
