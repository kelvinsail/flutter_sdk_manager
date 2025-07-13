import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flutter_release.dart';
import '../services/sdk_service.dart';
import '../services/config_service.dart';

// 配置服务提供者
final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService.instance;
});

// SDK服务提供者
final sdkServiceProvider = Provider<SdkService>((ref) {
  return SdkService.instance;
});

// 本地SDK版本列表提供者
final localSdkProvider = FutureProvider.autoDispose<List<FlutterRelease>>((ref) async {
  final sdkService = ref.watch(sdkServiceProvider);
  return await sdkService.getLocalReleases();
});

// 远程SDK版本列表提供者
final remoteSdkProvider = FutureProvider.autoDispose<List<FlutterRelease>>((ref) async {
  final sdkService = ref.watch(sdkServiceProvider);
  return await sdkService.getRemoteReleases();
});

// 当前激活的SDK提供者
final currentSdkProvider = FutureProvider.autoDispose<FlutterRelease?>((ref) async {
  final sdkService = ref.watch(sdkServiceProvider);
  return await sdkService.getCurrentSdk();
});

// 下载状态管理器
class DownloadState {
  final bool isDownloading;
  final double progress;
  final String statusMessage;
  final String? currentVersion;
  final String? error;

  DownloadState({
    this.isDownloading = false,
    this.progress = 0.0,
    this.statusMessage = '',
    this.currentVersion,
    this.error,
  });

  DownloadState copyWith({
    bool? isDownloading,
    double? progress,
    String? statusMessage,
    String? currentVersion,
    String? error,
  }) {
    return DownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      currentVersion: currentVersion ?? this.currentVersion,
      error: error ?? this.error,
    );
  }
}

// 下载状态管理器
class DownloadNotifier extends StateNotifier<DownloadState> {
  DownloadNotifier() : super(DownloadState());

  final SdkService _sdkService = SdkService.instance;

  Future<void> downloadSdk(FlutterRelease release) async {
    state = state.copyWith(
      isDownloading: true,
      progress: 0.0,
      statusMessage: '准备下载...',
      currentVersion: release.version,
      error: null,
    );

    try {
      await _sdkService.downloadAndInstallSdk(
        release,
        (progress) {
          state = state.copyWith(progress: progress);
        },
        (message) {
          state = state.copyWith(statusMessage: message);
        },
      );

      state = state.copyWith(
        isDownloading: false,
        progress: 1.0,
        statusMessage: '下载完成！',
      );
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error: e.toString(),
        statusMessage: '下载失败',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = DownloadState();
  }
}

// 下载状态提供者
final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  return DownloadNotifier();
});

// SDK管理器
class SdkNotifier extends StateNotifier<AsyncValue<void>> {
  SdkNotifier() : super(const AsyncValue.data(null));

  final SdkService _sdkService = SdkService.instance;

  Future<Map<String, dynamic>> switchSdk(String version) async {
    state = const AsyncValue.loading();
    try {
      final result = await _sdkService.switchSdkVersion(version);
      state = const AsyncValue.data(null);
      return result;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> removeSdk(String version) async {
    state = const AsyncValue.loading();
    try {
      await _sdkService.removeSdkVersion(version);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// SDK管理提供者
final sdkManagerProvider = StateNotifierProvider<SdkNotifier, AsyncValue<void>>((ref) {
  return SdkNotifier();
});

// 配置状态管理器
class ConfigNotifier extends StateNotifier<Map<String, dynamic>> {
  ConfigNotifier() : super({}) {
    _loadConfig();
  }

  final ConfigService _configService = ConfigService.instance;

  void _loadConfig() {
    state = {
      'sdkRootPath': _configService.sdkRootPath,
      'mirrorSource': _configService.mirrorSource,
      'customMirrorUrl': _configService.customMirrorUrl,
      'useCustomMirror': _configService.useCustomMirror,
    };
  }

  void updateSdkRootPath(String path) {
    _configService.sdkRootPath = path;
    state = {...state, 'sdkRootPath': path};
  }

  void updateMirrorSource(String source) {
    _configService.mirrorSource = source;
    state = {...state, 'mirrorSource': source};
  }

  void updateCustomMirrorUrl(String url) {
    _configService.customMirrorUrl = url;
    state = {...state, 'customMirrorUrl': url};
  }

  void updateUseCustomMirror(bool use) {
    _configService.useCustomMirror = use;
    state = {...state, 'useCustomMirror': use};
  }

  void refresh() {
    _loadConfig();
  }
}

// 配置状态提供者
final configProvider = StateNotifierProvider<ConfigNotifier, Map<String, dynamic>>((ref) {
  return ConfigNotifier();
});

// 搜索过滤器
final searchFilterProvider = StateProvider<String>((ref) => '');

// 频道过滤器
final channelFilterProvider = StateProvider<String>((ref) => 'all');

// 过滤后的远程SDK列表
final filteredRemoteSdkProvider = Provider<AsyncValue<List<FlutterRelease>>>((ref) {
  final remoteSdkAsync = ref.watch(remoteSdkProvider);
  final searchFilter = ref.watch(searchFilterProvider);
  final channelFilter = ref.watch(channelFilterProvider);

  return remoteSdkAsync.when(
    data: (releases) {
      List<FlutterRelease> filtered = releases;

      // 频道过滤
      if (channelFilter != 'all') {
        filtered = filtered.where((release) => release.channel == channelFilter).toList();
      }

      // 搜索过滤
      if (searchFilter.isNotEmpty) {
        filtered = filtered.where((release) {
          return release.version.toLowerCase().contains(searchFilter.toLowerCase()) ||
                 release.channel.toLowerCase().contains(searchFilter.toLowerCase());
        }).toList();
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
}); 