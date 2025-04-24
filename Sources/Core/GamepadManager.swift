import Foundation
import GameController

public class GamepadManager {
    public static let shared = GamepadManager()
    private var currentController: GCController?
    private var isMonitoring: Bool = false
    private let inputMapper = InputMapper.shared
    
    private init() {
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
        }
    }
    
    private func checkExistingControllers() {
        if let controller = GCController.controllers().first(where: { $0.extendedGamepad != nil }) {
            setupController(controller)
        }
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        GCController.startWirelessControllerDiscovery { [weak self] in
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
    }
    
    private func setupController(_ controller: GCController) {
        // 设置处理队列为主队列
        controller.handlerQueue = .main
        
        // 设置玩家索引
        controller.playerIndex = .index1
        
        // 检查并设置扩展手柄
        if let gamepad = controller.extendedGamepad {
            setupExtendedGamepad(gamepad)
        } else {
            print("[Error] Controller does not support extended gamepad profile")
            return
        }
        
        // 检查haptics支持
        if #available(macOS 11.0, *) {
            if let haptics = controller.haptics {
                setupHaptics(haptics)
            }
            
            // 检查LED灯光支持
            if let light = controller.light {
                setupLight(light)
            }
        }
        
        currentController = controller
    }
    
    private func loadDefaultConfig() {
        // 获取当前模块的 Bundle
        let bundle = Bundle.module
        if let configUrl = bundle.url(forResource: "default_config", withExtension: "json") {
            print("[Debug] Found config at: \(configUrl)")
            do {
                try inputMapper.loadConfig(from: configUrl)
            } catch {
                print("[Error] Failed to load default configuration: \(error)")
            }
        } else {
            print("[Error] Could not find default_config.json in bundle")
            // 打印所有可用的资源文件
            if let resourceURLs = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) {
                print("[Debug] Available json files in bundle: \(resourceURLs)")
            } else {
                print("[Debug] No json files found in bundle")
            }
        }
    }
    
    private func setupExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        // ABXY 按钮
        gamepad.buttonA.valueChangedHandler = { [weak self] (button, value, pressed) in
            self?.inputMapper.handleButtonInput(buttonId: "buttonA", value: value, pressed: pressed)
        }
        
        gamepad.buttonB.valueChangedHandler = { [weak self] (button: GCControllerButtonInput, value, pressed) in
            self?.inputMapper.handleButtonInput(buttonId: "buttonB", value: value, pressed: pressed)
        }
        
        gamepad.buttonX.valueChangedHandler = { [weak self] (button, value, pressed) in
            self?.inputMapper.handleButtonInput(buttonId: "buttonX", value: value, pressed: pressed)
        }
        
        gamepad.buttonY.valueChangedHandler = { [weak self] (button, value, pressed) in
            self?.inputMapper.handleButtonInput(buttonId: "buttonY", value: value, pressed: pressed)
        }
        
        // 方向键
        gamepad.dpad.valueChangedHandler = { [weak self] (dpad, xValue, yValue) in
            if xValue != 0 || yValue != 0 {
                if xValue > 0 {
                    self?.inputMapper.handleButtonInput(buttonId: "dpadRight", value: abs(xValue), pressed: true)
                } else if xValue < 0 {
                    self?.inputMapper.handleButtonInput(buttonId: "dpadLeft", value: abs(xValue), pressed: true)
                }
                if yValue > 0 {
                    self?.inputMapper.handleButtonInput(buttonId: "dpadUp", value: abs(yValue), pressed: true)
                } else if yValue < 0 {
                    self?.inputMapper.handleButtonInput(buttonId: "dpadDown", value: abs(yValue), pressed: true)
                }
            } else {
                self?.inputMapper.handleButtonInput(buttonId: "dpadRight", value: 0, pressed: false)
                self?.inputMapper.handleButtonInput(buttonId: "dpadLeft", value: 0, pressed: false)
                self?.inputMapper.handleButtonInput(buttonId: "dpadUp", value: 0, pressed: false)
                self?.inputMapper.handleButtonInput(buttonId: "dpadDown", value: 0, pressed: false)
            }
        }
        
        // 摇杆
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] (stick, xValue, yValue) in
            self?.inputMapper.handleStickInput(stickId: "leftStick", x: xValue, y: yValue)
        }
        
        gamepad.rightThumbstick.valueChangedHandler = { [weak self] (stick, xValue, yValue) in
            self?.inputMapper.handleStickInput(stickId: "rightStick", x: xValue, y: yValue)
        }
        
        // 肩键
        gamepad.leftShoulder.valueChangedHandler = { [weak self] (button, value, pressed) in
            self?.inputMapper.handleButtonInput(buttonId: "leftShoulder", value: value, pressed: pressed)
        }
        
        gamepad.rightShoulder.valueChangedHandler = { [weak self] (button, value, pressed) in
            self?.inputMapper.handleButtonInput(buttonId: "rightShoulder", value: value, pressed: pressed)
        }
        
        // 扳机键
        gamepad.leftTrigger.valueChangedHandler = { [weak self] (trigger, value, pressed) in
            self?.inputMapper.handleButtonInput(buttonId: "leftTrigger", value: value, pressed: pressed)
        }
        
        gamepad.rightTrigger.valueChangedHandler = { [weak self] (trigger, value, pressed) in
            self?.inputMapper.handleButtonInput(buttonId: "rightTrigger", value: value, pressed: pressed)
        }
        
        // 尝试加载默认配置
        loadDefaultConfig()
        
        // Menu按钮 (macOS 11.0+)
        if #available(macOS 11.0, *) {
            gamepad.buttonMenu.valueChangedHandler = { [weak self] (button, value, pressed) in
                if pressed {
                    self?.handlePauseGame()
                    self?.inputMapper.handleButtonInput(buttonId: "buttonMenu", value: value, pressed: pressed)
                }
            }
        } else {
            gamepad.controller?.controllerPausedHandler = { [weak self] _ in
                self?.handlePauseGame()
                self?.inputMapper.handleButtonInput(buttonId: "buttonMenu", value: 1.0, pressed: true)
            }
        }
    }
    
    private func cleanupController(_ controller: GCController) {
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
    
    @available(macOS 11.0, *)
    @objc private func handleControllerDidBecomeCurrent(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        print("[Status] Controller became current: \(controller.playerIndex.rawValue)")
    }
    
    @available(macOS 11.0, *)
    @objc private func handleControllerDidStopBeingCurrent(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        print("[Status] Controller stopped being current: \(controller.playerIndex.rawValue)")
    }
    
    @available(macOS 13.0, *)
    @objc private func handleControllerUserCustomizationsDidChange(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        if controller == currentController {
            setupController(controller)
            print("[Status] Controller customizations updated")
        }
    }
    
    @objc private func handleControllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            print("[Error] Invalid controller in connection notification")
            return
        }
        print("[Status] Controller connected")
        loadDefaultConfig()
        setupController(controller)
    }
    
    @objc private func handleControllerDidDisconnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            print("[Error] Invalid controller in disconnection notification")
            return
        }
        
        if currentController == controller {
            cleanupController(controller)
            currentController = nil
            print("[Status] Controller disconnected")
        }
    }
    
    private func handlePauseGame() {
        // TODO: 实现具体的暂停逻辑
    }
    
    @available(macOS 11.0, *)
    private func setupHaptics(_ haptics: GCDeviceHaptics) {
        // TODO: 根据需要设置具体的震动效果
    }
    
    @available(macOS 11.0, *)
    private func setupLight(_ light: GCDeviceLight) {
        // TODO: 根据需要设置具体的灯光效果
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
}