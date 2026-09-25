import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../widgets/common.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    return Scaffold(appBar: AppBar(title: const Text('設定', style: TextStyle(fontWeight: FontWeight.w800))), body: PageWrap(child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
      const SectionTitle('表示'),
      Card(child: Column(children: [_themeTile(context, s, ThemeMode.light, 'ライト', '白 × 青。端末設定に関係なくライト表示', Icons.light_mode_outlined), _themeTile(context, s, ThemeMode.dark, 'ダーク', '濃い背景 × 青', Icons.dark_mode_outlined), _themeTile(context, s, ThemeMode.system, '端末設定', '端末のテーマに合わせる', Icons.settings_brightness_outlined)])),
      const SectionTitle('連携'),
      const Card(child: Column(children: [ListTile(leading: Icon(Icons.account_circle_outlined), title: Text('Google アカウント'), subtitle: Text('Phase 3で接続')), Divider(height: 1), ListTile(leading: Icon(Icons.calendar_month_outlined), title: Text('Google Calendar'), subtitle: Text('Phase 3で接続'))])),
      const SectionTitle('Android'),
      const Card(child: ListTile(leading: Icon(Icons.widgets_outlined), title: Text('ホーム画面ウィジェット'), subtitle: Text('Quick Capture / Today を実装予定'))),
      const SizedBox(height: 24), Center(child: Text('Neru Memory  v0.2.0')),
    ])));
  }
  Widget _themeTile(BuildContext context, AppState s, ThemeMode mode, String title, String subtitle, IconData icon) => ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: s.themeMode == mode ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : const Icon(Icons.circle_outlined), onTap: () => s.setTheme(mode));
}
