import Foundation

print("GamepadSwift is starting...")

// 启动应用
let app = App.shared
app.start()

// 确保 RunLoop 持续运行
RunLoop.current.run()