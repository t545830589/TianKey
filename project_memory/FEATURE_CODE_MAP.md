# Feature Code Map

## Purpose
建立目标 APK 功能与真实代码之间的长期映射。

规则：

功能
↓
页面/UI
↓
代码文件
↓
验证状态
↓
下一步

禁止只根据文件名判断完成状态，必须有代码和验证依据。

---

## Feature 001 - Vehicle Control

状态：代码存在，验证未闭环

页面/UI：
- TianKeyHome 首页车辆控制区域

代码：
- lib/main.dart
- lib/ble_service.dart

已有能力：
- 锁车
- 解锁
- 车辆命令入口
- BLE连接调用

未闭环：
- 真实车辆/ESP32命令验证
- 状态回传闭环

下一步：
建立车辆命令协议与真实硬件验证记录。

---

## Feature 002 - BLE Connection

状态：代码存在，真实验证未闭环

代码：
- lib/main.dart
- lib/ble_service.dart

已有能力：
- 扫描
- 连接
- 断开
- 状态管理

未闭环：
- 完整GATT协议验证
- ESP32真实通信验证

下一步：
补充BLE协议映射。

---

## Feature 003 - Temporary Borrow

状态：部分代码存在，流程未完全验证

代码：
- lib/main.dart

已有能力：
- 借车码
- 有效时间判断
- 借车权限状态

未闭环：
- 完整授权流程测试

下一步：
建立授权流程验证记录。

---

## Feature 004 - Permission Management

状态：部分代码存在

代码：
- lib/main.dart

已有能力：
- 管理员模式
- 管理员密码
- 管理员设备记录

未闭环：
- 多设备权限真实验证

下一步：
建立权限状态映射。
