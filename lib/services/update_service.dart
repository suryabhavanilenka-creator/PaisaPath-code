import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// In-app update check for the Android build.
///
/// The published website hosts a small `app-version.json` describing the
/// latest release. On startup (Android only) the app compares that version
/// with its own and, when newer, the UI offers a download link. Every
/// failure (offline, timeout, bad payload) is swallowed: the app is
/// offline-first and the check is purely optional.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.apkUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final String apkUrl;

  bool get updateAvailable =>
      latestVersion.isNotEmpty &&
      latestVersion != currentVersion &&
      apkUrl.isNotEmpty;
}

class UpdateService {
  const UpdateService();

  static const String _metaUrl =
      'https://paisapath-six.vercel.app/app-version.json';

  /// Returns [AppUpdateInfo] when a newer version exists, otherwise null.
  /// Never throws.
  Future<AppUpdateInfo?> checkForUpdate() async {
    // Web is always the latest deployment; other desktop targets unused.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final http.Response response = await http
          .get(Uri.parse(_metaUrl))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final String latest = (data['versionName'] as String?) ?? '';
      final String apkUrl = (data['apkUrl'] as String?) ?? '';
      if (latest.isEmpty || apkUrl.isEmpty) return null;

      final PackageInfo info = await PackageInfo.fromPlatform();
      if (latest == info.version) return null;

      return AppUpdateInfo(
        currentVersion: info.version,
        latestVersion: latest,
        apkUrl: apkUrl,
      );
    } on Exception {
      return null;
    } catch (_) {
      return null;
    }
  }
}
