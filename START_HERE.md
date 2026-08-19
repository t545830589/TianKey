# TianKey START HERE

## ⚠️ AI进入项目必须执行

1. 禁止直接修改代码
2. 必须先读取项目记忆
3. 必须确认当前任务和项目状态
4. 必须完成上下文恢复后再开发
5. 完成工作后必须更新项目记录

任何 AI 或开发者进入 TianKey 项目，必须先恢复项目上下文，禁止依靠聊天历史或个人记忆直接开发。

## 项目入口

TianKey 是一个 Flutter APP + BLE + ESP32 的智能车辆控制系统。

AI进入后的唯一恢复入口：

START_HERE.md
↓
AI_ENTRY_RULES.md
↓
PROJECT_MEMORY_INDEX.md
↓
project_memory/

详细文件导航由 PROJECT_MEMORY_INDEX.md 负责维护。

## 开发规则

禁止：
- 未分析直接重构
- 删除未知代码
- 只做UI不做逻辑
- 忽略已有需求场景

必须：
- 修改前确认职责
- 修改后记录 CHANGE_LOG
- 重大设计记录 DECISION_HISTORY

## 技术路线

第一阶段：Mock BLE 完整模拟

第二阶段：替换真实 BLE 与 ESP32 通信

最终目标：完整手机车钥匙体验。
