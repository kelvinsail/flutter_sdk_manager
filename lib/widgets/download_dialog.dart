import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/flutter_release.dart';
import '../providers/sdk_providers.dart';

class DownloadDialog extends ConsumerStatefulWidget {
  final FlutterRelease release;

  const DownloadDialog({
    super.key,
    required this.release,
  });

  @override
  ConsumerState<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends ConsumerState<DownloadDialog> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadProvider);

    return AlertDialog(
      title: Text('下载 ${widget.release.version}'),
      content: _isDownloading
          ? _buildDownloadingContent(downloadState)
          : _buildConfirmContent(),
      actions: _isDownloading
          ? [
              TextButton(
                onPressed: () {
                  ref.read(downloadProvider.notifier).reset();
                  Navigator.of(context).pop(false);
                },
                child: const Text('取消'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  setState(() {
                    _isDownloading = true;
                  });
                  
                  try {
                    await ref.read(downloadProvider.notifier).downloadSdk(widget.release);
                    if (mounted) {
                      navigator.pop(true);
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isDownloading = false;
                      });
                    }
                  }
                },
                child: const Text('下载'),
              ),
            ],
    );
  }

  Widget _buildConfirmContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('确定要下载 Flutter SDK ${widget.release.version} 吗？'),
        const SizedBox(height: 16),
        _buildInfoRow('版本', widget.release.version),
        _buildInfoRow('频道', widget.release.channel),
        if (widget.release.dartSdkVersion.isNotEmpty)
          _buildInfoRow('Dart SDK', widget.release.dartSdkVersion),
        if (widget.release.size > 0)
          _buildInfoRow('大小', _formatSize(widget.release.size)),
        if (widget.release.releaseDate.isNotEmpty)
          _buildInfoRow('发布日期', _formatDate(widget.release.releaseDate)),
      ],
    );
  }

  Widget _buildDownloadingContent(DownloadState downloadState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpinKitWave(
          color: Theme.of(context).colorScheme.primary,
          size: 30.0,
        ),
        const SizedBox(height: 16),
        Text(
          downloadState.statusMessage,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: downloadState.progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(downloadState.progress * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (downloadState.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    downloadState.error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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