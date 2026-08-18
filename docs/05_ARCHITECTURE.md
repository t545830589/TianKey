# TianKey Architecture

版本: V1.0

## 分层结构

UI层

↓

业务逻辑层

↓

Vehicle Controller

↓

BLE通信层

↓

ESP32

## 第一阶段

使用 Mock BLE 模拟设备。

## 第二阶段

替换真实 BLE 与 ESP32通信。

## 原则

UI不直接控制硬件逻辑。
