import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class AppPermissionHandler {
  static Future<bool> requestStoragePermissions() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    return statuses[Permission.storage]?.isGranted == true ||
        statuses[Permission.manageExternalStorage]?.isGranted == true;
  }

  static Future<bool> requestCameraPermission() async {
    if (await Permission.camera.isGranted) {
      return true;
    }

    PermissionStatus status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestLocationPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    return statuses[Permission.location]?.isGranted == true ||
        statuses[Permission.locationWhenInUse]?.isGranted == true;
  }

  static Future<bool> requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    return statuses.values.any((status) => status.isGranted);
  }

  static Future<bool> requestNotificationPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<void> requestAllPermissions(BuildContext context) async {
    // Show permission explanation dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app needs various permissions to provide the best experience:\n\n'
            '• Storage: Save QR codes and documents\n'
            '• Camera: Scan QR codes\n'
            '• Location: Travel tracking\n'
            '• Bluetooth: Offline messaging\n'
            '• Notifications: Important alerts',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    // Request permissions
    await requestStoragePermissions();
    await requestCameraPermission();
    await requestLocationPermissions();
    await requestBluetoothPermissions();
    await requestNotificationPermission();
  }
}
