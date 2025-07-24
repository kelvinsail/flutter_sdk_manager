import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flutter_release.dart';
import '../providers/sdk_providers.dart';
import '../widgets/sdk_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_dialog.dart';
import '../widgets/switch_result_dialog.dart';
import '../widgets/loading_dialog.dart';

class LocalSdkPage extends ConsumerWidget {
  const LocalSdkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localSdkAsync = ref.watch(localSdkProvider);
    final currentSdkAsync = ref.watch(currentSdkProvider);

    return Column(
      children: [
        // 当前版本信息卡片
        Container(
          margin: const EdgeInsets.all(16),
          child: _CurrentSdkCard(currentSdkAsync: currentSdkAsync),
        ),
        // SDK列表
        Expanded(
          child: localSdkAsync.when(
            data: (releases) {
              if (releases.isEmpty) {
                return const Center(
                  child: EmptyState(
                    icon: Icons.folder_open,
                    title: '暂无已安装的SDK',
                    subtitle: '您可以在云端版本页面下载Flutter SDK',
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: releases.length,
                itemBuilder: (context, index) {
                  final release = releases[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: SdkCard(
                      release: release,
                      isLocal: true,
                      onSwitch: release.isActive
                          ? null
                          : () async {
                              try {
                                final result = await ref
                                    .read(sdkManagerProvider.notifier)
                                    .switchSdk(release.version);
                                
                                ref.invalidate(localSdkProvider);
                                ref.invalidate(currentSdkProvider);
                                
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => SwitchResultDialog(
                                      version: result['version'],
                                      sdkPath: result['sdkPath'],
                                      sdkRootPath: result['sdkRootPath'],
                                      symbolicLinkCreated: result['symbolicLinkCreated'],
                                      errorMessage: result['errorMessage'],
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ErrorDialog.show(context, '切换失败', e.toString());
                                }
                              }
                            },
                      onRemove: release.isActive
                          ? null
                          : () async {
                              final shouldRemove = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('确认删除'),
                                  content: Text('确定要删除 ${release.version} 吗？此操作不可恢复。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('删除'),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldRemove == true) {
                                try {
                                  // 显示加载状态
                                  if (context.mounted) {
                                    LoadingDialog.show(context, '正在删除 ${release.version}...');
                                  }
                                  
                                  // 执行删除操作
                                  await ref
                                      .read(sdkManagerProvider.notifier)
                                      .removeSdk(release.version);
                                  
                                  // 关闭加载对话框
                                  if (context.mounted) {
                                    LoadingDialog.hide(context);
                                  }
                                  
                                  // 刷新相关状态
                                  ref.invalidate(localSdkProvider);
                                  ref.invalidate(currentSdkProvider);
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('已删除 ${release.version}'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // 关闭加载对话框
                                  if (context.mounted) {
                                    LoadingDialog.hide(context);
                                  }
                                  
                                  if (context.mounted) {
                                    ErrorDialog.show(context, '删除失败', e.toString());
                                  }
                                }
                              }
                            },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '加载失败',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(localSdkProvider);
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrentSdkCard extends StatelessWidget {
  final AsyncValue<FlutterRelease?> currentSdkAsync;

  const _CurrentSdkCard({required this.currentSdkAsync});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flutter_dash,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前激活版本',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  currentSdkAsync.when(
                    data: (currentSdk) {
                      if (currentSdk == null) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '无激活版本',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              currentSdk.version,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (currentSdk.channel.toLowerCase() != 'unknown') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getChannelColor(currentSdk.channel).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getChannelDisplayName(currentSdk.channel),
                                style: TextStyle(
                                  color: _getChannelColor(currentSdk.channel),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '加载中...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    error: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '加载失败',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChannelColor(String channel) {
    switch (channel.toLowerCase()) {
      case 'stable':
        return Colors.green;
      case 'beta':
        return Colors.orange;
      case 'dev':
        return Colors.red;
      case 'master':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getChannelDisplayName(String channel) {
    switch (channel.toLowerCase()) {
      case 'stable':
        return '稳定版';
      case 'beta':
        return '测试版';
      case 'dev':
        return '开发版';
      case 'master':
        return '主分支';
      default:
        return channel;
    }
  }
} 