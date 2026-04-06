import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming_yoer/flutter_callkit_incoming.dart';
import 'package:get/get.dart';

// ==============================================================================
// 1. BACKGROUND HANDLER (Top-Level Function)
// ==============================================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('DEBUG: Background Message Received: ${message.messageId}');

  // NOTE: FCM automatically creates a notification tray item for 'notification' payloads.
  // We only need to manually show valid notifications if it's a data-only message
  // and we want to control the display. But for standard behavior, FCM SDK handles it.
}

// ==============================================================================
// 2. NOTIFICATION SERVICE CLASS
// ==============================================================================
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Initialize everything
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _requestPermissions();
    await _initLocalNotifications();
    await _createNotificationChannels(); // Create channels explicitly
    await _configureFCM();

    _isInitialized = true;
    print("DEBUG: NotificationService Initialized");
  }

  // Request Permissions (Android 13+ & iOS)
  Future<void> _requestPermissions() async {
    // IOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Android 13+ (UpsideDownCake) requires explict permission for local notifications via plugin
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // Initialize Local Notifications (For Foreground Banners)
  Future<void> _initLocalNotifications() async {
    // Use 'launcher_icon' to match the manifest, or 'ic_launcher' if you prefer.
    // 'launcher_icon' is safer if that's what the manifest uses for default.
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    final InitializationSettings settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("DEBUG: Local Notification Tapped: ${response.payload}");
        // TODO: Handle navigation based on payload
      },
    );
  }

  // Create Notification Channels (Critical for Android 8+)
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel highImportanceChannel =
        AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel fcmDefaultChannel =
        AndroidNotificationChannel(
      'message_channel_v4', // id (Match Manifest)
      'FCM Notifications', // title
      description:
          'Channel for Firebase Cloud Messaging notifications', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation
          .createNotificationChannel(highImportanceChannel);
      await androidImplementation.createNotificationChannel(fcmDefaultChannel);
      print("DEBUG: Notification Channels Created");
    }
  }

  // Configure FCM Listeners
  Future<void> _configureFCM() async {
    // Background message handler is set in main.dart

    // Foreground Message Handler
    // We listen here to LOG, but we rely on Socket.IO for the actual banner
    // to avoid potential duplicates if the server sends both.
    // OR we can decide to show it if it's a "notification" payload.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('DEBUG: FCM Foreground Message: ${message.notification?.title}');

      // If the message contains a notification payload, FCM might NOT show it automatically in foreground.
      // We can optionally show it here if Socket.IO isn't responsible for this specific message type.
      if (message.notification != null) {
        // If we want to rely ONLY on Socket.IO for chat, we do nothing here.
        // But if FCM is the primary delivery for some things, we might need to show it:
        // showLocalNotification(...)
      }
    });

    // Message Open App Handler (When app opened from background notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("DEBUG: details FCM Notification Opened: ${message.data}");
      // TODO: Handle navigation
    });
  }

  // Public method to show Local Notification (Called by Socket Client)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // print(
    //     "DEBUG: showLocalNotification called with Title: $title, Body: $body");
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel', // id
        'High Importance Notifications', // name
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        ticker: 'ticker',
      );

      const NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails, iOS: DarwinNotificationDetails());

      // Generate a unique ID based on time
      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      // print(
      //     "DEBUG: _localNotifications.show executed successfully for ID: $notificationId");
    } catch (e) {
      print("DEBUG: Error showing local notification: $e");
    }
  }

  // Get FCM Token
  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print("DEBUG: FCM Token: $token");
      return token;
    } catch (e) {
      print("DEBUG: Error getting FCM token: $e");
      return null;
    }
  }
}
