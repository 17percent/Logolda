import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get logged-in user
  User? getLoggedInUser() {
    return _auth.currentUser;
  }

  // Register with email and password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      // handle incorrect credentials
      return null;
    }
  }

  // Login with email and password
  Future<User?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      // handle incorrect credentials
      return null;
    }
  } 

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
