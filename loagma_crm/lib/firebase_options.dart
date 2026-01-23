import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isIOS) {
      return ios;
    }
    return android;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC7RmFi_6QgKXyf4iid6adgFgAG7cIAwZI',
    appId: '1:287066847706:web:371e7e2dfd0c8da4f168e3',
    messagingSenderId: '287066847706',
    projectId: 'loagmacrm-a60ba',
    authDomain: 'loagmacrm-a60ba.firebaseapp.com',
    databaseURL:
        'https://loagmacrm-a60ba-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'loagmacrm-a60ba.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDzVcsntunSmyUzKVh8FrvDd2BQtNzEEHA',
    appId: '1:287066847706:android:8392042394366681f168e3',
    messagingSenderId: '287066847706',
    projectId: 'loagmacrm-a60ba',
    databaseURL:
        'https://loagmacrm-a60ba-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'loagmacrm-a60ba.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC8UI7Iko1HaIKA92rJcIsEHsAYx9gcOIc',
    appId: '1:287066847706:ios:f5865aecfeb4efeff168e3',
    messagingSenderId: '287066847706',
    projectId: 'loagmacrm-a60ba',
    databaseURL:
        'https://loagmacrm-a60ba-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'loagmacrm-a60ba.firebasestorage.app',
  );
}
