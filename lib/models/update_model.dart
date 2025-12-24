class UpdateInfo {
  final bool updateAvailable;
  final String? latestVersion;
  final String? downloadUrl;
  final String? changelog;
  final bool forceUpdate;
  final String message;

  UpdateInfo({
    required this.updateAvailable,
    this.latestVersion,
    this.downloadUrl,
    this.changelog,
    this.forceUpdate = false,
    required this.message,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      updateAvailable: json['update_available'] ?? false,
      latestVersion: json['latest_version']?['version'],
      downloadUrl: json['latest_version']?['download_url'],
      changelog: json['latest_version']?['changelog'],
      forceUpdate: json['latest_version']?['force_update'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
