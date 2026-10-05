import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../widgets/common.dart';
import '../lists/editors.dart';
import '../goals/goals_page.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  Future<void> _editInbox(BuildContext context, AppState state, InboxItem item) async {
    final controller = TextEditingController(text: item.text);
    final value = await showDialog<String>(context: context, builder: (c) => AlertDialog(
      title: const Text('Inboxを編集'),
      content: TextField(controller: controller, autofocus: true, maxLines: 3, decoration: const InputDecoration(labelText: '内容')),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('キャンセル')), FilledButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: const Text('保存'))],
    ));
    controller.dispose();
    if (value != null && value.isNotEmpty) state.updateInbox(item, value);
  }

  Future<void> _classify(BuildContext context, AppState state, InboxItem item, String type) async {
    final created = state.convertInbox(item, type);
    if (!context.mounted || created == null) return;
    if (created is MemoryTask) await editTask(context, created);
    if (created is WantItem) await editWant(context, created);
    if (created is FutureItem) await editFuture(context, created);
    if (created is GoalItem) await openGoalDetail(context, created);
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
                            } else if (value == 'edit') {
                              _editInbox(context, state, item);
                            } else {
                              _classify(context, state, item, value);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('内容を編集')),
                            PopupMenuDivider(),
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
