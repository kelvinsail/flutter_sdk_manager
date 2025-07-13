import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance {
    _instance ??= ConfigService._internal();
    return _instance!;
  }

  ConfigService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // SDK根目录路径
  String get sdkRootPath {
    return _prefs?.getString('sdk_root_path') ?? _defaultSdkPath;
  }

  set sdkRootPath(String path) {
    _prefs?.setString('sdk_root_path', path);
  }

  // 当前激活的SDK版本
  String get currentSdkVersion {
    return _prefs?.getString('current_sdk_version') ?? '';
  }

  set currentSdkVersion(String version) {
    _prefs?.setString('current_sdk_version', version);
  }

  // 镜像源配置
  String get mirrorSource {
    return _prefs?.getString('mirror_source') ?? 'flutter-io';
  }

  set mirrorSource(String source) {
    _prefs?.setString('mirror_source', source);
  }

  // 自定义镜像地址
  String get customMirrorUrl {
    return _prefs?.getString('custom_mirror_url') ?? '';
  }

  set customMirrorUrl(String url) {
    _prefs?.setString('custom_mirror_url', url);
  }

  // 是否使用自定义镜像
  bool get useCustomMirror {
    return _prefs?.getBool('use_custom_mirror') ?? false;
  }

  set useCustomMirror(bool use) {
    _prefs?.setBool('use_custom_mirror', use);
  }

  // 默认SDK路径
  String get _defaultSdkPath {
    if (Platform.isWindows) {
      return path.join(Platform.environment['USERPROFILE'] ?? '', 'flutter_sdks');
    } else if (Platform.isMacOS) {
      return path.join(Platform.environment['HOME'] ?? '', 'flutter_sdks');
    } else {
      return path.join(Platform.environment['HOME'] ?? '', 'flutter_sdks');
    }
  }

  // 获取当前平台的发布信息URL
  String get platformReleaseUrl {
    final baseUrl = useCustomMirror && customMirrorUrl.isNotEmpty
        ? customMirrorUrl
        : 'https://storage.flutter-io.cn/flutter_infra_release/releases';
    
    if (Platform.isWindows) {
      return '$baseUrl/releases_windows.json';
    } else if (Platform.isMacOS) {
      return '$baseUrl/releases_macos.json';
    } else {
      return '$baseUrl/releases_linux.json';
    }
  }

  // 获取平台标识
  String get platformIdentifier {
    if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else {
      return 'linux';
    }
  }

  // 获取临时下载目录
  Future<String> get downloadTempPath async {
    final tempDir = await getTemporaryDirectory();
    return path.join(tempDir.path, 'flutter_downloads');
  }

  // 清空配置
  Future<void> clear() async {
    await _prefs?.clear();
  }
} 