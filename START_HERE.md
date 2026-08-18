# TianKey START HERE

## ⚠️ AI进入项目必须执行

1. 禁止直接修改代码
2. 必须先读取项目记忆
3. 必须读取当前任务
4. 必须确认项目状态
5. 必须更新记录后再修改

任何 AI 或开发者进入 TianKey 项目，必须先完成项目上下文恢复，禁止依靠聊天历史或个人记忆直接开发。

## 项目记忆恢复顺序（强制）

进入项目后必须依次读取：

1. START_HERE.md
2. docs/00_PROJECT_RULES.md
3. docs/01_PRODUCT_REQUIREMENTS.md
4. docs/02_PROJECT_STATUS.md
5. docs/03_SCENARIO_MATRIX.md
6. docs/04_STATE_MACHINE.md
7. docs/05_ARCHITECTURE.md
8. docs/06_FILE_MAP.md
9. docs/09_DECISION_LOG.md
10. CURRENT_TASK.md
11. CHANGELOG.md

读取完成后，AI 必须确认：

- 项目目标
- 当前阶段
- 已完成内容
- 未完成内容
- 下一步任务
- 不允许改变的设计决策

## 项目入口

TianKey 是一个 Flutter APP + BLE + ESP32 的智能车辆控制系统。

进入项目后的第一原则：先理解项目记忆，再修改代码。

## AI / 开发者必须阅读

请依次读取：

1. docs/00_PROJECT_RULES.md
2. docs/01_PRODUCT_REQUIREMENTS.md
3. docs/02_PROJECT_STATUS.md
4. docs/03_SCENARIO_MATRIX.md
5. docs/04_STATE_MACHINE.md
6. docs/05_ARCHITECTURE.md
7. docs/06_FILE_MAP.md

## 开发规则

禁止：
- 未分析直接重构
- 删除未知代码
- 只做UI不做逻辑
- 忽略已有需求场景

必须：
- 修改前确认职责
- 修改后记录 CHANGELOG
- 重大设计记录 DECISION_LOG

## 技术路线

第一阶段：Mock BLE 完整模拟

第二阶段：替换真实 BLE 与 ESP32 通信

最终目标：完整手机车钥匙体验。
