import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'features/auth/auth_gate.dart';

class NeruMemoryApp extends StatelessWidget {
  const NeruMemoryApp({super.key, required this.state});
  final AppState state;
  @override Widget build(BuildContext context) => AppStateScope(notifier: state, child: AnimatedBuilder(animation: state, builder: (context, child) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Neru Memory', theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: state.themeMode, home: const AuthGate())));
}
