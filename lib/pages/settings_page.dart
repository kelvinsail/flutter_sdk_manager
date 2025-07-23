import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/sdk_providers.dart';
import '../services/config_service.dart';
import '../widgets/setting_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final configNotifier = ref.read(configProvider.notifier);
    final appInfoAsync = ref.watch(appInfoProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SDK路径设置
          SettingCard(
            title: 'SDK 存储路径',
            subtitle: '设置Flutter SDK的存储位置',
            icon: Icons.folder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          config['sdkRootPath'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.getDirectoryPath();
                    if (result != null) {
                      configNotifier.updateSdkRootPath(result);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SDK路径已更新'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('选择路径'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 镜像源设置
          SettingCard(
            title: '镜像源配置',
            subtitle: '设置Flutter SDK的下载镜像源',
            icon: Icons.cloud,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 镜像源选择
                RadioListTile<String>(
                  title: const Text('官方镜像 (flutter-io.cn)'),
                  subtitle: const Text('推荐使用，速度快且稳定'),
                  value: 'flutter-io',
                  groupValue: config['mirrorSource'],
                  onChanged: (value) {
                    if (value != null) {
                      configNotifier.updateMirrorSource(value);
                      configNotifier.updateUseCustomMirror(false);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('GitHub 官方源'),
                  subtitle: const Text('官方源，可能速度较慢'),
                  value: 'github',
                  groupValue: config['mirrorSource'],
                  onChanged: (value) {
                    if (value != null) {
                      configNotifier.updateMirrorSource(value);
                      configNotifier.updateUseCustomMirror(false);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('自定义镜像'),
                  subtitle: const Text('使用自定义的镜像地址'),
                  value: 'custom',
                  groupValue: config['mirrorSource'],
                  onChanged: (value) {
                    if (value != null) {
                      configNotifier.updateMirrorSource(value);
                      configNotifier.updateUseCustomMirror(true);
                    }
                  },
                ),
                
                // 自定义镜像地址输入
                if (config['mirrorSource'] == 'custom') ...[
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '自定义镜像地址',
                      hintText: '例如: https://your-mirror.com/flutter_infra_release/releases',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: config['customMirrorUrl'] ?? '',
                    ),
                    onChanged: (value) {
                      configNotifier.updateCustomMirrorUrl(value);
                    },
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 其他设置
          SettingCard(
            title: '其他设置',
            subtitle: '应用的其他配置选项',
            icon: Icons.settings,
            child: Column(
              children: [
                appInfoAsync.when(
                  data: (packageInfo) => ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('关于应用'),
                    subtitle: Text('Flutter SDK 管理器 v${packageInfo.version ?? '未知'}'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Flutter SDK 管理器',
                        applicationVersion: '${packageInfo.version ?? '未知'}+${packageInfo.buildNumber ?? '0'}',
                        applicationIcon: const Icon(Icons.flutter_dash),
                        children: [
                          const Text('一个用于管理Flutter SDK版本的工具'),
                          const SizedBox(height: 8),
                          const Text('支持多版本管理、快速切换和云端下载'),
                        ],
                      );
                    },
                  ),
                  loading: () => const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('关于应用'),
                    subtitle: Text('加载中...'),
                  ),
                  error: (error, stack) => ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('关于应用'),
                    subtitle: const Text('版本信息加载失败'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Flutter SDK 管理器',
                        applicationVersion: '未知版本',
                        applicationIcon: const Icon(Icons.flutter_dash),
                        children: [
                          const Text('一个用于管理Flutter SDK版本的工具'),
                          const SizedBox(height: 8),
                          const Text('支持多版本管理、快速切换和云端下载'),
                        ],
                      );
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('重置所有设置'),
                  subtitle: const Text('将所有设置恢复为默认值'),
                  onTap: () async {
                    final shouldReset = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('重置设置'),
                        content: const Text('确定要重置所有设置吗？此操作不可恢复。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('重置'),
                          ),
                        ],
                      ),
                    );
                    
                    if (shouldReset == true) {
                      await ConfigService.instance.clear();
                      await ConfigService.instance.init();
                      configNotifier.refresh();
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('设置已重置'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 系统信息
          SettingCard(
            title: '系统信息',
            subtitle: '当前系统的相关信息',
            icon: Icons.computer,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_system_daydream),
                  title: const Text('当前平台'),
                  subtitle: Text(ConfigService.instance.platformIdentifier),
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('当前镜像源'),
                  subtitle: Text(ConfigService.instance.platformReleaseUrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 