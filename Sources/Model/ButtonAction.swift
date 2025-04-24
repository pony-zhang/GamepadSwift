import Foundation

/// 定义按键可以映射的行为类型
public enum ButtonAction {
    // 鼠标相关
    case mouseMove(dx: Double, dy: Double)  // 鼠标移动（相对位置）
    case mouseLeftClick                     // 鼠标左键
    case mouseRightClick                    // 鼠标右键
    case mouseMiddleClick                   // 鼠标中键
    case mouseScroll(dy: Double)            // 鼠标滚轮
    
    // 键盘相关
    case keyPress(keyCode: Int)             // 键盘按键
    case keyHold(keyCode: Int)              // 键盘按住
    case keyRelease(keyCode: Int)           // 键盘释放
    case keyCombo([Int])                    // 组合键
    
    // 特殊行为
    case none                               // 不执行任何操作
    case custom(String)                     // 自定义行为（预留扩展）
}

/// 按键映射配置结构
public struct ButtonMapping {
    public let buttonId: String             // 手柄按键标识
    public let action: ButtonAction         // 映射的行为
    public let sensitivity: Double          // 灵敏度（用于摇杆和扳机）
    public let deadzone: Double            // 死区值（用于摇杆）
    
    public init(buttonId: String, action: ButtonAction, sensitivity: Double = 1.0, deadzone: Double = 0.1) {
        self.buttonId = buttonId
        self.action = action
        self.sensitivity = sensitivity
        self.deadzone = deadzone
    }
}