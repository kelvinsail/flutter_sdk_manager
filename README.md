# Flutter SDK 管理器

一个用于管理本地Flutter SDK版本的桌面应用程序，支持多版本管理、快速切换和云端下载。

## 功能特性

### 📦 本地SDK管理
- 扫描和显示本地已安装的Flutter SDK版本
- 一键切换当前激活的SDK版本
- 删除不需要的SDK版本
- 显示当前激活版本的详细信息

### ☁️ 云端版本下载
- 获取官方Flutter SDK版本列表
- 支持按频道筛选（稳定版、测试版、开发版、主分支）
- 支持版本搜索功能
- 一键下载并安装指定版本

### ⚙️ 灵活配置
- 自定义SDK存储路径
- 支持多种镜像源：
  - 官方中国镜像 (flutter-io.cn) - 推荐
  - GitHub官方源
  - 自定义镜像地址
- 持久化保存用户设置

### 🖥️ 跨平台支持
- Windows
- macOS
- Linux

## 安装和使用

### 环境要求
- Flutter SDK >= 3.6.2
- Dart SDK >= 3.6.2

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/your-username/FlutterVerManager.git
cd FlutterVerManager
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行应用**
```bash
flutter run
```

### 构建发布版本

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## 项目结构

```
lib/
├── main.dart                   # 应用入口
├── models/                     # 数据模型
│   └── flutter_release.dart    # SDK版本信息模型
├── services/                   # 服务层
│   ├── config_service.dart     # 配置管理服务
│   └── sdk_service.dart        # SDK管理服务
├── providers/                  # 状态管理
│   └── sdk_providers.dart      # Riverpod状态提供者
├── pages/                      # 页面
│   ├── main_page.dart          # 主页面
│   ├── local_sdk_page.dart     # 本地SDK页面
│   ├── remote_sdk_page.dart    # 远程SDK页面
│   └── settings_page.dart      # 设置页面
└── widgets/                    # 通用组件
    ├── sdk_card.dart           # SDK版本卡片
    ├── empty_state.dart        # 空状态组件
    ├── error_dialog.dart       # 错误对话框
    ├── setting_card.dart       # 设置卡片
    └── download_dialog.dart    # 下载对话框
```

## 技术栈

- **Flutter** - 跨平台UI框架
- **Riverpod** - 状态管理
- **SharedPreferences** - 本地数据存储
- **HTTP** - 网络请求
- **Archive** - 文件解压缩
- **FilePicker** - 文件选择器
- **PathProvider** - 路径获取

## 主要功能说明

### 1. 本地SDK管理
- 自动扫描指定目录下的Flutter SDK版本
- 验证SDK完整性
- 获取SDK版本和频道信息
- 支持版本切换（需要手动更新PATH环境变量）

### 2. 云端版本获取
- 从官方API获取最新版本信息
- 支持不同平台的版本列表
- 实时显示版本状态（已安装/未安装）

### 3. 下载和安装
- 支持从多个镜像源下载
- 实时显示下载进度
- 自动解压缩到指定目录
- 错误处理和重试机制

### 4. 配置管理
- 持久化保存用户设置
- 支持重置所有设置
- 系统信息显示

## 使用说明

### 首次使用
1. 启动应用后，先进入"设置"页面
2. 配置SDK存储路径（可选，默认为用户目录下的flutter_sdks文件夹）
3. 选择合适的镜像源（推荐使用flutter-io.cn）

### 下载SDK
1. 切换到"云端版本"页面
2. 使用搜索框或频道筛选找到需要的版本
3. 点击"下载"按钮开始下载
4. 下载完成后会自动出现在"本地版本"页面

### 切换SDK版本
1. 在"本地版本"页面查看已安装的SDK
2. 点击非当前版本的"切换"按钮
3. 手动更新系统PATH环境变量（指向新版本的bin目录）

### 管理SDK版本
- 删除不需要的版本（当前激活版本不能删除）
- 查看版本详细信息
- 刷新本地版本列表

## 注意事项

1. **环境变量更新**: 应用无法自动更新系统PATH环境变量，需要用户手动配置
2. **权限要求**: 可能需要管理员权限来访问某些系统目录
3. **网络连接**: 下载功能需要稳定的网络连接
4. **存储空间**: 确保有足够的磁盘空间存储多个SDK版本

## 贡献指南

欢迎提交Issue和Pull Request来改进这个项目！

## 许可证

本项目采用MIT许可证，详见LICENSE文件。

## 更新日志

### v1.0.0
- 初始版本发布
- 支持本地SDK管理
- 支持云端版本下载
- 支持配置管理
- 跨平台支持
