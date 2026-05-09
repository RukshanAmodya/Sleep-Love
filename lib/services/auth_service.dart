import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<void> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    if (cred.user != null) {
      await _initializeUser(cred.user!.uid, "Guest");
    }
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await _initializeUser(cred.user!.uid, email);
    }
  }

  Future<void> _initializeUser(String uid, String email) async {
    final ref = _db.ref('users/$uid');
    final snapshot = await ref.get();
    if (snapshot.value == null) {
      await ref.set({
        'email': email,
        'isPro': false,
        'createdAt': ServerValue.timestamp,
      });
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
