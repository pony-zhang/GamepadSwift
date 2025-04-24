import AppKit

NSApplication.shared.setActivationPolicy(.accessory)  // 设置为状态栏应用

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 启动应用
_ = App.shared
app.run()