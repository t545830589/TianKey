# Architecture Refactor Queue

## Purpose
记录已经发现但不能立即破坏性重构的问题，避免 AI 忘记原因。

## Issue 001 - main.dart responsibility overload

发现：
当前功能入口、页面状态、BLE调用、权限逻辑、临时借车逻辑集中在 lib/main.dart。

当前状态：
代码可继续开发，但后续功能增加会提高维护风险。

处理原则：
- 不立即大规模重构，避免破坏已有功能。
- 后续按功能闭环逐步拆分。

计划方向：
lib/
├ pages/
├ widgets/
├ services/
├ models/

完成条件：
拆分后功能行为保持一致，并通过运行验证。
