import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sdk_providers.dart';
import '../widgets/sdk_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_dialog.dart';
import '../widgets/download_dialog.dart';

class RemoteSdkPage extends ConsumerWidget {
  const RemoteSdkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredRemoteSdkAsync = ref.watch(filteredRemoteSdkProvider);
    final channelFilter = ref.watch(channelFilterProvider);
    final localSdkAsync = ref.watch(localSdkProvider);

    return Scaffold(
      body: Column(
        children: [
          // 搜索和过滤器
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 搜索框
                TextField(
                  decoration: const InputDecoration(
                    hintText: '搜索版本...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    ref.read(searchFilterProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 12),
                // 频道过滤器
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChannelChip(context, ref, '全部', 'all', channelFilter),
                      const SizedBox(width: 8),
                      _buildChannelChip(context, ref, '稳定版', 'stable', channelFilter),
                      const SizedBox(width: 8),
                      _buildChannelChip(context, ref, '测试版', 'beta', channelFilter),
                      const SizedBox(width: 8),
                      _buildChannelChip(context, ref, '开发版', 'dev', channelFilter),
                      const SizedBox(width: 8),
                      _buildChannelChip(context, ref, '主分支', 'master', channelFilter),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 版本列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(remoteSdkProvider);
                ref.invalidate(localSdkProvider);
              },
              child: filteredRemoteSdkAsync.when(
                data: (releases) {
                  if (releases.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off,
                      title: '没有找到匹配的版本',
                      subtitle: '请尝试调整搜索条件或过滤器',
                    );
                  }

                  return localSdkAsync.when(
                    data: (localReleases) {
                      final localVersions = localReleases.map((r) => r.version).toSet();
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: releases.length,
                        itemBuilder: (context, index) {
                          final release = releases[index];
                          final isInstalled = localVersions.contains(release.version);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SdkCard(
                              release: release.copyWith(isInstalled: isInstalled),
                              isLocal: false,
                              onDownload: isInstalled 
                                  ? null 
                                  : () async {
                                      final shouldDownload = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => DownloadDialog(release: release),
                                      );
                                      
                                      if (shouldDownload == true) {
                                        try {
                                          await ref
                                              .read(downloadProvider.notifier)
                                              .downloadSdk(release);
                                          ref.invalidate(localSdkProvider);
                                          
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${release.version} 下载完成'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ErrorDialog.show(context, '下载失败', e.toString());
                                          }
                                        }
                                      }
                                    },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('加载本地版本失败', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(error.toString(), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(localSdkProvider),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('加载失败', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(remoteSdkProvider),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
    String currentValue,
  ) {
    final isSelected = currentValue == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(channelFilterProvider.notifier).state = value;
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
} 