import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'api_service.dart';
import 'auth_service.dart';

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  await Firebase.initializeApp();
  _handleMessage(message);
}

void _handleMessage(RemoteMessage message) {
  print('========================================');
  print('Message received in background');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
  print('========================================');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FirebaseMessaging _firebaseMessaging;
  late FlutterLocalNotificationsPlugin _localNotifications;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    print('Initializing Firebase...');
    
    // Initialize Firebase
    await Firebase.initializeApp();
    
    _firebaseMessaging = FirebaseMessaging.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();

   // NEW CODE (CORRECT)
NotificationSettings settings = await _firebaseMessaging.requestPermission(
  alert: true,
  announcement: false,
  badge: true,
  criticalAlert: false,
  provisional: false,
  sound: true,
);

    print('User granted permission: ${settings.authorizationStatus}');

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Handle foreground messages
    print('Setting up foreground message handler...');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Handle messages opened from notification
    print('Setting up message opened handler...');
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened from notification: ${message.notification?.title}');
      _handleMessageOpenedApp(message);
    });

    // Handle background messages
    print('Setting up background message handler...');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get and log device token
    await _getAndSaveDeviceToken();

    print('Firebase initialization complete!');
  }

  Future<void> _initializeLocalNotifications() async {
    print('Initializing local notifications...');
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    print('Local notifications initialized');
  }

  // Callback for iOS notifications
  static Future<void> _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    print('iOS notification tapped: $title');
  }

  static Future<void> _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    print('Notification tapped: ${notificationResponse.payload}');
  }

  Future<void> _getAndSaveDeviceToken() async {
    try {
      print('Getting FCM device token...');
      final token = await _firebaseMessaging.getToken();
      
      if (token != null) {
        print('Device Token: $token');
        
        // Get user ID
        final authService = AuthService();
        final userId = authService.currentUserId;
        
        if (userId != null) {
          // Save to database
          print('Saving device token to database...');
          await _saveDeviceTokenToDatabase(int.parse(userId), token);
          print('Device token saved successfully');
        }
      }
    } catch (e) {
      print('Error getting device token: $e');
    }
  }

  Future<void> _saveDeviceTokenToDatabase(int userId, String token) async {
    try {
      await ApiService.saveDeviceToken(userId: userId, token: token);
    } catch (e) {
      print('Failed to save device token: $e');
    }
  }

  // Get device token (can be called anytime)
  Future<String> getDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      return token ?? '';
    } catch (e) {
      print('Error: $e');
      return '';
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling foreground message...');
    
    await _showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'Remindly',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  // Handle message opened from notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Handling message opened from app: ${message.notification?.title}');
    // You can navigate to specific page based on message data
    // e.g., if (message.data['type'] == 'alert') { navigate to alert page }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String payload = '',
  }) async {
    print('Showing local notification: $title');
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'remindly_channel',
          'Remindly Notifications',
          channelDescription: 'Notifications for reminders and alerts',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.m4a',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Schedule notification (for testing or offline reminders)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    print('Scheduling notification for: $scheduledTime');
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'remindly_channel',
          'Remindly Notifications',
          channelDescription: 'Notifications for reminders and alerts',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Notification scheduled successfully');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}