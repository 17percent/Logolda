import 'package:flutter/material.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/firebase/auth_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmedPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _register() async {
    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final passwordAgain = _confirmedPasswordController.text;

    try {
      if (password.length < 6) {
        // Password too short
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "A megadott jelszónak legalább 6 karakter hosszúnak kell lennie!")),
        );
      }
      final user =
          await _authService.registerWithEmailPassword(email, password);

      if (user != null) {
        if (mounted) {
          // Save user data to Firestore
          await _firestore.collection('Users').doc(user.uid).set({
            'uid': user.uid,
            'name': username,
            'email': email,
            'rank': "Logger",
            'seeds': 0,
            'createdAt': DateTime.now(),
          });
          if (mounted) {
            // Taking user back to login
            Navigator.pushNamed(context, '/');
            // Sending info to screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sikeres regisztráció!")),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sikertelen regisztráció!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceCadet,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_header(context), _inputField(context), _login(context)],
        ),
      ),
    );
  }

  _header(context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.only(top: 50),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.account_circle,
              color: AppColors.antiFlashWhite, size: 100),
          SizedBox(height: 20),
          Text(
            "Regisztráció",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.antiFlashWhite,
            ),
          ),
        ],
      ),
    );
  }

  _inputField(context) {
    return Container(
        margin: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    blurStyle: BlurStyle.normal,
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(0, 5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Felhasználó név",
                  hintStyle: const TextStyle(color: AppColors.coolGrey),
                  // Inaktív keret
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.coolGrey,
                      width: 3.0,
                    ),
                  ),
                  // Aktív keret
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.springBud,
                      width: 3.0,
                    ),
                  ),
                  fillColor: AppColors.antiFlashWhite,
                  filled: true,
                  prefixIcon:
                      const Icon(Icons.person, color: AppColors.coolGrey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    blurStyle: BlurStyle.normal,
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(0, 5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "E-mail cím",
                  hintStyle: const TextStyle(color: AppColors.coolGrey),
                  // Inaktív keret
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.coolGrey,
                      width: 3.0,
                    ),
                  ),
                  // Aktív keret
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.springBud,
                      width: 3.0,
                    ),
                  ),
                  fillColor: AppColors.antiFlashWhite,
                  filled: true,
                  prefixIcon:
                      const Icon(Icons.email, color: AppColors.coolGrey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    blurStyle: BlurStyle.normal,
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(0, 5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: "Jelszó (min. 6 karakter)",
                  hintStyle: const TextStyle(color: AppColors.coolGrey),
                  // Inaktív keret
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.coolGrey,
                      width: 3.0,
                    ),
                  ),
                  // Aktív keret
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.springBud,
                      width: 3.0,
                    ),
                  ),
                  fillColor: AppColors.antiFlashWhite,
                  filled: true,
                  prefixIcon:
                      const Icon(Icons.password, color: AppColors.coolGrey),
                ),
                obscureText: true,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    blurStyle: BlurStyle.normal,
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(0, 5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _confirmedPasswordController,
                decoration: InputDecoration(
                  hintText: "Jelszó megerősítése",
                  hintStyle: const TextStyle(color: AppColors.coolGrey),
                  // Inaktív keret
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.coolGrey,
                      width: 3.0,
                    ),
                  ),
                  // Aktív keret
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.springBud,
                      width: 3.0,
                    ),
                  ),
                  fillColor: AppColors.antiFlashWhite,
                  filled: true,
                  prefixIcon:
                      const Icon(Icons.password, color: AppColors.coolGrey),
                ),
                obscureText: true,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    blurStyle: BlurStyle.normal,
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(0, 5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.coolGrey,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.check_rounded, size: 50, color: AppColors.antiFlashWhite)),
              ),
            ),
          ],
        ));
  }

  _login(context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Van már fiókod?",
            style: TextStyle(fontSize: 16, color: AppColors.antiFlashWhite),
          ),
          TextButton(
              onPressed: () {
                Navigator.pushNamed(context, "/");
              },
              child: const Text(
                "Belépés",
                style: TextStyle(fontSize: 20, color: AppColors.orangePeel),
              ))
        ],
      ),
    );
  }
}
