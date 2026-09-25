import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'features/shell/app_shell.dart';

class NeruMemoryApp extends StatefulWidget {
  const NeruMemoryApp({super.key});
  @override State<NeruMemoryApp> createState() => _NeruMemoryAppState();
}

class _NeruMemoryAppState extends State<NeruMemoryApp> {
  final AppState state = AppState.seeded();
  @override Widget build(BuildContext context) {
    return AppStateScope(
      notifier: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (_, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Neru Memory',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: state.themeMode,
          home: const AppShell(),
        ),
      ),
    );
  }
}
