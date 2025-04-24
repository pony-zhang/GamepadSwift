import Foundation
import GameController

public class InputMapper {
    // 单例模式
    public static let shared = InputMapper()

    private var config: GamepadConfig
    private let emulator: MouseKeyboardEmulator

    // 用于处理摇杆输入的计时器
    private var analogTimer: Timer?
    private var lastStickValues: [String: (x: Double, y: Double)] = [:]

    private init() {
        // 加载默认配置
        self.config = GamepadConfig()
        self.emulator = MouseKeyboardEmulator.shared
        setupAnalogTimer()
    }

    // MARK: - Configuration

    /// 加载配置
    public func loadConfig(from url: URL) throws {
        let data = try Data(contentsOf: url)
        config = try JSONDecoder().decode(GamepadConfig.self, from: data)
        print("[Status] Config loaded: \(config.name)")
    }

    /// 保存配置
    public func saveConfig(to url: URL) throws {
        let data = try JSONEncoder().encode(config)
        try data.write(to: url)
        print("[Status] Config saved: \(config.name)")
    }

    // MARK: - Input Handling

    /// 处理按钮输入
    public func handleButtonInput(buttonId: String, value: Float, pressed: Bool) {
        print("[Status] Button \(buttonId) value: \(value), pressed: \(pressed)")
        guard let mapping = config.buttonMappings.first(where: { $0.buttonId == buttonId }) else {
            print("[Error] No mapping found for button \(buttonId)")
            return
        }

        let buttonMapping = mapping.toButtonMapping()

        // 检查死区
        if abs(Double(value)) < buttonMapping.deadzone {
            print("[Warning] Button \(buttonId) value \(value) is within deadzone")
            return
        }

        // 根据按钮状态执行相应动作
        if pressed {
            emulator.executeAction(buttonMapping.action)
        } else {
            // 对于某些动作，需要在释放时执行相反操作
            switch buttonMapping.action {
            case .keyHold(let keyCode):
                emulator.executeAction(.keyRelease(keyCode: keyCode))
            default:
                break
            }
        }
    }

    /// 处理摇杆输入
    public func handleStickInput(stickId: String, x: Float, y: Float) {
        guard let mapping = config.buttonMappings.first(where: { $0.buttonId == stickId }) else {
            return
        }

        let stickMapping = mapping.toButtonMapping()

        // 应用死区
        let xValue = abs(Double(x)) < stickMapping.deadzone ? 0 : Double(x)
        let yValue = abs(Double(y)) < stickMapping.deadzone ? 0 : Double(y)

        // 保存当前值用于计时器更新
        lastStickValues[stickId] = (x: xValue, y: yValue)
    }

    // MARK: - Analog Timer

    private func setupAnalogTimer() {
        // 创建一个定时器来平滑处理模拟输入
        analogTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) {
            [weak self] _ in
            self?.updateAnalogInputs()
        }
    }

    private func updateAnalogInputs() {
        // 处理所有摇杆的持续输入
        for (stickId, values) in lastStickValues {
            guard let mapping = config.buttonMappings.first(where: { $0.buttonId == stickId })
            else {
                continue
            }
            //TODO: 这儿需要处理win和mac的差异
            let stickMapping = mapping.toButtonMapping()
            var dx: Double = 0
            var dy: Double = 0
            if mapping.actionParams["wheeldirection"] == "win" {
                dx = values.x * stickMapping.sensitivity * config.settings.mouseSpeed
                dy = -values.y * stickMapping.sensitivity * config.settings.mouseSpeed
            } else {
                // 应用灵敏度
                dx = values.x * stickMapping.sensitivity * config.settings.mouseSpeed
                dy = values.y * stickMapping.sensitivity * config.settings.mouseSpeed
            }

            if abs(dx) <= stickMapping.deadzone && abs(dy) <= stickMapping.deadzone {
                continue  // 忽略小于死区的输入
            }

            // 执行动作（如鼠标移动）
            switch stickMapping.action {
            case .mouseMove:
                emulator.executeAction(.mouseMove(dx: dx, dy: dy))
            default:
                break
            }
        }
    }

    deinit {
        analogTimer?.invalidate()
    }
}
