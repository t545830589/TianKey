# TianKey 修改记录

## Batch 000

时间：2026-08-18

内容：
- 建立项目记忆系统
- 创建项目目标文档
- 创建当前状态文档

目的：
防止开发过程中遗忘目标、重复修改、任务丢失。

规则：
以后每次代码修改必须同步更新此文件。

---

## Batch 001

问题：
缺少当前执行断点，AI重新进入仓库时可能无法恢复正在进行的工作。

解决：
- 创建 project_memory/CURRENT_TASK.md
- 明确当前任务ID、目标、正在处理文件、下一步动作、完成证据

影响：
记忆系统增加执行恢复节点，形成从任务到历史记录的闭环。

---

## Batch 002 - Memory Closure 01

问题：
AI进入项目时存在多个入口文件重复定义读取顺序，可能导致不同AI采用不同恢复路径。

解决：
- 统一 START_HERE.md、AI_ENTRY_RULES.md、PROJECT_MEMORY_INDEX.md 的职责
- START_HERE 负责入口说明
- AI_ENTRY_RULES 负责AI行为规则
- PROJECT_MEMORY_INDEX 负责唯一记忆导航
- 修正 CURRENT_TASK.md 中失效状态文件引用

影响：
AI恢复路径统一为：
START_HERE → AI_ENTRY_RULES → PROJECT_MEMORY_INDEX → project_memory

状态：
Memory Closure 01 继续处理中。

---

## Batch 003 - Memory Closure 01 checkpoint

检查范围：
project_memory/

确认：
- PROJECT_MEMORY_INDEX.md 已定义唯一恢复入口
- CURRENT_STATUS.md 作为真实状态入口
- CURRENT_TASK.md 作为执行任务入口
- CHANGE_LOG.md 作为修改历史入口
- TODO_QUEUE.md 作为后续任务入口

发现：
.batch_001_trigger 属于历史批次触发标记，不参与AI恢复链。

处理决定：
暂不删除，避免破坏历史批次追踪；后续统一清理历史标记文件。

状态：
Memory Closure 01 继续处理中。