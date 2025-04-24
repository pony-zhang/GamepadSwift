import Foundation
import AppKit

public final class App: NSObject {
    private var statusItem: NSStatusItem?
    private let gamepadManager: GamepadManager
    
    public static let shared = App()
    
    private override init() {
        self.gamepadManager = GamepadManager.shared
        super.init()
        
        DispatchQueue.main.async { [weak self] in
            self?.setupStatusBar()
        }
        print("[Status] GamepadSwift App Started")
    }
    
    private func setupStatusBar() {
        print("[Debug] Setting up status bar...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            print("[Debug] Configuring status bar button...")
            // 使用系统SF Symbol
            if let image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: nil) {
                image.size = NSSize(width: 18, height: 18)
                button.image = image
                print("[Debug] Status bar icon set successfully")
            }
            setupMenu()
        } else {
            print("[Error] Failed to create status bar button")
        }
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "GamepadSwift", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    public func start() {
        gamepadManager.startMonitoring()
    }
}