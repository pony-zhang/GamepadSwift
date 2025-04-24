import Foundation

public struct GamepadConfig: Codable {
    // 配置文件版本
    public let version: String
    
    // 配置名称
    public let name: String
    
    // 按键映射配置
    public var buttonMappings: [ButtonMappingConfig]
    
    // 全局设置
    public var settings: GamepadSettings
    
    public init(version: String = "1.0",
                name: String = "Default",
                buttonMappings: [ButtonMappingConfig] = [],
                settings: GamepadSettings = GamepadSettings()) {
        self.version = version
        self.name = name
        self.buttonMappings = buttonMappings
        self.settings = settings
    }
}

// 用于JSON序列化的按键映射配置
public struct ButtonMappingConfig: Codable {
    public let buttonId: String
    public let actionType: String
    public let actionParams: [String: String]
    public let sensitivity: Double
    public let deadzone: Double
    
    public init(buttonId: String,
                actionType: String,
                actionParams: [String: String] = [:],
                sensitivity: Double = 1.0,
                deadzone: Double = 0.1) {
        self.buttonId = buttonId
        self.actionType = actionType
        self.actionParams = actionParams
        self.sensitivity = sensitivity
        self.deadzone = deadzone
    }
    
    // 转换为ButtonMapping
    public func toButtonMapping() -> ButtonMapping {
        let action: ButtonAction = parseAction(type: actionType, params: actionParams)
        return ButtonMapping(buttonId: buttonId,
                           action: action,
                           sensitivity: sensitivity,
                           deadzone: deadzone)
    }
    
    // 解析action
    private func parseAction(type: String, params: [String: String]) -> ButtonAction {
        switch type {
        case "mouseMove":
            let dx = Double(params["dx"] ?? "0") ?? 0
            let dy = Double(params["dy"] ?? "0") ?? 0

            let wheeldirection = params["wheeldirection"] ?? "win"
            if wheeldirection == "win" {
                return .mouseMove(dx: dx, dy: -dy)
            }
            return .mouseMove(dx: dx, dy: dy)
            
        case "mouseLeftClick":
            return .mouseLeftClick
            
        case "mouseRightClick":
            return .mouseRightClick
            
        case "mouseMiddleClick":
            return .mouseMiddleClick
            
        case "mouseScroll":
            let dy = Double(params["dy"] ?? "0") ?? 0
            return .mouseScroll(dy: dy)
            
        case "keyPress":
            let keyCode = Int(params["keyCode"] ?? "0") ?? 0
            return .keyPress(keyCode: keyCode)
            
        case "keyHold":
            let keyCode = Int(params["keyCode"] ?? "0") ?? 0
            return .keyHold(keyCode: keyCode)
            
        case "keyRelease":
            let keyCode = Int(params["keyCode"] ?? "0") ?? 0
            return .keyRelease(keyCode: keyCode)
            
        case "keyCombo":
            let keyCodes = (params["keyCodes"] ?? "")
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            return .keyCombo(keyCodes)
            
        case "custom":
            return .custom(params["action"] ?? "")
            
        default:
            return .none
        }
    }
}

// 全局设置
public struct GamepadSettings: Codable {
    // 鼠标移动速度
    public var mouseSpeed: Double
    
    // 鼠标加速度
    public var mouseAcceleration: Double
    
    // 摇杆死区
    public var stickDeadzone: Double
    
    // 扳机键死区
    public var triggerDeadzone: Double
    
    public init(mouseSpeed: Double = 1.0,
                mouseAcceleration: Double = 1.0,
                stickDeadzone: Double = 0.1,
                triggerDeadzone: Double = 0.1) {
        self.mouseSpeed = mouseSpeed
        self.mouseAcceleration = mouseAcceleration
        self.stickDeadzone = stickDeadzone
        self.triggerDeadzone = triggerDeadzone
    }
}