import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAysBSDp3jOsCai15McUKwI8PSJ_ELUpbU',
    appId: '1:1021793302127:android:8e8954afd5e2b7cf363f9a',
    messagingSenderId: '1021793302127',
    projectId: 'qaxer-crash-apps',

    // GANTI sesuai URL Realtime Database kamu
    databaseURL:
        'https://qaxer-crash-apps-default-rtdb.asia-southeast1.firebasedatabase.app',
  );


  static const FirebaseOptions currentPlatform = android;
}