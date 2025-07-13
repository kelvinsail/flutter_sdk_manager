import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:process/process.dart';
import '../models/flutter_release.dart';
import 'config_service.dart';

class SdkService {
  static SdkService? _instance;
  static SdkService get instance {
    _instance ??= SdkService._internal();
    return _instance!;
  }

  SdkService._internal();

  final ConfigService _config = ConfigService.instance;
  final ProcessManager _processManager = const LocalProcessManager();

  // 获取云端SDK版本列表
  Future<List<FlutterRelease>> getRemoteReleases() async {
    try {
      final response = await http.get(Uri.parse(_config.platformReleaseUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final releaseResponse = FlutterReleaseResponse.fromJson(data);
        
        // 将相对路径转换为完整的下载URL
        final baseUrl = releaseResponse.baseUrl;
        final updatedReleases = releaseResponse.releases.map((release) {
          String fullArchiveUrl = release.archive;
          if (!fullArchiveUrl.startsWith('http') && baseUrl.isNotEmpty) {
            fullArchiveUrl = '$baseUrl/${release.archive}';
          }
          
          return release.copyWith(archive: fullArchiveUrl);
        }).toList();
        
        return updatedReleases;
      } else {
        throw Exception('获取远程版本信息失败: ${response.statusCode}');
      }
    } catch (e) {
      // 云端版本获取失败
      throw Exception('获取远程版本信息失败: $e');
    }
  }

  // 获取本地已安装的SDK版本
  Future<List<FlutterRelease>> getLocalReleases() async {
    final List<FlutterRelease> localReleases = [];
    final sdkDir = Directory(_config.sdkRootPath);
    
    // 扫描SDK目录
    
    if (!sdkDir.existsSync()) {
      // SDK目录不存在，创建目录
      try {
        sdkDir.createSync(recursive: true);
      } catch (e) {
        // 创建目录失败，返回空列表
      }
      return localReleases;
    }

    final currentVersion = _config.currentSdkVersion;
    
    try {
      final entities = sdkDir.listSync();
      
      for (final entity in entities) {
        if (entity is Directory) {
          final versionPath = entity.path;
          final versionName = path.basename(versionPath);
          
          // 检查是否是有效的Flutter SDK目录
          final sdkInfo = await _analyzeSdkDirectory(versionPath);
          if (sdkInfo != null) {
            localReleases.add(FlutterRelease(
              version: sdkInfo['version'] ?? versionName,
              channel: sdkInfo['channel'] ?? 'unknown',
              sha: sdkInfo['sha'] ?? '',
              releaseDate: sdkInfo['releaseDate'] ?? '',
              dartSdkVersion: sdkInfo['dartSdkVersion'] ?? '',
              dartSdkArch: sdkInfo['dartSdkArch'] ?? '',
              archive: '',
              size: 0,
              sha256: '',
              isInstalled: true,
              isActive: versionName == currentVersion,
            ));
          }
        }
      }
    } catch (e) {
      // 扫描过程中出现错误，返回已找到的SDK列表
    }

    return localReleases;
  }

  // 分析SDK目录，获取详细信息
  Future<Map<String, String>?> _analyzeSdkDirectory(String sdkPath) async {
    // 首先检查基本目录结构
    if (!_isValidFlutterSdk(sdkPath)) {
      return null;
    }

    final result = <String, String>{};

    // 尝试从version文件读取版本信息
    try {
      final versionFile = File(path.join(sdkPath, 'version'));
      if (versionFile.existsSync()) {
        final versionContent = await versionFile.readAsString();
        result['version'] = versionContent.trim();
      }
    } catch (e) {
      // 忽略版本文件读取错误
    }

    // 尝试从bin/cache/dart-sdk读取Dart版本
    try {
      final dartVersionFile = File(path.join(sdkPath, 'bin', 'cache', 'dart-sdk', 'version'));
      if (dartVersionFile.existsSync()) {
        final dartVersion = await dartVersionFile.readAsString();
        result['dartSdkVersion'] = dartVersion.trim();
      }
    } catch (e) {
      // 忽略Dart版本文件读取错误
    }

    // 如果无法从文件获取版本信息，尝试执行命令
    if (result['version'] == null) {
      final cmdVersion = await _getFlutterVersionFromCommand(sdkPath);
      if (cmdVersion != null) {
        result['version'] = cmdVersion['version'] ?? '';
        result['channel'] = cmdVersion['channel'] ?? '';
        result['sha'] = cmdVersion['sha'] ?? '';
        result['dartSdkVersion'] = cmdVersion['dartSdkVersion'] ?? '';
      }
    }

    // 尝试从.git/logs/HEAD或其他位置获取更多信息
    try {
      final gitLogFile = File(path.join(sdkPath, '.git', 'logs', 'HEAD'));
      if (gitLogFile.existsSync()) {
        final gitLogs = await gitLogFile.readAsLines();
        if (gitLogs.isNotEmpty) {
          final lastCommit = gitLogs.last;
          if (lastCommit.contains(' ')) {
            final sha = lastCommit.split(' ')[1];
            if (sha.length >= 7) {
              result['sha'] = sha.substring(0, 7);
            }
          }
        }
      }
    } catch (e) {
      // 忽略git信息读取错误
    }

    // 设置默认值
    result['channel'] ??= 'unknown';
    result['version'] ??= path.basename(sdkPath);

    return result;
  }

  // 检查是否是有效的Flutter SDK目录
  bool _isValidFlutterSdk(String sdkPath) {
    // 检查关键文件和目录是否存在
    final flutterBin = Platform.isWindows 
        ? path.join(sdkPath, 'bin', 'flutter.bat')
        : path.join(sdkPath, 'bin', 'flutter');
    
    final binDir = Directory(path.join(sdkPath, 'bin'));
    final packagesDir = Directory(path.join(sdkPath, 'packages'));
    
    return File(flutterBin).existsSync() && 
           binDir.existsSync() && 
           packagesDir.existsSync();
  }

  // 通过命令行获取Flutter版本信息
  Future<Map<String, String>?> _getFlutterVersionFromCommand(String sdkPath) async {
    try {
      final flutterBin = Platform.isWindows 
          ? path.join(sdkPath, 'bin', 'flutter.bat')
          : path.join(sdkPath, 'bin', 'flutter');
      
      final result = await _processManager.run([
        flutterBin,
        '--version',
        '--machine',
      ]);
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final data = json.decode(output);
        return {
          'version': data['frameworkVersion'] ?? '',
          'channel': data['channel'] ?? '',
          'sha': data['frameworkRevision'] ?? '',
          'dartSdkVersion': data['dartSdkVersion'] ?? '',
        };
      }
    } catch (e) {
      // 如果命令执行失败，尝试简单的版本命令
      try {
        final flutterBin = Platform.isWindows 
            ? path.join(sdkPath, 'bin', 'flutter.bat')
            : path.join(sdkPath, 'bin', 'flutter');
        
        final result = await _processManager.run([
          flutterBin,
          '--version',
        ]);
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          // 解析简单的版本输出
          final lines = output.split('\n');
          for (final line in lines) {
            if (line.contains('Flutter') && line.contains('•')) {
              final parts = line.split('•');
              if (parts.length >= 2) {
                final versionPart = parts[1].trim();
                final channelMatch = RegExp(r'channel\s+(\w+)').firstMatch(line);
                return {
                  'version': versionPart.split(' ').first,
                  'channel': channelMatch?.group(1) ?? 'unknown',
                };
              }
            }
          }
        }
      } catch (e2) {
        // 所有方法都失败了
      }
    }
    return null;
  }

  // 下载并安装SDK
  Future<void> downloadAndInstallSdk(
    FlutterRelease release,
    Function(double progress) onProgress,
    Function(String message) onStatusUpdate,
  ) async {
    try {
      onStatusUpdate('开始下载 ${release.version}...');
      
      // 创建临时下载目录
      final tempPath = await _config.downloadTempPath;
      final tempDir = Directory(tempPath);
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }

      // 下载文件
      final downloadUrl = release.archive;
      final fileName = path.basename(downloadUrl);
      final filePath = path.join(tempPath, fileName);
      
      await _downloadFile(downloadUrl, filePath, onProgress);
      
      onStatusUpdate('下载完成，开始解压...');
      
      // 解压文件
      await _extractArchive(filePath, tempPath, onStatusUpdate);
      
      onStatusUpdate('解压完成，开始安装...');
      
      // 移动到SDK目录
      final sdkRootDir = Directory(_config.sdkRootPath);
      if (!sdkRootDir.existsSync()) {
        sdkRootDir.createSync(recursive: true);
      }
      
      final extractedSdkPath = path.join(tempPath, 'flutter');
      final targetSdkPath = path.join(_config.sdkRootPath, release.version);
      
      // 移动文件夹
      final extractedDir = Directory(extractedSdkPath);
      if (extractedDir.existsSync()) {
        await extractedDir.rename(targetSdkPath);
      }
      
      // 清理临时文件
      if (File(filePath).existsSync()) {
        File(filePath).deleteSync();
      }
      
      onStatusUpdate('安装完成！');
      
    } catch (e) {
      throw Exception('下载安装失败: $e');
    }
  }

  // 下载文件
  Future<void> _downloadFile(
    String url,
    String filePath,
    Function(double progress) onProgress,
  ) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();
    
    if (response.statusCode != 200) {
      throw Exception('下载失败，状态码: ${response.statusCode}');
    }
    
    final file = File(filePath);
    final sink = file.openWrite();
    
    int downloaded = 0;
    final contentLength = response.contentLength ?? 0;
    
    await response.stream.listen(
      (chunk) {
        downloaded += chunk.length;
        sink.add(chunk);
        
        if (contentLength > 0) {
          final progress = downloaded / contentLength;
          onProgress(progress);
        }
      },
      onDone: () {
        sink.close();
      },
      onError: (error) {
        sink.close();
        throw Exception('下载过程中发生错误: $error');
      },
    ).asFuture();
  }

  // 解压文件
  Future<void> _extractArchive(
    String archivePath,
    String extractPath,
    Function(String message) onStatusUpdate,
  ) async {
    final file = File(archivePath);
    final bytes = file.readAsBytesSync();
    
    Archive archive;
    if (archivePath.endsWith('.zip')) {
      archive = ZipDecoder().decodeBytes(bytes);
    } else if (archivePath.endsWith('.tar.xz')) {
      archive = TarDecoder().decodeBytes(XZDecoder().decodeBytes(bytes));
    } else {
      throw Exception('不支持的压缩格式');
    }
    
    for (final file in archive) {
      final filename = file.name;
      onStatusUpdate('解压: $filename');
      
      if (file.isFile) {
        final data = file.content as List<int>;
        final outputFile = File(path.join(extractPath, filename));
        outputFile.parent.createSync(recursive: true);
        outputFile.writeAsBytesSync(data);
      } else {
        Directory(path.join(extractPath, filename)).createSync(recursive: true);
      }
    }
  }

  // 切换SDK版本
  Future<Map<String, dynamic>> switchSdkVersion(String version) async {
    final sdkPath = path.join(_config.sdkRootPath, version);
    
    if (!Directory(sdkPath).existsSync()) {
      throw Exception('SDK版本 $version 不存在');
    }
    
    if (!_isValidFlutterSdk(sdkPath)) {
      throw Exception('无效的Flutter SDK目录');
    }
    
    _config.currentSdkVersion = version;
    
    // 尝试多种切换方案
    final result = await _updateSystemPath(sdkPath, version);
    
    return {
      'version': version,
      'sdkPath': sdkPath,
      'sdkRootPath': _config.sdkRootPath,
      'symbolicLinkCreated': result['symbolicLinkCreated'] ?? false,
      'errorMessage': result['errorMessage'],
    };
  }

  // 更新系统PATH的多种方案
  Future<Map<String, dynamic>> _updateSystemPath(String sdkPath, String version) async {
    final binPath = path.join(sdkPath, 'bin');
    bool symbolicLinkCreated = false;
    String? errorMessage;
    
    try {
      // 方案1：创建符号链接（推荐）
      await _createSymbolicLink(sdkPath, version);
      symbolicLinkCreated = true;
    } catch (e) {
      // 符号链接失败，尝试其他方案
      errorMessage = e.toString();
      print('符号链接创建失败: $e');
    }
    
    // 方案2：生成切换脚本
    await _generateSwitchScripts(binPath, version);
    
    // 方案3：提供用户手动配置的说明
    await _showPathUpdateInstructions(binPath, version);
    
    return {
      'symbolicLinkCreated': symbolicLinkCreated,
      'errorMessage': errorMessage,
    };
  }
  
  // 方案1：创建符号链接
  Future<void> _createSymbolicLink(String sdkPath, String version) async {
    final linkPath = path.join(_config.sdkRootPath, 'current');
    final linkDir = Directory(linkPath);
    
    try {
      // 删除已存在的符号链接
      if (linkDir.existsSync()) {
        await linkDir.delete();
      }
      
      // 创建新的符号链接
      if (Platform.isWindows) {
        // Windows使用junction创建目录链接
        final result = await _processManager.run([
          'cmd',
          '/c',
          'mklink',
          '/J',
          linkPath,
          sdkPath,
        ]);
        
        if (result.exitCode != 0) {
          throw Exception('创建符号链接失败: ${result.stderr}');
        }
      } else {
        // Unix系统使用ln创建符号链接
        final result = await _processManager.run([
          'ln',
          '-sfn',
          sdkPath,
          linkPath,
        ]);
        
        if (result.exitCode != 0) {
          throw Exception('创建符号链接失败: ${result.stderr}');
        }
      }
      
      print('符号链接创建成功: $linkPath -> $sdkPath');
      print('请将 ${path.join(linkPath, 'bin')} 添加到PATH环境变量中');
      
    } catch (e) {
      throw Exception('创建符号链接失败: $e');
    }
  }
  
  // 方案2：生成切换脚本
  Future<void> _generateSwitchScripts(String binPath, String version) async {
    final scriptsDir = Directory(path.join(_config.sdkRootPath, 'scripts'));
    if (!scriptsDir.existsSync()) {
      scriptsDir.createSync(recursive: true);
    }
    
    if (Platform.isWindows) {
      // 生成Windows批处理脚本
      final batchContent = '''
@echo off
echo 正在切换到 Flutter SDK $version...
set "FLUTTER_ROOT=$binPath"
set "PATH=%FLUTTER_ROOT%;%PATH%"
echo Flutter SDK 已切换到版本 $version
echo 当前PATH: %FLUTTER_ROOT%
flutter --version
''';
      
      final batchFile = File(path.join(scriptsDir.path, 'switch_to_$version.bat'));
      await batchFile.writeAsString(batchContent);
      
      // 生成通用切换脚本
      final generalBatchContent = '''
@echo off
echo 正在切换到 Flutter SDK $version...
set "FLUTTER_ROOT=$binPath"
set "PATH=%FLUTTER_ROOT%;%PATH%"
echo Flutter SDK 已切换到版本 $version
cmd /k
''';
      
      final generalBatchFile = File(path.join(scriptsDir.path, 'switch_flutter.bat'));
      await generalBatchFile.writeAsString(generalBatchContent);
      
    } else {
      // 生成Unix shell脚本
      final shellContent = '''#!/bin/bash
echo "正在切换到 Flutter SDK $version..."
export FLUTTER_ROOT="$binPath"
export PATH="\$FLUTTER_ROOT:\$PATH"
echo "Flutter SDK 已切换到版本 $version"
echo "当前PATH: \$FLUTTER_ROOT"
flutter --version
''';
      
      final shellFile = File(path.join(scriptsDir.path, 'switch_to_$version.sh'));
      await shellFile.writeAsString(shellContent);
      
      // 设置执行权限
      await _processManager.run(['chmod', '+x', shellFile.path]);
    }
    
    print('切换脚本已生成在: ${scriptsDir.path}');
  }
  
  // 方案3：显示PATH更新说明
  Future<void> _showPathUpdateInstructions(String binPath, String version) async {
    final instructionsDir = Directory(path.join(_config.sdkRootPath, 'instructions'));
    if (!instructionsDir.existsSync()) {
      instructionsDir.createSync(recursive: true);
    }
    
    String instructions = '';
    
    if (Platform.isWindows) {
      instructions = '''
Flutter SDK 版本切换说明 - Windows

已切换到版本: $version
SDK路径: $binPath

请按以下步骤更新PATH环境变量：

方法1：使用系统设置
1. 右键"此电脑" → "属性"
2. 点击"高级系统设置"
3. 点击"环境变量"
4. 在"系统变量"中找到"Path"，点击"编辑"
5. 添加: $binPath
6. 点击"确定"保存

方法2：使用命令行（临时）
打开命令提示符，运行：
set PATH=$binPath;%PATH%

方法3：使用生成的脚本
运行脚本: scripts/switch_to_$version.bat

方法4：使用符号链接（推荐）
1. 将 ${path.join(_config.sdkRootPath, 'current', 'bin')} 添加到PATH
2. 每次切换版本时，符号链接会自动更新

验证安装：
flutter --version
''';
    } else {
      instructions = '''
Flutter SDK 版本切换说明 - Unix/Linux

已切换到版本: $version
SDK路径: $binPath

请按以下步骤更新PATH环境变量：

方法1：临时设置（当前会话）
export PATH="$binPath:\$PATH"

方法2：永久设置
编辑 ~/.bashrc 或 ~/.zshrc 文件，添加：
export PATH="$binPath:\$PATH"

然后运行：
source ~/.bashrc  # 或 source ~/.zshrc

方法3：使用生成的脚本
运行脚本: ./scripts/switch_to_$version.sh

方法4：使用符号链接（推荐）
1. 将 ${path.join(_config.sdkRootPath, 'current', 'bin')} 添加到PATH
2. 每次切换版本时，符号链接会自动更新

验证安装：
flutter --version
''';
    }
    
    final instructionsFile = File(path.join(instructionsDir.path, 'switch_instructions.txt'));
    await instructionsFile.writeAsString(instructions);
    
    print('PATH更新说明已保存到: ${instructionsFile.path}');
  }
  
  // 获取当前系统中实际使用的Flutter版本
  Future<String?> getCurrentSystemFlutterVersion() async {
    try {
      final result = await _processManager.run([
        'flutter',
        '--version',
        '--machine',
      ]);
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final data = json.decode(output);
        return data['flutterVersion'];
      }
    } catch (e) {
      // 获取失败，可能Flutter不在PATH中
    }
    return null;
  }
  
  // 检查当前配置的版本是否与系统中实际使用的版本一致
  Future<bool> isVersionSyncWithSystem() async {
    final configVersion = _config.currentSdkVersion;
    final systemVersion = await getCurrentSystemFlutterVersion();
    
    if (configVersion.isEmpty || systemVersion == null) {
      return false;
    }
    
    return configVersion == systemVersion;
  }

  // 删除SDK版本
  Future<void> removeSdkVersion(String version) async {
    final sdkPath = path.join(_config.sdkRootPath, version);
    final sdkDir = Directory(sdkPath);
    
    if (!sdkDir.existsSync()) {
      throw Exception('SDK版本 $version 不存在');
    }
    
    if (_config.currentSdkVersion == version) {
      throw Exception('无法删除当前激活的SDK版本');
    }
    
    sdkDir.deleteSync(recursive: true);
  }

  // 获取当前激活的SDK信息
  Future<FlutterRelease?> getCurrentSdk() async {
    final currentVersion = _config.currentSdkVersion;
    if (currentVersion.isEmpty) {
      return null;
    }
    
    final localReleases = await getLocalReleases();
    return localReleases.firstWhere(
      (release) => release.version == currentVersion,
      orElse: () => localReleases.first,
    );
  }
} 