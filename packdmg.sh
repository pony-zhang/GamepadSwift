#!/bin/bash

# 定义变量
APP_NAME="GamepadSwift.app"
DMG_NAME="GamepadSwift.dmg"
TEMP_DMG="temp.dmg"
VOLUME_NAME="GamepadSwift"
SIZE="100m"  # 磁盘大小
BUILD_DIR="./build"
CONTENTS_DIR="$BUILD_DIR/$APP_NAME/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 清理旧的构建文件
rm -rf "$BUILD_DIR"
rm -f "$DMG_NAME"
rm -f "$TEMP_DMG"

iconutil -c icns Sources/Resources/AppIcon.iconset -o Sources/Resources/AppIcon.icns

# 构建项目
echo "正在构建项目..."
swift build -c release

# 创建应用程序包结构
echo "创建应用程序包结构..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 复制二进制文件
cp ".build/release/GamepadSwift" "$MACOS_DIR/"

# 复制资源文件
cp "Sources/Info.plist" "$CONTENTS_DIR/"
cp "Sources/Resources/default_config.json" "$RESOURCES_DIR/"

# 检查是否存在图标文件并复制
if [ -f "Sources/Resources/AppIcon.icns" ]; then
    cp "Sources/Resources/AppIcon.icns" "$RESOURCES_DIR/"
fi

# 设置执行权限
chmod +x "$MACOS_DIR/GamepadSwift"

# 创建临时DMG
echo "创建DMG..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$BUILD_DIR" -ov -format UDRW -size $SIZE "$TEMP_DMG"

# 挂载DMG
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | awk 'NR==1{print $1}')
VOLUME="/Volumes/$VOLUME_NAME"
sleep 2

# 创建 Applications 链接
echo "创建 Applications 链接..."
ln -s /Applications "$VOLUME/Applications"

# 设置DMG窗口的位置和大小
echo "设置DMG窗口属性..."
osascript << EOT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 100, 900, 400}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 72
        
        # 设置图标位置
        set position of item "$APP_NAME" of container window to {140, 150}
        set position of item "Applications" of container window to {360, 150}
        
        update without registering applications
        delay 2
        close
    end tell
end tell
EOT

# 设置DMG权限
chmod -Rf go-w "$VOLUME"

# 等待Finder完成操作
sync
sync

# 卸载DMG
echo "完成DMG配置..."
hdiutil detach "$DEVICE"

# 转换为压缩格式
echo "生成最终DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_NAME"

# 清理临时文件
rm -f "$TEMP_DMG"

echo "打包完成！DMG文件已生成：$DMG_NAME"