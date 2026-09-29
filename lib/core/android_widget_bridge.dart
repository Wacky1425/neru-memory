import 'package:flutter/services.dart';
import 'app_state.dart';

class AndroidWidgetBridge {
  AndroidWidgetBridge._();
  static final instance = AndroidWidgetBridge._();
  static const _channel = MethodChannel('neru_memory/widgets');

  Future<void> init(AppState state) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'quickCapture') {
        final text = (call.arguments as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          state.addInbox(text);
        }
      }
    });
    await sync(state);
  }

  Future<void> sync(AppState state) async {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final startTomorrow = startToday.add(const Duration(days: 1));

    final overdue = state.tasks.where((task) {
      final deadline = task.deadline;
      return !task.completed &&
          deadline != null &&
          deadline.isBefore(startToday);
    }).toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    final today = state.tasks.where((task) {
      if (task.completed) return false;
      final deadline = task.deadline;
      final deadlineToday = deadline != null &&
          !deadline.isBefore(startToday) &&
          deadline.isBefore(startTomorrow);
      return task.bucket.name == 'today' || deadlineToday;
    }).toList();

    final lines = <String>[
      ...overdue.map((task) => '⚠ ${task.title}'),
      ...today
          .where((task) => !overdue.any((item) => item.id == task.id))
          .map((task) => '• ${task.title}'),
    ].take(6).toList();

    try {
      await _channel.invokeMethod('updateToday', <String, dynamic>{
        'items': lines,
        'overdueCount': overdue.length,
        'todayCount': today.length,
      });
    } catch (_) {}
  }
}
