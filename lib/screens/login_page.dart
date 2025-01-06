import 'package:flutter/material.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/firebase/auth_handler.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final user = await _authService.loginWithEmailPassword(email, password);

      if (user != null) {
        if (mounted) {
          // Taking user to Home page
          Navigator.pushReplacementNamed(context, '/home');
          // Sending info to screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sikeres belépés!")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sikertelen belépés!")),
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
      // Added Scaffold here
      backgroundColor: AppColors.spaceCadet,
      body: SingleChildScrollView(
        // margin: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _header(context),
            _inputField(context),
            // _forgotPassword(context),
            _signup(context),
          ],
        ),
      ),
    );
  }

  _header(context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/app_logo.png', height: 200, width: 400),
          const Text(
            "Üdvözlünk!",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.antiFlashWhite),
          ),
          const Text(
            "Lépj be a fiókodba",
            style: TextStyle(color: AppColors.antiFlashWhite),
          )
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
                prefixIcon: const Icon(Icons.person, color: AppColors.coolGrey),
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
                hintText: "Jelszó",
                hintStyle: const TextStyle(color: AppColors.coolGrey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.coolGrey,
                    width: 3.0,
                  ),
                ),
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
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                  fixedSize: const Size(250, 60),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.coolGrey),
              child: const Text(
                "Bejelentkezés",
                style: TextStyle(fontSize: 20, color: AppColors.antiFlashWhite),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Elfelejtett jelszó:
/*
  _forgotPassword(context) {
    return TextButton(
      onPressed: () {},
      child: const Text(
        "Forgot password?",
        style: TextStyle(color: Colors.purple),
      ),
    );
  }
*/

  _signup(context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Nincs még fiókod? ",
            style: TextStyle(fontSize: 16, color: AppColors.antiFlashWhite),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(
                  context, '/signup'); // Navigate to sign-up page
            },
            child: const Text(
              "Regisztrálok",
              style: TextStyle(fontSize: 20, color: AppColors.orangePeel),
            ),
          ),
        ],
      ),
    );
  }
}
