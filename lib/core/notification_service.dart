import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'neru_memory_reminders',
      'Neru Memory リマインダー',
      channelDescription: 'やることや予定のリマインダー',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (response) {
        // V1.4: notification taps safely open the app.
        // Item-level deep-link routing can be added without changing scheduled payloads.
      },
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  int _id(String prefix, String id) {
    var h = 17;
    for (final c in '$prefix:$id'.codeUnits) {
      h = (h * 37 + c) & 0x7fffffff;
    }
    return h;
  }

  Future<void> showTest() async {
    await init();
    await plugin.show(
      10001,
      'Neru Memory',
      '通知は正常に動いています',
      _details,
    );
  }

  Future<void> showDueDigest(int overdue, int today) async {
    await init();
    final parts = <String>[];
    if (overdue > 0) parts.add('期限切れ $overdue件');
    if (today > 0) parts.add('今日 $today件');
    await plugin.show(
      10002,
      '今日のNeru Memory',
      parts.isEmpty ? '今日の未完了Taskはありません' : parts.join('・'),
      _details,
    );
  }

  Future<void> syncTask(MemoryTask task) async {
    await init();
    final nid = _id('task', task.id);
    await plugin.cancel(nid);
    final at = task.deadline;
    if (task.completed || at == null || !at.isAfter(DateTime.now())) return;
    await plugin.zonedSchedule(
      nid,
      'やること',
      task.title,
      tz.TZDateTime.from(at, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'task:${task.id}',
    );
  }

  Future<void> syncFuture(FutureItem item) async {
    await init();
    final nid = _id('future', item.id);
    await plugin.cancel(nid);
    final at = item.scheduledAt;
    if (at == null ||
        !at.isAfter(DateTime.now()) ||
        item.status == FutureStatus.completed ||
        item.status == FutureStatus.dropped) {
      return;
    }
    await plugin.zonedSchedule(
      nid,
      '予定',
      item.title,
      tz.TZDateTime.from(at, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'future:${item.id}',
    );
  }

  Future<void> cancelTask(String id) async {
    await init();
    await plugin.cancel(_id('task', id));
  }

  Future<void> cancelFuture(String id) async {
    await init();
    await plugin.cancel(_id('future', id));
  }

  Future<void> resyncAll(
    List<MemoryTask> tasks,
    List<FutureItem> futures,
  ) async {
    await init();
    for (final task in tasks) {
      await syncTask(task);
    }
    for (final item in futures) {
      await syncFuture(item);
    }
  }
}
