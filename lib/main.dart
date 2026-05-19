import 'package:club_india_user/firebase_options.dart';
import 'package:club_india_user/services/user_notification_srevice.dart';
import 'package:club_india_user/views/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await UserNotificationService().initialize();

  runApp(const ClubIndiaApp());
}

class ClubIndiaApp extends StatelessWidget {
  const ClubIndiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
