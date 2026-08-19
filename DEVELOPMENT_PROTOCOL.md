# TianKey Development Protocol

## Purpose

Define the required workflow after any AI or developer performs project work.

## Before Development

The official project recovery chain is:

1. Read START_HERE.md
2. Read AI_ENTRY_RULES.md
3. Read PROJECT_MEMORY_INDEX.md
4. Load required files through project_memory/
5. Check current task and current status from the memory index

This file does not define a separate memory navigation path.

## After Development

Any meaningful change must update the project memory records:

- project_memory/CURRENT_TASK.md
- project_memory/CHANGE_LOG.md
- project_memory/TODO_QUEUE.md when future work changes

Major decisions must update:

- project_memory/DECISION_HISTORY.md

## Rules

Do not leave undocumented changes.
Do not finish a task without recording the next step.
Do not allow future AI sessions to guess project state.

## Goal

Maintain continuous development across different AI models and sessions.
