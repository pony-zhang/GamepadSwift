import Foundation

public final class App {
    private let gamepadManager: GamepadManager
    
    public static let shared = App()
    
    private init() {
        self.gamepadManager = GamepadManager.shared
        print("[Status] GamepadSwift App Started")
    }
    
    public func start() {
        gamepadManager.startMonitoring()
    }
}