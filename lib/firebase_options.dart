import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      default: throw UnsupportedError('Neru Memory currently supports Android and Web.');
    }
  }
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDYYBiEnBr4JsEWpLfx3Yvc33d1fgiCF_8',
    appId: '1:916997940907:web:3b20155e3f51e44e66f9ee',
    messagingSenderId: '916997940907',
    projectId: 'neru-memory',
    authDomain: 'neru-memory.firebaseapp.com',
    storageBucket: 'neru-memory.firebasestorage.app',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYYBiEnBr4JsEWpLfx3Yvc33d1fgiCF_8',
    appId: '1:916997940907:android:fbe58652185fdaa666f9ee',
    messagingSenderId: '916997940907',
    projectId: 'neru-memory',
    storageBucket: 'neru-memory.firebasestorage.app',
  );
}
