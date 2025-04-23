import Foundation

print("GamepadSwift is starting...")

// 启动应用
let app = App.shared
app.start()

print("GamepadSwift is running and listening for controller input...")

// 确保 RunLoop 持续运行
RunLoop.current.run()