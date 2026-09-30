import 'dart:async';

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

  final state = await AppState.load();

  runApp(
    AppStateScope(
      notifier: state,
      child: NeruMemoryApp(state: state),
    ),
  );

  if (!kIsWeb) {
    unawaited(_initAndroidServices(state));
  }
}

Future<void> _initAndroidServices(AppState state) async {
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.resyncAll(
      state.tasks,
      state.futures,
    );
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  try {
    await AndroidWidgetBridge.instance.init(state);
  } catch (e) {
    debugPrint('Widget init failed: $e');
  }
}

