import Foundation
import GameController

public class GamepadManager {
    public static let shared = GamepadManager()
    private var currentController: GCController?
    private var isMonitoring: Bool = false
    
    private init() {
        print("GamepadManager: Initializing...")
        setupNotifications()
        checkExistingControllers()
    }
    
    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        
        // 基本的连接/断开通知
        notificationCenter.addObserver(
            self,
            selector: #selector(handleControllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(handleControllerDidDisconnect),
            name: .GCControllerDidDisconnect,
            object: nil
        )
        
        // macOS 11.0+ 特定的通知
        if #available(macOS 11.0, *) {
            notificationCenter.addObserver(
                self,
                selector: #selector(handleControllerDidBecomeCurrent),
                name: .GCControllerDidBecomeCurrent,
                object: nil
            )
            
            notificationCenter.addObserver(
                self,
                selector: #selector(handleControllerDidStopBeingCurrent),
                name: .GCControllerDidStopBeingCurrent,
                object: nil
            )
        }
        
        // macOS 13.0+ 用户自定义设置变更通知
        if #available(macOS 13.0, *) {
            notificationCenter.addObserver(
                self,
                selector: #selector(handleControllerUserCustomizationsDidChange),
                name: .GCControllerUserCustomizationsDidChange,
                object: nil
            )
        }
        
        // 开启背景事件处理
        if #available(macOS 11.3, *) {
            GCController.shouldMonitorBackgroundEvents = true
            print("GamepadManager: Background events monitoring enabled")
        }
        
        print("GamepadManager: Notifications setup complete")
    }
    
    private func checkExistingControllers() {
        let controllers = GCController.controllers()
        if let controller = controllers.first(where: { $0.extendedGamepad != nil }) {
            print("GamepadManager: Found existing controller")
            setupController(controller)
        }
    }
    
    public func startMonitoring() {
        guard !isMonitoring else {
            print("GamepadManager: Already monitoring")
            return
        }
        
        isMonitoring = true
        print("GamepadManager: Starting controller discovery...")
        
        GCController.startWirelessControllerDiscovery { [weak self] in
            print("GamepadManager: Controller discovery completed")
            if let controller = GCController.controllers().first(where: { $0.extendedGamepad != nil }) {
                self?.setupController(controller)
            }
        }
    }
    
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        GCController.stopWirelessControllerDiscovery()
        
        if let controller = currentController {
            cleanupController(controller)
        }
        currentController = nil
        
        print("GamepadManager: Stopped monitoring")
    }
    
    private func setupController(_ controller: GCController) {
        print("GamepadManager: Setting up controller: \(controller.description)")
        
        // 设置处理队列为主队列
        controller.handlerQueue = .main
        
        // 设置玩家索引
        controller.playerIndex = .index1
        
        // 检查并设置扩展手柄
        if let gamepad = controller.extendedGamepad {
            setupExtendedGamepad(gamepad)
        } else {
            print("GamepadManager: Controller does not support extended gamepad profile")
            return
        }
        
        // 检查电池状态
        if #available(macOS 11.0, *) {
            if let battery = controller.battery {
                print("GamepadManager: Battery state: \(battery.batteryState.rawValue), level: \(battery.batteryLevel * 100)%")
            }
        }
        
        // 检查haptics支持
        if #available(macOS 11.0, *) {
            if let haptics = controller.haptics {
                print("GamepadManager: Haptics supported")
                // 这里可以设置震动反馈
                setupHaptics(haptics)
            }
            
            // 检查LED灯光支持
            if let light = controller.light {
                print("GamepadManager: Light supported")
                setupLight(light)
            }
        }
        
        currentController = controller
    }
    
    private func setupExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        print("GamepadManager: Setting up extended gamepad...")
        
        // ABXY 按钮
        gamepad.buttonA.valueChangedHandler = { [weak self] (button, value, pressed) in
            print("GamepadManager: Button A - value: \(value), pressed: \(pressed)")
        }
        
        gamepad.buttonB.valueChangedHandler = { [weak self] (button, value, pressed) in
            print("GamepadManager: Button B - value: \(value), pressed: \(pressed)")
        }
        
        gamepad.buttonX.valueChangedHandler = { [weak self] (button, value, pressed) in
            print("GamepadManager: Button X - value: \(value), pressed: \(pressed)")
        }
        
        gamepad.buttonY.valueChangedHandler = { [weak self] (button, value, pressed) in
            print("GamepadManager: Button Y - value: \(value), pressed: \(pressed)")
        }
        
        // 方向键
        gamepad.dpad.valueChangedHandler = { [weak self] (dpad, xValue, yValue) in
            if xValue != 0 || yValue != 0 {
                print("GamepadManager: DPad - x: \(xValue), y: \(yValue)")
            }
        }
        
        // 摇杆
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] (stick, xValue, yValue) in
            if abs(xValue) > 0.1 || abs(yValue) > 0.1 {
                print("GamepadManager: Left Stick - x: \(xValue), y: \(yValue)")
            }
        }
        
        gamepad.rightThumbstick.valueChangedHandler = { [weak self] (stick, xValue, yValue) in
            if abs(xValue) > 0.1 || abs(yValue) > 0.1 {
                print("GamepadManager: Right Stick - x: \(xValue), y: \(yValue)")
            }
        }
        
        // 肩键
        gamepad.leftShoulder.valueChangedHandler = { [weak self] (button, value, pressed) in
            print("GamepadManager: Left Shoulder - value: \(value), pressed: \(pressed)")
        }
        
        gamepad.rightShoulder.valueChangedHandler = { [weak self] (button, value, pressed) in
            print("GamepadManager: Right Shoulder - value: \(value), pressed: \(pressed)")
        }
        
        // 扳机键
        gamepad.leftTrigger.valueChangedHandler = { [weak self] (trigger, value, pressed) in
            if value > 0.1 {
                print("GamepadManager: Left Trigger - value: \(value)")
            }
        }
        
        gamepad.rightTrigger.valueChangedHandler = { [weak self] (trigger, value, pressed) in
            if value > 0.1 {
                print("GamepadManager: Right Trigger - value: \(value)")
            }
        }
        
        // Menu按钮 (macOS 11.0+)
        if #available(macOS 11.0, *) {
            gamepad.buttonMenu.valueChangedHandler = { [weak self] (button, value, pressed) in
                if pressed {
                    print("GamepadManager: Menu Button pressed - Triggering pause")
                    self?.handlePauseGame()
                }
            }
        } else {
            // 对于老版本，使用controllerPausedHandler
            gamepad.controller?.controllerPausedHandler = { [weak self] _ in
                print("GamepadManager: Pause button pressed - Triggering pause")
                self?.handlePauseGame()
            }
        }
        
        print("GamepadManager: Input handlers setup complete")
        printGamepadState(gamepad)
    }
    
    private func cleanupController(_ controller: GCController) {
        print("GamepadManager: Cleaning up controller...")
        if let gamepad = controller.extendedGamepad {
            // 清除所有按键处理器
            gamepad.buttonA.valueChangedHandler = nil
            gamepad.buttonB.valueChangedHandler = nil
            gamepad.buttonX.valueChangedHandler = nil
            gamepad.buttonY.valueChangedHandler = nil
            gamepad.leftShoulder.valueChangedHandler = nil
            gamepad.rightShoulder.valueChangedHandler = nil
            gamepad.leftTrigger.valueChangedHandler = nil
            gamepad.rightTrigger.valueChangedHandler = nil
            gamepad.dpad.valueChangedHandler = nil
            gamepad.leftThumbstick.valueChangedHandler = nil
            gamepad.rightThumbstick.valueChangedHandler = nil
            if #available(macOS 11.0, *) {
                gamepad.buttonMenu.valueChangedHandler = nil
            }
        }
        controller.controllerPausedHandler = nil
    }
    
    private func printGamepadState(_ gamepad: GCExtendedGamepad) {
        print("GamepadManager: Current gamepad state:")
        print("Button A: \(gamepad.buttonA.isPressed)")
        print("Button B: \(gamepad.buttonB.isPressed)")
        print("Button X: \(gamepad.buttonX.isPressed)")
        print("Button Y: \(gamepad.buttonY.isPressed)")
        print("Left Shoulder: \(gamepad.leftShoulder.isPressed)")
        print("Right Shoulder: \(gamepad.rightShoulder.isPressed)")
        print("Left Trigger: \(gamepad.leftTrigger.value)")
        print("Right Trigger: \(gamepad.rightTrigger.value)")
        print("DPad: x=\(gamepad.dpad.xAxis.value), y=\(gamepad.dpad.yAxis.value)")
        print("Left Stick: x=\(gamepad.leftThumbstick.xAxis.value), y=\(gamepad.leftThumbstick.yAxis.value)")
        print("Right Stick: x=\(gamepad.rightThumbstick.xAxis.value), y=\(gamepad.rightThumbstick.yAxis.value)")
    }
    
    // macOS 11.0+ 特定的处理方法
    @available(macOS 11.0, *)
    @objc private func handleControllerDidBecomeCurrent(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        print("GamepadManager: Controller became current: \(controller.description)")
    }
    
    @available(macOS 11.0, *)
    @objc private func handleControllerDidStopBeingCurrent(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        print("GamepadManager: Controller stopped being current: \(controller.description)")
    }
    
    @available(macOS 13.0, *)
    @objc private func handleControllerUserCustomizationsDidChange(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        print("GamepadManager: Controller customizations changed: \(controller.description)")
        // 重新设置控制器，以适应新的自定义设置
        if controller == currentController {
            setupController(controller)
        }
    }
    
    @objc private func handleControllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            print("GamepadManager: Invalid controller in connection notification")
            return
        }
        
        print("GamepadManager: Controller connected: \(controller.description)")
        setupController(controller)
    }
    
    @objc private func handleControllerDidDisconnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            print("GamepadManager: Invalid controller in disconnection notification")
            return
        }
        
        print("GamepadManager: Controller disconnected: \(controller.description)")
        
        if currentController == controller {
            cleanupController(controller)
            currentController = nil
            print("GamepadManager: Current controller removed")
        }
    }
    
    private func handlePauseGame() {
        // 在这里实现游戏暂停逻辑
        print("GamepadManager: Game pause triggered")
        // TODO: 实现具体的暂停逻辑
    }
    
    @available(macOS 11.0, *)
    private func setupHaptics(_ haptics: GCDeviceHaptics) {
        // 这里可以设置不同的震动效果
        print("GamepadManager: Setting up haptics...")
        // TODO: 根据需要设置具体的震动效果
    }
    
    @available(macOS 11.0, *)
    private func setupLight(_ light: GCDeviceLight) {
        // 这里可以设置LED灯光效果
        print("GamepadManager: Setting up light...")
        // TODO: 根据需要设置具体的灯光效果
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
        print("GamepadManager: Cleaned up resources")
    }
}