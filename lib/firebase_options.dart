// GENERATED PLACEHOLDER. Run `flutterfire configure` to replace this file.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      default: throw UnsupportedError('Run flutterfire configure for this platform.');
    }
  }
  static const FirebaseOptions web = FirebaseOptions(apiKey: 'CONFIGURE_ME', appId: 'CONFIGURE_ME', messagingSenderId: 'CONFIGURE_ME', projectId: 'CONFIGURE_ME');
  static const FirebaseOptions android = FirebaseOptions(apiKey: 'CONFIGURE_ME', appId: 'CONFIGURE_ME', messagingSenderId: 'CONFIGURE_ME', projectId: 'CONFIGURE_ME');
}
