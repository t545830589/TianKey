# TianKey

## AI / 开发入口规则

进入 TianKey 项目后，任何 AI 或开发者必须先恢复项目上下文。

唯一入口链：

```text
START_HERE.md
↓
AI_ENTRY_RULES.md
↓
PROJECT_MEMORY_INDEX.md
↓
project_memory/
```

详细记忆导航由 `PROJECT_MEMORY_INDEX.md` 维护。

## 项目原则

TianKey 不是简单按钮控制 APP。

目标：

实现完整手机车钥匙系统：

APP
↓
业务逻辑
↓
BLE 抽象层
↓
ESP32
↓
车辆控制

## 开发规则

禁止：

- 未读取项目记忆直接修改代码
- 根据个人理解改变产品目标
- 删除未知用途代码
- 只开发界面而忽略完整流程

必须：

- 先确认当前项目状态
- 查看 `CURRENT_TASK.md`
- 修改后更新 `CHANGE_LOG.md`
- 重大决定记录到 `DECISION_HISTORY.md`

## 当前项目入口

请从：

`START_HERE.md`

开始。
