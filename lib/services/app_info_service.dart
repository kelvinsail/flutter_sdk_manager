import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  static final AppInfoService _instance = AppInfoService._internal();
  factory AppInfoService() => _instance;
  AppInfoService._internal();

  PackageInfo? _packageInfo;

  /// 获取应用信息
  Future<PackageInfo> get packageInfo async {
    if (_packageInfo == null) {
      _packageInfo = await PackageInfo.fromPlatform();
    }
    return _packageInfo!;
  }

  /// 获取应用名称
  Future<String> get appName async {
    final info = await packageInfo;
    return info.appName;
  }

  /// 获取应用版本号
  Future<String> get version async {
    final info = await packageInfo;
    return info.version;
  }

  /// 获取构建号
  Future<String> get buildNumber async {
    final info = await packageInfo;
    return info.buildNumber;
  }

  /// 获取包名
  Future<String> get packageName async {
    final info = await packageInfo;
    return info.packageName;
  }

  /// 获取完整版本信息
  Future<String> get fullVersion async {
    final info = await packageInfo;
    return '${info.version}+${info.buildNumber}';
  }
} 