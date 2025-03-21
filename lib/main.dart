import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logolda/screens/create_page.dart';
import 'package:logolda/screens/home_page.dart';
import 'package:logolda/screens/login_page.dart';
import 'package:logolda/screens/category_page.dart';
import 'package:logolda/screens/register_page.dart';
import 'package:logolda/screens/archive_page.dart';
import 'package:logolda/screens/standings_page.dart';
import 'package:logolda/screens/intro_page.dart';
import 'package:logolda/services/noti_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotiService().initNotification();
  await Firebase.initializeApp();

  // Request notification permissions
  final notificationSettings = await FirebaseMessaging.instance.requestPermission(provisional: true);

  // For Apple platforms, ensure the APNS token is available before making any FCM plugin API calls
  final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
  if (apnsToken != null) {
    // APNS token is available, make FCM plugin API requests...
  }

  // Request SCHEDULE_EXACT_ALARM permission
  if (await Permission.scheduleExactAlarm.request().isGranted) {
    // Permission granted, proceed with scheduling notifications
  } else {
    // Handle the case where the permission is not granted
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login Demo',
      theme: ThemeData(
        fontFamily: 'Michroma',
        useMaterial3: true
      ),
      initialRoute: '/', // Set the initial route to the login page
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/signup': (context) => const SignupPage(),
        '/create': (context) => const AddTaskPage(),
        '/archive': (context) => const ArchivePage(),
        '/category': (context) => const CategoryPage(),
        '/standings': (context) => const StandingsPage(),
        '/intro': (context) => const IntroPage(),
      },
    );
  }
}





