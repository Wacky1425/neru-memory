import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../lists/editors.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  Future<void> _classify(BuildContext context, AppState state, InboxItem item, String type) async {
    state.convertInbox(item, type);
    if (!context.mounted) return;
    switch (type) {
      case 'task':
        await editTask(context, state.tasks.first);
      case 'want':
        await editWant(context, state.wants.first);
      case 'future':
        await editFuture(context, state.futures.first);
      case 'goal':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目標に整理しました')),
        );
    }
  }

  Future<void> _chooseType(BuildContext context, AppState state, InboxItem item) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text('どこに整理する？', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('選んだあと、そのまま詳細を設定できます'),
            ),
            ListTile(leading: const Icon(Icons.check_circle_outline), title: const Text('やること'), subtitle: const Text('期限・今日/近いうち/いつか・メモ・タグ'), onTap: () => Navigator.pop(sheetContext, 'task')),
            ListTile(leading: const Icon(Icons.shopping_bag_outlined), title: const Text('買いたい'), subtitle: const Text('予算・時期・待機条件・メモ・タグ'), onTap: () => Navigator.pop(sheetContext, 'want')),
            ListTile(leading: const Icon(Icons.push_pin_outlined), title: const Text('予定候補'), subtitle: const Text('時期・日時・ステータス・メモ・タグ'), onTap: () => Navigator.pop(sheetContext, 'future')),
            ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('目標'), subtitle: const Text('長期的に追いかけたいこと'), onTap: () => Navigator.pop(sheetContext, 'goal')),
          ],
        ),
      ),
    );
    if (type != null && context.mounted) await _classify(context, state, item, type);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Inbox  ${state.inbox.length}件')),
      body: PageWrap(
        child: state.inbox.isEmpty
            ? const Center(child: Text('Inboxは空です'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('思いつきを、あとから使える形に整理します。')),
                  for (final item in state.inbox)
                    Card(
                      child: ListTile(
                        onTap: () => _chooseType(context, state, item),
                        leading: const Icon(Icons.inbox_outlined),
                        title: Text(item.text),
                        subtitle: Text('${item.createdAt.month}/${item.createdAt.day} に保存'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              state.deleteInbox(item);
                            } else {
                              _classify(context, state, item, value);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'task', child: Text('やることに整理')),
                            PopupMenuItem(value: 'want', child: Text('買いたいに整理')),
                            PopupMenuItem(value: 'future', child: Text('予定候補に整理')),
                            PopupMenuItem(value: 'goal', child: Text('目標に整理')),
                            PopupMenuDivider(),
                            PopupMenuItem(value: 'delete', child: Text('削除')),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
