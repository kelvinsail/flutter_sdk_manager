#!/bin/bash

cd ../
flutter clean
flutter pub get
flutter build macos -v
# 重命名
mv ./build/macos/Build/Products/Release/fluttervermanager.app ./build/macos/Build/Products/Release/FVM.app

# 1.zip flutter build macos
# 2.授予权限 chmod +x create_dmg.sh

# 定义源目录
SOURCE_DIR="./build/macos/Build/Products/Release/"
OUT_DIR="./"

# 查找第一个 .app 文件
SOURCE_APP_PATH=$(find "$SOURCE_DIR" -maxdepth 1 -type d -name "*.app" | head -n 1)

# 检查是否找到了 .app 文件
if [ -z "$SOURCE_APP_PATH" ]; then
  echo "No .app file found in $SOURCE_DIR"
  exit 1
fi

# 设置输出 DMG 路径
OUTPUT_DMG_PATH="$OUT_DIR"$(basename "$SOURCE_APP_PATH" .app).dmg

# 创建 DMG 文件
echo "Creating DMG from $SOURCE_APP_PATH to $OUTPUT_DMG_PATH..."

# hdiutil打包详细参数如下
# `-volname`: 安装时挂载的名字（一般和 app 一样）
#`-srcfolder`: 你的 `.app` 路径
#`-format UDZO`: 压缩格式（推荐使用）
# `-ov`: 允许覆盖已有文件
# 输出路径是 `.dmg` 文件最终保存的位置
hdiutil create -volname "$(basename "$SOURCE_APP_PATH")" \
  -srcfolder "$SOURCE_APP_PATH" \
  -ov -format UDZO "$OUTPUT_DMG_PATH"

echo "DMG created successfully at $OUTPUT_DMG_PATH"