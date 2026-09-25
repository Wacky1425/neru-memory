import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/auth_service.dart';
import '../shell/app_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: AuthService.instance.authChanges,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      final user = snapshot.data;
      if (user == null) return const _LoginPage();
      return _CloudConnector(uid: user.uid);
    },
  );
}

class _CloudConnector extends StatefulWidget {
  const _CloudConnector({required this.uid});
  final String uid;
  @override State<_CloudConnector> createState() => _CloudConnectorState();
}
class _CloudConnectorState extends State<_CloudConnector> {
  bool started = false;
  @override void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) { started = true; AppStateScope.of(context).connectCloud(widget.uid); }
  }
  @override Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (state.cloudBusy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (state.cloudError != null && !state.cloudReady) {
      return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 48), const SizedBox(height: 12), const Text('クラウド同期に接続できませんでした'), const SizedBox(height: 8), Text(state.cloudError!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: () => state.connectCloud(widget.uid), child: const Text('再試行')), TextButton(onPressed: AuthService.instance.signOut, child: const Text('ログアウト')),
      ]))));
    }
    return const AppShell();
  }
}

class _LoginPage extends StatefulWidget { const _LoginPage(); @override State<_LoginPage> createState() => _LoginPageState(); }
class _LoginPageState extends State<_LoginPage> {
  bool busy = false;
  String? error;
  Future<void> signIn() async {
    setState(() { busy = true; error = null; });
    try { await AuthService.instance.signInWithGoogle(); }
    catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.memory_rounded, size: 64, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 20), Text('Neru Memory', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Text('未来のための外部記憶'), const SizedBox(height: 28), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : signIn, icon: const Icon(Icons.login), label: Text(busy ? '接続中…' : 'Googleでログイン'))), if (error != null) ...[const SizedBox(height: 12), Text(error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error))],
  ])))));
}
