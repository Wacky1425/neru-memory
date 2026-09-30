import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/app_state.dart';
import 'core/notification_service.dart';
import 'core/android_widget_bridge.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  if (!kIsWeb) {
    await NotificationService.instance.init();
  }

  final state = await AppState.load();
  if (!kIsWeb) {
    await AndroidWidgetBridge.instance.init(state);
  }

  runApp(
    AppStateScope(
      notifier: state,
      child: NeruMemoryApp(state: state),
    ),
  );
}
