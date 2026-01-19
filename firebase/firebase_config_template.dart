import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // 🔹 ANDROID
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "YOUR_ANDROID_API_KEY",
    appId: "YOUR_ANDROID_APP_ID",
    messagingSenderId: "287066847706",
    projectId: "loagmacrm-a60ba",
    databaseURL:
        "https://loagmacrm-a60ba-default-rtdb.asia-southeast1.firebasedatabase.app",
    storageBucket: "loagmacrm-a60ba.appspot.com",
  );

  // 🔹 iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "YOUR_IOS_API_KEY",
    appId: "YOUR_IOS_APP_ID",
    messagingSenderId: "287066847706",
    projectId: "loagmacrm-a60ba",
    databaseURL:
        "https://loagmacrm-a60ba-default-rtdb.asia-southeast1.firebasedatabase.app",
    storageBucket: "loagmacrm-a60ba.appspot.com",
    iosBundleId: "com.example.livesalesmantracking",
  );

  // 🔹 WEB
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyC7RmFi_6QGKyf4iid6adgFgAG7CIaWzI",
    appId: "1:287066847706:web:5045bbefa7341a80f168e3",
    messagingSenderId: "287066847706",
    projectId: "loagmacrm-a60ba",
    authDomain: "loagmacrm-a60ba.firebaseapp.com",
    databaseURL:
        "https://loagmacrm-a60ba-default-rtdb.asia-southeast1.firebasedatabase.app",
    storageBucket: "loagmacrm-a60ba.appspot.com",
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return web;
      default:
        return web;
    }
  }
}

// 🔹 INITIALIZER
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
}
