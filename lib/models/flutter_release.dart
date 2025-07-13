class FlutterRelease {
  final String version;
  final String channel;
  final String sha;
  final String releaseDate;
  final String dartSdkVersion;
  final String dartSdkArch;
  final String archive;
  final int size;
  final String sha256;
  final bool isInstalled;
  final bool isActive;

  FlutterRelease({
    required this.version,
    required this.channel,
    required this.sha,
    required this.releaseDate,
    required this.dartSdkVersion,
    required this.dartSdkArch,
    required this.archive,
    required this.size,
    required this.sha256,
    this.isInstalled = false,
    this.isActive = false,
  });

  factory FlutterRelease.fromJson(Map<String, dynamic> json) {
    return FlutterRelease(
      version: json['version'] ?? '',
      channel: json['channel'] ?? '',
      sha: json['hash'] ?? '', // API返回的是 'hash' 而不是 'sha'
      releaseDate: json['release_date'] ?? '',
      dartSdkVersion: json['dart_sdk_version'] ?? '',
      dartSdkArch: json['dart_sdk_arch'] ?? '',
      archive: json['archive'] ?? '',
      size: json['size'] ?? 0,
      sha256: json['sha256'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'channel': channel,
      'sha': sha,
      'release_date': releaseDate,
      'dart_sdk_version': dartSdkVersion,
      'dart_sdk_arch': dartSdkArch,
      'archive': archive,
      'size': size,
      'sha256': sha256,
    };
  }

  FlutterRelease copyWith({
    String? version,
    String? channel,
    String? sha,
    String? releaseDate,
    String? dartSdkVersion,
    String? dartSdkArch,
    String? archive,
    int? size,
    String? sha256,
    bool? isInstalled,
    bool? isActive,
  }) {
    return FlutterRelease(
      version: version ?? this.version,
      channel: channel ?? this.channel,
      sha: sha ?? this.sha,
      releaseDate: releaseDate ?? this.releaseDate,
      dartSdkVersion: dartSdkVersion ?? this.dartSdkVersion,
      dartSdkArch: dartSdkArch ?? this.dartSdkArch,
      archive: archive ?? this.archive,
      size: size ?? this.size,
      sha256: sha256 ?? this.sha256,
      isInstalled: isInstalled ?? this.isInstalled,
      isActive: isActive ?? this.isActive,
    );
  }
}

class FlutterReleaseResponse {
  final String baseUrl;
  final String currentRelease;
  final List<FlutterRelease> releases;

  FlutterReleaseResponse({
    required this.baseUrl,
    required this.currentRelease,
    required this.releases,
  });

  factory FlutterReleaseResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> releasesJson = json['releases'] ?? [];
    final List<FlutterRelease> releases = releasesJson
        .map((releaseJson) => FlutterRelease.fromJson(releaseJson))
        .toList();

    // current_release是一个Map，包含各个channel的当前版本hash
    String currentReleaseStr = '';
    final currentReleaseMap = json['current_release'];
    if (currentReleaseMap is Map) {
      // 优先使用stable，然后是beta，dev
      currentReleaseStr = currentReleaseMap['stable']?.toString() ?? 
                         currentReleaseMap['beta']?.toString() ?? 
                         currentReleaseMap['dev']?.toString() ?? '';
    } else if (currentReleaseMap is String) {
      currentReleaseStr = currentReleaseMap;
    }

    return FlutterReleaseResponse(
      baseUrl: json['base_url'] ?? '',
      currentRelease: currentReleaseStr,
      releases: releases,
    );
  }
} 