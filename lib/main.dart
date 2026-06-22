import 'dart:io';
import 'package:club_india_user/firebase_options.dart';
import 'package:club_india_user/views/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

// ─────────────────────────────────────────────
// IMAGE DOWNLOAD HELPER
// ─────────────────────────────────────────────
Future<String?> _downloadAndSaveImage(String imageUrl) async {
  try {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/notification_image.jpg';
    final response = await http.get(Uri.parse(imageUrl));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    debugPrint('✅ [FCM] Notification image saved: $filePath');
    return filePath;
  } catch (e) {
    debugPrint('❌ [FCM] Image download failed: $e');
    return null;
  }
}

// ─────────────────────────────────────────────
// SHOW LOCAL NOTIFICATION (with or without image)
// ─────────────────────────────────────────────
Future<void> _showLocalNotification({
  required int id,
  required String? title,
  required String? body,
  String? imageUrl,
}) async {
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  debugPrint('🔔 [Notification] _showLocalNotification()');
  debugPrint('   Title   : $title');
  debugPrint('   Body    : $body');
  debugPrint('   ImageUrl: ${imageUrl ?? "NULL — no image"}');
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  StyleInformation? styleInformation;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    debugPrint('⬇️ [Notification] Image URL found — downloading...');
    final imagePath = await _downloadAndSaveImage(imageUrl);

    if (imagePath != null) {
      debugPrint('✅ [Notification] Image ready — applying BigPicture style');
      styleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(imagePath),
        largeIcon: FilePathAndroidBitmap(imagePath),
        hideExpandedLargeIcon: false,
        contentTitle: title,
        summaryText: body,
      );
    } else {
      debugPrint(
        '⚠️ [Notification] Image download failed — falling back to BigText',
      );
    }
  } else {
    debugPrint('ℹ️ [Notification] No image URL — using BigText style');
  }

  styleInformation ??= BigTextStyleInformation(body ?? '');

  debugPrint('📤 [Notification] Showing notification...');
  debugPrint('   Style: ${styleInformation.runtimeType}');

  await localNotifications.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'clubindia_channel',
        'Club India Notifications',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: styleInformation,
      ),
    ),
  );

  debugPrint('✅ [Notification] show() called successfully');
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

// ─────────────────────────────────────────────
// BACKGROUND HANDLER
// ─────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 [FCM] Background message: ${message.messageId}');

  final notification = message.notification;
  if (notification == null) return;

  final imageUrl =
      message.notification?.android?.imageUrl ??
      message.notification?.apple?.imageUrl ??
      message.data['image'];

  // await _showLocalNotification(
  //   id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  //   title: notification.title,
  //   body: notification.body,
  //   imageUrl: imageUrl,
  // );
  
}

// ─────────────────────────────────────────────
// LOCAL NOTIFICATION INIT
// ─────────────────────────────────────────────
Future<void> setupLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidInit,
  );

  await localNotifications.initialize(settings: settings);
  debugPrint('✅ [LocalNotifications] Initialized');
}

// ─────────────────────────────────────────────
// FIREBASE MESSAGING SETUP
// ─────────────────────────────────────────────
Future<void> setupFirebaseMessaging() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  final token = await messaging.getToken();
  debugPrint('🔥 [FCM] Token => $token');

  // ── Foreground ────────────────────────────────────────────
  // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  //   final notification = message.notification;
  //   if (notification == null) return;

  //   debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  //   debugPrint('📩 [FCM] Foreground message');
  //   debugPrint('   Title : ${notification.title}');
  //   debugPrint('   Body  : ${notification.body}');

  //   final imageUrl =
  //       message.notification?.android?.imageUrl ??
  //       message.notification?.apple?.imageUrl ??
  //       message.data['image'];
  //   debugPrint('   Image : ${imageUrl ?? "none"}');
  //   debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  //   await _showLocalNotification(
  //     id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  //     title: notification.title,
  //     body: notification.body,
  //     imageUrl: imageUrl,
  //   );
  // });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("📩 Foreground message received (no manual notification)");
  });

  // ── App opened from background notification ───────────────
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('🚀 [FCM] Opened from background: ${message.data}');
  });

  // ── App opened from terminated notification ───────────────
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('🚀 [FCM] Opened from terminated: ${initialMessage.data}');
  }
}

// ─────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await setupLocalNotifications();
  await setupFirebaseMessaging();

  runApp(const ClubIndiaApp());
}

// ─────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────
class ClubIndiaApp extends StatelessWidget {
  const ClubIndiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Club India',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFFF5F5),
      ),
      home: const SplashScreen(),
    );
  }
}
