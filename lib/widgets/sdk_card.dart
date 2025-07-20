import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/flutter_release.dart';

class SdkCard extends StatelessWidget {
  final FlutterRelease release;
  final bool isLocal;
  final VoidCallback? onSwitch;
  final VoidCallback? onRemove;
  final VoidCallback? onDownload;

  const SdkCard({
    super.key,
    required this.release,
    required this.isLocal,
    this.onSwitch,
    this.onRemove,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 版本信息头部
            Row(
              children: [
                // 版本号
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getChannelColor(release.channel).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getChannelColor(release.channel),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    release.version,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getChannelColor(release.channel),
                    ),
                  ),
                ),
                // 频道标签 - 只有当channel不是unknown时才显示
                if (release.channel.toLowerCase() != 'unknown') ...[
                  const SizedBox(width: 8),
                  _buildChannelChip(release.channel),
                ],
                const Spacer(),
                // 状态标识
                if (release.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '当前版本',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (release.isInstalled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_done,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '已安装',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 详细信息
            if (release.dartSdkVersion.isNotEmpty) ...[
              _buildInfoRow(
                Icons.code,
                'Dart SDK',
                release.dartSdkVersion,
              ),
              const SizedBox(height: 8),
            ],
            
            if (release.releaseDate.isNotEmpty) ...[
              _buildInfoRow(
                Icons.calendar_today,
                '发布日期',
                _formatDate(release.releaseDate),
              ),
              const SizedBox(height: 8),
            ],
            
            if (release.size > 0) ...[
              _buildInfoRow(
                Icons.storage,
                '大小',
                _formatSize(release.size),
              ),
              const SizedBox(height: 8),
            ],
            
            if (release.sha.isNotEmpty) ...[
              _buildInfoRow(
                Icons.fingerprint,
                'SHA',
                release.sha.substring(0, math.min(8, release.sha.length)),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              children: [
                if (isLocal) ...[
                  // 本地版本的操作按钮
                  if (onSwitch != null)
                    ElevatedButton.icon(
                      onPressed: onSwitch,
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('切换'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (onSwitch != null && onRemove != null)
                    const SizedBox(width: 8),
                  if (onRemove != null)
                    OutlinedButton.icon(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('删除'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ] else ...[
                  // 远程版本的操作按钮
                  if (onDownload != null)
                    ElevatedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download),
                      label: const Text('下载'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.download_done),
                      label: const Text('已安装'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelChip(String channel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getChannelColor(channel).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getChannelDisplayName(channel),
        style: TextStyle(
          color: _getChannelColor(channel),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
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

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
} 