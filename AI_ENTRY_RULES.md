# TianKey AI Entry Rules

## Purpose

This file defines the required working rules for any AI entering the project.

The memory navigation path is maintained by PROJECT_MEMORY_INDEX.md.
This file does not define a separate project reading map.

## Mandatory Behavior

Before analyzing code or making changes:

- Restore project context through the official memory entry chain
- Confirm current task and project status
- Understand existing decisions before changing architecture

## Development Rules

Do not:

- Directly modify code before understanding the project state
- Recreate completed decisions
- Remove unknown files
- Replace architecture without documentation

Must:

- Check current task before working
- Update status after major progress
- Record important decisions
- Record modifications in CHANGE_LOG

## Goal

Ensure TianKey can continue development across different AI models and sessions without losing project context.
