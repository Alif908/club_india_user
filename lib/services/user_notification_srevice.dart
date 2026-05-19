import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background handler — top-level function വേണം (FCM requirement)
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseUserBackgroundHandler(RemoteMessage message) async {
  debugPrint('BG User Notification: ${message.notification?.title}');
}

// ─────────────────────────────────────────────────────────────────────────────
// UserNotificationService
// ─────────────────────────────────────────────────────────────────────────────
class UserNotificationService {
  static final UserNotificationService _instance =
      UserNotificationService._internal();
  factory UserNotificationService() => _instance;
  UserNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const AndroidNotificationChannel _userChannel =
      AndroidNotificationChannel(
        'club_india_user',
        'User Notifications',
        description: 'Coin earned, offers, money credited alerts',
        importance: Importance.high,
        playSound: true,
      );

  // ── Step 1: App start-ൽ ഒരിക്കൽ call ചെയ്യുക (main.dart) ─────────────────
  Future<void> initialize() async {
    // ── Firestore connection test ──────────────────────────────────────────
    try {
      await FirebaseFirestore.instance.collection('test').doc('ping').set({
        'time': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Firestore direct test SUCCESS');
    } catch (e) {
      debugPrint('❌ Firestore direct test FAILED: $e');
    }

    // ── Local notifications setup ──────────────────────────────────────────
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotifTapped,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_userChannel);
    }

    await _requestPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseUserBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotifOpened);

    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token Refreshed: $newToken');
      if (_currentPhone != null) {
        _saveTokenToFirestore(_currentPhone!, newToken);
      }
    });

    debugPrint('✅ UserNotificationService initialized');
  }

  // Current logged-in phone — token refresh-ന് വേണ്ടി cache ചെയ്യുന്നു
  String? _currentPhone;

  // ── Step 2: OTP verify success ആയ ഉടൻ ഇത് call ചെയ്യുക (login_page.dart) ──
  // phoneNumber: "9876543210" (digits only, 10 digits)
  Future<void> saveTokenForUser(String phoneNumber) async {
    _currentPhone = phoneNumber;

    final String? token = await _fcm.getToken();
    if (token == null) {
      debugPrint('❌ FCM token null — cannot save');
      return;
    }

    await _saveTokenToFirestore(phoneNumber, token);

    // Broadcast topic — admin-ന് all users-നെ ഒരുമിച്ച് notify ചെയ്യണമെങ്കിൽ
    await _fcm.subscribeToTopic('all_users');
    debugPrint('✅ Token saved & subscribed for $phoneNumber');
  }

  // ── Step 3: Logout ആകുമ്പോൾ call ചെയ്യുക (profile_page.dart) ──────────────
  Future<void> clearTokenOnLogout(String phoneNumber) async {
    _currentPhone = null;

    try {
      await _firestore.collection('users').doc(phoneNumber).update({
        'fcmToken': FieldValue.delete(),
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      await _fcm.unsubscribeFromTopic('all_users');
      await _fcm.deleteToken(); // പഴയ token invalid ആക്കുന്നു
      debugPrint('🚫 Token cleared for $phoneNumber');
    } catch (e) {
      debugPrint('❌ Token clear failed: $e');
    }
  }

  // ── Private: Firestore-ൽ token save ─────────────────────────────────────
  // users → {phoneNumber} → { fcmToken, tokenUpdatedAt, platform }
  Future<void> _saveTokenToFirestore(String phoneNumber, String token) async {
    try {
      await _firestore
          .collection('users')
          .doc(phoneNumber) // phone number തന്നെ document ID
          .set(
            {
              'fcmToken': token,
              'tokenUpdatedAt': FieldValue.serverTimestamp(),
              'platform': defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'android',
            },
            SetOptions(merge: true), // മറ്റ് fields overwrite ആകരുത്
          );
      debugPrint('✅ FCM token saved to Firestore for $phoneNumber');
    } catch (e) {
      debugPrint('❌ Firestore token save failed: $e');
    }
  }

  // ── Foreground notification show ─────────────────────────────────────────
  void _onForegroundMessage(RemoteMessage message) {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'club_india_user',
          'User Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFF2D78),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['screen']?.toString(),
    );
  }

  void _onNotifTapped(NotificationResponse response) {
    debugPrint('📲 Tapped → screen: ${response.payload}');
    // TODO: NavigatorKey ഉപയോഗിച്ച് screen navigate ചെയ്യുക
  }

  void _onNotifOpened(RemoteMessage message) {
    debugPrint('🚀 Opened from BG → screen: ${message.data['screen']}');
  }

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permission: ${settings.authorizationStatus}');
  }

  Future<String?> getToken() async => await _fcm.getToken();
}
