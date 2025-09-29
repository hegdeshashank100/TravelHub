import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class BackgroundLocationService {
  static const int NOTIFICATION_ID = 1001;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static bool _isTracking = false;

  // Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize notifications
    await _initializeNotifications();

    _isInitialized = true;
    print('🚀 Background Location Service initialized');
  }

  // Start background location tracking
  static Future<void> startBackgroundTracking() async {
    if (_isTracking) return;

    await initialize();

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions denied');
    }

    // Request background location permission for Android 10+
    if (permission != LocationPermission.always) {
      print('⚠️ Requesting background location permission...');
      // On Android 10+, users need to manually enable "Allow all the time" in settings
    }

    // Start enhanced location tracking through existing service
    LocationService.instance.enableBackgroundMode();

    // Show persistent notification
    await _showPersistentNotification();

    _isTracking = true;
    print(
        '✅ Background location tracking started with persistent notification');
  }

  // Stop background location tracking
  static Future<void> stopBackgroundTracking() async {
    if (!_isTracking) return;

    // Stop background mode in location service
    LocationService.instance.disableBackgroundMode();

    // Hide notification
    await _notifications.cancel(NOTIFICATION_ID);

    _isTracking = false;
    print('🛑 Background location tracking stopped');
  }

  // Initialize notifications
  static Future<void> _initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'background_location',
      'Background Location Tracking',
      description: 'Shows when live location is being tracked continuously',
      importance: Importance.low,
      showBadge: false,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  // Show persistent notification
  static Future<void> _showPersistentNotification() async {
    const androidSettings = AndroidNotificationDetails(
      'background_location',
      'Background Location Tracking',
      channelDescription: 'Live location tracking is active',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Makes it persistent
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosSettings = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.show(
      NOTIFICATION_ID,
      'Travelers Hub - Live Location',
      '🌍 Location tracking active • Updates every second',
      notificationDetails,
    );
  }

  // Check if background tracking is active
  static bool get isTracking => _isTracking;
}
