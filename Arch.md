# **手柄映射工具 - 项目设计书**

## **1. 项目概述**
开发一个 macOS 应用，使用 **Swift + GameController Framework**，实现：
1. **检测 Xbox 手柄的所有按键输入**（摇杆、方向键、ABXY、肩键、扳机键等）。
2. **通过配置文件（JSON）自定义按键映射**（如 A 键映射为鼠标左键，左摇杆映射为鼠标移动）。

---

## **2. 功能需求**
| **功能** | **描述** |
|----------|----------|
| **手柄检测** | 自动识别 Xbox 手柄，监听所有按键输入 |
| **按键映射** | 支持 JSON 配置文件定义按键行为 |
| **鼠标控制** | 摇杆控制鼠标移动，按键模拟点击 |
| **键盘模拟** | 支持映射手柄按键到键盘按键（如 A→空格） |
| **UI 配置界面** | 可视化调整映射（可选，二期实现） |

---

## **3. 技术架构**
### **3.1 系统架构**
```
├── Core/
│   ├── GamepadManager.swift      // 手柄连接管理
│   ├── InputMapper.swift         // 按键映射逻辑
│   └── MouseKeyboardEmulator.swift // 模拟输入
├── Model/
│   ├── GamepadConfig.swift       // 配置文件模型
│   └── ButtonAction.swift        // 按键行为定义
├── Resources/
│   └── default_config.json       // 默认按键配置
└── AppDelegate.swift             // 应用入口
```

### **3.2 核心模块设计**
#### **(1) `GamepadManager` - 手柄管理**
- 监听手柄连接/断开。
- 使用 `GCController` 获取输入数据。
- 将原始输入传递给 `InputMapper`。

#### **(2) `InputMapper` - 按键映射**
- 加载 `GamepadConfig` 配置文件。
- 根据配置将手柄输入转换为 `ButtonAction`（如鼠标移动、键盘按下）。

#### **(3) `MouseKeyboardEmulator` - 输入模拟**
- 使用 `CGEvent` 模拟鼠标移动/点击。
- 使用 `CGPostKeyboardEvent` 模拟键盘输入。

#### **(4) `GamepadConfig` - 配置文件模型**