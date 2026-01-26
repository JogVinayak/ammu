import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._();
  factory PermissionService() => _instance;
  PermissionService._();

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // Check notification permission
  Future<bool> hasNotificationPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Request notification permission
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Check exact alarm permission (Android 12+)
  Future<bool> hasExactAlarmPermission() async {
    if (!_isAndroid) return true;
    
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  // Request exact alarm permission
  Future<bool> requestExactAlarmPermission() async {
    if (!_isAndroid) return true;
    
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  // Check storage permission
  Future<bool> hasStoragePermission() async {
    if (kIsWeb) return true;
    
    if (_isAndroid) {
      // Android 13+ uses different permissions for media
      final status = await Permission.audio.status;
      if (status.isGranted) return true;
      
      // Fallback to storage for older Android versions
      return await Permission.storage.status.isGranted;
    }
    return true;
  }

  // Request storage permission for audio files
  Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true;
    
    if (_isAndroid) {
      // Try audio permission first (Android 13+)
      var status = await Permission.audio.request();
      if (status.isGranted) return true;
      
      // Fallback to storage permission
      status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  // Check all required permissions
  Future<Map<String, bool>> checkAllPermissions() async {
    if (kIsWeb) {
      return {
        'notification': true,
        'exactAlarm': true,
        'storage': true,
      };
    }
    return {
      'notification': await hasNotificationPermission(),
      'exactAlarm': await hasExactAlarmPermission(),
      'storage': await hasStoragePermission(),
    };
  }

  // Request all required permissions
  Future<Map<String, bool>> requestAllPermissions() async {
    if (kIsWeb) {
      return {
        'notification': true,
        'exactAlarm': true,
      };
    }
    
    final results = <String, bool>{};
    
    results['notification'] = await requestNotificationPermission();
    results['exactAlarm'] = await requestExactAlarmPermission();
    
    return results;
  }

  // Open app settings
  Future<bool> openSettings() async {
    if (kIsWeb) return false;
    return await openAppSettings();
  }

  // Show permission dialog
  Future<bool> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onRequest,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              onRequest();
            },
            child: const Text('Grant'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Show permission denied dialog with settings option
  Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
