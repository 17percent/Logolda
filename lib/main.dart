import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logolda/screens/create_page.dart';
import 'package:logolda/screens/home_page.dart';
import 'package:logolda/screens/login_page.dart';
import 'package:logolda/screens/profile_page.dart';
import 'package:logolda/screens/register_page.dart';
import 'package:logolda/screens/archive_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        '/profile': (context) => const ProfilePage(),
        '/create': (context) => const AddTaskPage(),
        '/archive': (context) => const ArchivePage(),
      },
    );
  }
}





