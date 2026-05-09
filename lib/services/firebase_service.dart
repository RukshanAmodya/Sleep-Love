import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart'; // ඔබ සාදා ගන්නා config ගොනුව

class FirebaseService {
  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase Initialized with Auto-Config!");
    } catch (e) {
      print("Firebase Initialization Error: $e");
    }
  }
}
