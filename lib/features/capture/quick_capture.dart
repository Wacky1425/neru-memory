import 'package:flutter/material.dart';
import '../../core/app_state.dart';

enum CaptureType { task, want, future, goal, inbox }

Future<void> showQuickCapture(BuildContext context) async {
  final state = AppStateScope.of(context);
  final controller = TextEditingController();
  var type = CaptureType.inbox;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '何か覚えておく？',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(hintText: '例：冬に温泉旅行したい'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Inbox', Icons.inbox_outlined, CaptureType.inbox),
                _chip('やること', Icons.check_box_outlined, CaptureType.task),
                _chip('買いたい', Icons.shopping_bag_outlined, CaptureType.want),
                _chip('予定候補', Icons.push_pin_outlined, CaptureType.future),
                _chip('目標', Icons.flag_outlined, CaptureType.goal),
              ].map((item) {
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$2, size: 17),
                      const SizedBox(width: 5),
                      Text(item.$1),
                    ],
                  ),
                  selected: type == item.$3,
                  onSelected: (_) => setLocal(() => type = item.$3),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  switch (type) {
                    case CaptureType.task:
                      state.addTask(text);
                    case CaptureType.want:
                      state.addWant(text);
                    case CaptureType.future:
                      state.addFuture(text);
                    case CaptureType.goal:
                      state.addGoal(text);
                    case CaptureType.inbox:
                      state.addInbox(text);
                  }
                  Navigator.pop(sheetContext);
                },
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  controller.dispose();
}

(String, IconData, CaptureType) _chip(
  String label,
  IconData icon,
  CaptureType type,
) =>
    (label, icon, type);
