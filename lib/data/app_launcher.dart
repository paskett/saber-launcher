import 'dart:io';

import 'package:flutter/services.dart';

class AppInfo {
  const AppInfo({required this.label, required this.packageName});

  final String label;
  final String packageName;
}

abstract class AppLauncher {
  static const _channel = MethodChannel('com.adilhanney.saber/launcher');

  static Future<List<AppInfo>> listApps() async {
    if (!Platform.isAndroid) return const [];
    final apps = await _channel.invokeListMethod<Map>('listApps');
    if (apps == null) return const [];
    return apps
        .map((app) => AppInfo(
              label: app['label'] as String? ?? '',
              packageName: app['packageName'] as String? ?? '',
            ))
        .toList();
  }

  static Future<void> launchApp(String packageName) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('launchApp', {'packageName': packageName});
  }
}
