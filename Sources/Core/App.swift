import Foundation

public final class App {
    private let gamepadManager: GamepadManager
    
    public static let shared = App()
    
    private init() {
        // 初始化各个管理器
        self.gamepadManager = GamepadManager.shared
        print("GamepadSwift App Started...")
    }
    
    public func start() {
    }
}