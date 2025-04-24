import CoreGraphics
import Foundation
import ApplicationServices
import AppKit

public class MouseKeyboardEmulator {
    // 单例模式
    public static let shared = MouseKeyboardEmulator()

    private var lastMousePosition: CGPoint
    private var pressedKeys: Set<Int>
    private var hasAccessibilityAccess: Bool = false

    private init() {
        self.lastMousePosition = .zero
        self.pressedKeys = []
        checkAccessibilityPermission()
        updateCurrentMousePosition()
    }

    // MARK: - Accessibility Permission

    /// 检查辅助功能权限
    private func checkAccessibilityPermission() {
        // 首先检查是否已经获得权限
        if AXIsProcessTrusted() {
            hasAccessibilityAccess = true
            print("[Status] 已获得辅助功能权限")
            return
        }
        
        // 如果没有权限，使用 AXIsProcessTrustedWithOptions 来请求权限
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        hasAccessibilityAccess = AXIsProcessTrustedWithOptions(options)
        
        if !hasAccessibilityAccess {
            print("[Error] 需要辅助功能权限才能模拟鼠标和键盘输入")
            openAccessibilitySettings()
        }
    }
    
    /// 打开系统设置
    private func openAccessibilitySettings() {
        print("[Action] 正在打开系统设置...")
        
        // 获取当前程序的路径
        guard let executablePath = Bundle.main.executablePath else {
            print("[Error] 无法获取程序路径")
            return
        }
        
        print("[Debug] 程序路径: \(executablePath)")
        
        // 尝试打开应用程序文件夹以添加权限
        NSWorkspace.shared.selectFile(executablePath, 
                                    inFileViewerRootedAtPath: "")
        
        // 打开系统偏好设置的辅助功能面板
        if #available(macOS 13.0, *) {
            // Ventura 及以上版本使用新的 URL scheme
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
                
                // 显示提示信息
                print("[Action] 请在系统设置中找到程序: \(executablePath)")
                print("[Action] 并点击 + 按钮将其添加到列表中")
            }
        } else {
            // 较早版本使用传统方式
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
                
                // 显示提示信息
                print("[Action] 请在系统设置中找到程序: \(executablePath)")
                print("[Action] 并点击 + 按钮将其添加到列表中")
            }
        }

        // 开始监听权限变化
        startAccessibilityPermissionMonitoring()
    }

    /// 开始监听权限变化
    private func startAccessibilityPermissionMonitoring() {
        DispatchQueue.global().async { [weak self] in
            while true {
                // 使用 options 来检查权限状态
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
                if AXIsProcessTrustedWithOptions(options) {
                    DispatchQueue.main.async {
                        print("[Status] 已成功获得辅助功能权限！")
                        self?.hasAccessibilityAccess = true
                    }
                    break
                }
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
    }

    // MARK: - Mouse Control

    /// 更新当前鼠标位置
    private func updateCurrentMousePosition() {
        guard hasAccessibilityAccess else { return }
        
        // 重新验证权限
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            hasAccessibilityAccess = false
            print("[Error] 辅助功能权限已丢失")
            checkAccessibilityPermission()
            return
        }
        
        var point = CGPoint.zero
        if let event = CGEvent(source: nil) {
            point = event.location
        }
        lastMousePosition = point
    }

    /// 移动鼠标（相对移动）
    public func moveMouseRelative(dx: Double, dy: Double) {
        guard hasAccessibilityAccess else {
            print("[Error] 无法移动鼠标：需要辅助功能权限")
            return
        }

        let newX = lastMousePosition.x + CGFloat(dx)
        let newY = lastMousePosition.y + CGFloat(dy)

        if let event = CGEvent(
            mouseEventSource: nil, mouseType: .mouseMoved,
            mouseCursorPosition: CGPoint(x: newX, y: newY), mouseButton: .left)
        {
            event.post(tap: .cghidEventTap)
            lastMousePosition = CGPoint(x: newX, y: newY)
        }
    }

    /// 鼠标点击
    public func mouseClick(button: CGMouseButton, type: CGEventType) {
        guard hasAccessibilityAccess else {
            print("[Error] 无法点击鼠标：需要辅助功能权限")
            return
        }

        if let event = CGEvent(
            mouseEventSource: nil, mouseType: type, mouseCursorPosition: lastMousePosition,
            mouseButton: button)
        {
            print("[Action] Mouse click: \(type) at \(lastMousePosition)")
            event.post(tap: .cghidEventTap)
        } else {
            print("[Error] 创建鼠标事件失败")
        }
    }

    /// 鼠标左键点击
    public func leftClick() {
        guard hasAccessibilityAccess else { return }
        mouseClick(button: .left, type: .leftMouseDown)
        mouseClick(button: .left, type: .leftMouseUp)
    }

    /// 鼠标右键点击
    public func rightClick() {
        print("[Action] Right click access \(hasAccessibilityAccess)")
        guard hasAccessibilityAccess else { return }
        print("Right click")
        mouseClick(button: .right, type: .rightMouseDown)
        mouseClick(button: .right, type: .rightMouseUp)
    }

    /// 鼠标滚轮
    public func scroll(dy: Double) {
        guard hasAccessibilityAccess else {
            print("[Error] 无法滚动：需要辅助功能权限")
            return
        }

        if let event = CGEvent(
            scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: Int32(dy),
            wheel2: 0, wheel3: 0)
        {
            event.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Keyboard Control

    /// 按下键盘按键
    public func keyDown(keyCode: Int) {
        guard hasAccessibilityAccess else {
            print("[Error] 无法按下按键：需要辅助功能权限")
            return
        }

        guard !pressedKeys.contains(keyCode) else { return }

        if let event = CGEvent(
            keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true)
        {
            event.post(tap: .cghidEventTap)
            pressedKeys.insert(keyCode)
        }
    }

    /// 释放键盘按键
    public func keyUp(keyCode: Int) {
        guard hasAccessibilityAccess else {
            print("[Error] 无法释放按键：需要辅助功能权限")
            return
        }

        guard pressedKeys.contains(keyCode) else { return }

        if let event = CGEvent(
            keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: false)
        {
            event.post(tap: .cghidEventTap)
            pressedKeys.remove(keyCode)
        }
    }

    /// 按下并释放键盘按键
    public func keyPress(keyCode: Int) {
        guard hasAccessibilityAccess else { return }
        keyDown(keyCode: keyCode)
        keyUp(keyCode: keyCode)
    }

    /// 组合键
    public func keyCombo(_ keyCodes: [Int]) {
        guard hasAccessibilityAccess else {
            print("[Error] 无法执行组合键：需要辅助功能权限")
            return
        }

        // 确保开始前所有相关按键都是释放状态
        for keyCode in keyCodes {
            if pressedKeys.contains(keyCode) {
                keyUp(keyCode: keyCode)
            }
        }

        // 按下所有键
        var pressedSuccessfully: [Int] = []
        for keyCode in keyCodes {
            if let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true) {
                event.post(tap: .cghidEventTap)
                pressedKeys.insert(keyCode)
                pressedSuccessfully.append(keyCode)
            } else {
                print("[Error] 无法按下按键: \(keyCode)")
                // 如果某个按键失败，释放之前成功的按键
                for successKey in pressedSuccessfully {
                    keyUp(keyCode: successKey)
                }
                return
            }
            // 每个按键之间添加小延迟，确保系统能正确识别
            usleep(10000) // 10ms delay
        }

        // 保持组合键状态一段时间
        usleep(100000) // 100ms delay

        // 按相反顺序释放所有键
        for keyCode in keyCodes.reversed() {
            keyUp(keyCode: keyCode)
            usleep(10000) // 10ms delay
        }
    }

    /// 执行按键行为
    public func executeAction(_ action: ButtonAction) {
        print("[Action] Executing action: \(action)")
        
        switch action {
        case .mouseMove(let dx, let dy):
            moveMouseRelative(dx: dx, dy: dy)

        case .mouseLeftClick:
            leftClick()

        case .mouseRightClick:
            rightClick()

        case .mouseMiddleClick:
            mouseClick(button: .center, type: .otherMouseDown)
            mouseClick(button: .center, type: .otherMouseUp)

        case .mouseScroll(let dy):
            scroll(dy: dy)

        case .keyPress(let keyCode):
            keyPress(keyCode: keyCode)

        case .keyHold(let keyCode):
            keyDown(keyCode: keyCode)

        case .keyRelease(let keyCode):
            keyUp(keyCode: keyCode)

        case .keyCombo(let keyCodes):
            keyCombo(keyCodes)

        case .none:
            break

        case .custom:
            // 自定义行为预留
            break
        }
    }
}
