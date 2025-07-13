import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sdk_providers.dart';
import '../widgets/sdk_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_dialog.dart';
import '../widgets/switch_result_dialog.dart';

class LocalSdkPage extends ConsumerWidget {
  const LocalSdkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localSdkAsync = ref.watch(localSdkProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(localSdkProvider);
          ref.invalidate(currentSdkProvider);
        },
        child: localSdkAsync.when(
          data: (releases) {
            if (releases.isEmpty) {
              return const EmptyState(
                icon: Icons.folder_open,
                title: '暂无已安装的SDK',
                subtitle: '您可以在云端版本页面下载Flutter SDK',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: releases.length,
              itemBuilder: (context, index) {
                final release = releases[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                                // 显示切换结果对话框
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
                                await ref
                                    .read(sdkManagerProvider.notifier)
                                    .removeSdk(release.version);
                                ref.invalidate(localSdkProvider);
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('已删除 ${release.version}'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              } catch (e) {
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.invalidate(localSdkProvider);
          ref.invalidate(currentSdkProvider);
        },
        icon: const Icon(Icons.refresh),
        label: const Text('刷新'),
      ),
    );
  }
}

class LocalSdkHeader extends ConsumerWidget {
  const LocalSdkHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSdkAsync = ref.watch(currentSdkProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.flutter_dash,
            size: 32,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前激活版本',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                currentSdkAsync.when(
                  data: (currentSdk) {
                    if (currentSdk == null) {
                      return const Text(
                        '无激活版本',
                        style: TextStyle(color: Colors.grey),
                      );
                    }
                    return Text(
                      '${currentSdk.version} (${currentSdk.channel})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                  loading: () => const Text('加载中...'),
                  error: (_, __) => const Text(
                    '加载失败',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 