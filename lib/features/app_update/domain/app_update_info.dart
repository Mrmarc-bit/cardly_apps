/// Model entitas informasi pembaruan versi Cardly
class AppUpdateInfo {
  final String latestVersion;
  final int buildNumber;
  final String downloadUrl;
  final List<String> changelog;
  final bool isForceUpdate;
  final String releaseDate;
  final int fileSizeBytes;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.buildNumber,
    required this.downloadUrl,
    required this.changelog,
    this.isForceUpdate = false,
    this.releaseDate = '',
    this.fileSizeBytes = 0,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion:
          (json['latest_version'] as String?) ??
          (json['tag_name'] as String?)?.replaceAll('v', '') ??
          '1.0.0',
      buildNumber: (json['build_number'] as num?)?.toInt() ?? 1,
      downloadUrl:
          (json['download_url'] as String?) ??
          (json['browser_download_url'] as String?) ??
          '',
      changelog:
          (json['changelog'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          _parseBodyChangelog((json['body'] as String?) ?? ''),
      isForceUpdate: (json['is_force_update'] as bool?) ?? false,
      releaseDate:
          (json['release_date'] as String?) ??
          (json['published_at'] as String?) ??
          '',
      fileSizeBytes:
          (json['file_size_bytes'] as num?)?.toInt() ??
          (json['size'] as num?)?.toInt() ??
          0,
    );
  }

  static List<String> _parseBodyChangelog(String body) {
    if (body.isEmpty) return const [];
    return body
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'^[\*\-\d\.\s]+'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toJson() => {
    'latest_version': latestVersion,
    'build_number': buildNumber,
    'download_url': downloadUrl,
    'changelog': changelog,
    'is_force_update': isForceUpdate,
    'release_date': releaseDate,
    'file_size_bytes': fileSizeBytes,
  };
}
