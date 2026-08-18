# TianKey Project Decisions

## Purpose

Record confirmed decisions so future AI models do not redesign settled choices.

## Decision 1: Full simulation first

Decision:

Complete APP simulation before real ESP32 integration.

Reason:

The APP logic, permissions, states and scenarios must be verified without depending on hardware availability.

## Decision 2: ESP32 is a second phase

Decision:

Simulation BLE is replaced by real BLE later.

Reason:

Hardware integration should not block APP logic completion.

## Decision 3: Keep administrator mode

Decision:

Administrator functions remain in the APP.

Reason:

Required for personal management and configuration.

## Decision 4: No payment features

Decision:

Payment or commercial charging functions are not part of the product.

Reason:

This is a personal vehicle key system.

## Rule

New AI or developers must read this file before changing confirmed architecture decisions.
