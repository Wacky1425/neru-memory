import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../widgets/common.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});
  @override Widget build(BuildContext context) { final s = AppStateScope.of(context); return Scaffold(appBar: AppBar(title: const Text('Inbox')), body: PageWrap(child: s.inbox.isEmpty ? const Center(child: Text('Inboxは空です')) : ListView(padding: const EdgeInsets.all(16), children: [for (final item in s.inbox) Card(child: ListTile(title: Text(item.text), subtitle: Text('${item.createdAt.month}/${item.createdAt.day} に保存'), trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'delete') { s.deleteInbox(item); } else { s.convertInbox(item, v); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'task', child: Text('やることにする')), PopupMenuItem(value: 'want', child: Text('買いたいにする')), PopupMenuItem(value: 'future', child: Text('予定候補にする')), PopupMenuItem(value: 'goal', child: Text('目標にする')), PopupMenuDivider(), PopupMenuItem(value: 'delete', child: Text('削除'))])))]))); }
}
