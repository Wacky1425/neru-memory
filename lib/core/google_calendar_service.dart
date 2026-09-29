import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class CalendarEventItem {
  CalendarEventItem({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.description = '',
  });

  final String id;
  String title;
  DateTime start;
  DateTime end;
  bool allDay;
  String description;
}

class GoogleCalendarService {
  GoogleCalendarService._();

  static final instance = GoogleCalendarService._();

  static const scopes = <String>[
    'https://www.googleapis.com/auth/calendar',
  ];

  static const _serverClientId =
      '916997940907-baq8lhqiprcubd048bnmo6hclui5l94b.apps.googleusercontent.com';

  bool _initialized = false;
  GoogleSignInAccount? _account;

  bool get isConnected => _account != null;

  Future<void> _init() async {
    if (_initialized) return;

    // google_sign_in 7.x requires initialize exactly once.
    await GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId,
    );
    _initialized = true;
  }

  /// Restores the previously authenticated Google account without showing UI.
  /// Returns false when user interaction is required.
  Future<bool> restoreConnection() async {
    await _init();

    if (_account != null) {
      final auth = await _account!.authorizationClient
          .authorizationForScopes(scopes);
      if (auth != null) return true;
    }

    try {
      final future =
          GoogleSignIn.instance.attemptLightweightAuthentication();
      if (future == null) return false;

      final account = await future;
      if (account == null) return false;

      final auth =
          await account.authorizationClient.authorizationForScopes(scopes);
      if (auth == null) return false;

      _account = account;
      return true;
    } on GoogleSignInException {
      return false;
    }
  }

  /// Explicit user action. This is the only path allowed to show Google UI.
  Future<void> connect() async {
    await _init();

    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: scopes,
    );
    await account.authorizationClient.authorizeScopes(scopes);
    _account = account;
  }

  Future<Map<String, String>> _headers({
    bool allowRestore = true,
  }) async {
    await _init();

    if (_account == null && allowRestore) {
      await restoreConnection();
    }

    final account = _account;
    if (account == null) {
      throw StateError('Calendar authorization required');
    }

    var headers = await account.authorizationClient.authorizationHeaders(
      scopes,
      promptIfNecessary: false,
    );

    if (headers == null) {
      // Do not unexpectedly show consent UI during background/calendar refresh.
      final auth =
          await account.authorizationClient.authorizationForScopes(scopes);
      if (auth != null) {
        headers = await account.authorizationClient.authorizationHeaders(
          scopes,
          promptIfNecessary: false,
        );
      }
    }

    if (headers == null) {
      throw StateError('Calendar authorization required');
    }

    return <String, String>{
      ...headers,
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, String>> _renewHeaders(
    Map<String, String> previous,
  ) async {
    final account = _account;
    if (account == null) {
      throw StateError('Calendar authorization required');
    }

    final authorization = previous['Authorization'];
    if (authorization != null &&
        authorization.startsWith('Bearer ') &&
        authorization.length > 7) {
      try {
        await account.authorizationClient.clearAuthorizationToken(
          accessToken: authorization.substring(7),
        );
      } catch (_) {
        // Cache clearing is best-effort; the silent authorization call below
        // is still worth trying.
      }
    }

    final auth =
        await account.authorizationClient.authorizationForScopes(scopes);
    if (auth == null) {
      throw StateError('Calendar authorization required');
    }

    final headers = await account.authorizationClient.authorizationHeaders(
      scopes,
      promptIfNecessary: false,
    );
    if (headers == null) {
      throw StateError('Calendar authorization required');
    }

    return <String, String>{
      ...headers,
      'Content-Type': 'application/json',
    };
  }

  Future<http.Response> _get(Uri uri) async {
    var headers = await _headers();
    var response = await http.get(uri, headers: headers);

    if (response.statusCode == 401) {
      headers = await _renewHeaders(headers);
      response = await http.get(uri, headers: headers);
    }
    return response;
  }

  Future<http.Response> _post(Uri uri, Object body) async {
    var headers = await _headers();
    var response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      headers = await _renewHeaders(headers);
      response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
    }
    return response;
  }

  Future<http.Response> _patch(Uri uri, Object body) async {
    var headers = await _headers();
    var response = await http.patch(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      headers = await _renewHeaders(headers);
      response = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
    }
    return response;
  }

  Future<List<CalendarEventItem>> listEvents(
    DateTime from,
    DateTime to,
  ) async {
    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events',
      <String, String>{
        'timeMin': from.toUtc().toIso8601String(),
        'timeMax': to.toUtc().toIso8601String(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'maxResults': '250',
      },
    );

    final response = await _get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Calendar取得失敗 ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['items'] as List?) ?? <dynamic>[]).map((raw) {
      final event = Map<String, dynamic>.from(raw as Map);
      final startData =
          Map<String, dynamic>.from(event['start'] ?? <String, dynamic>{});
      final endData =
          Map<String, dynamic>.from(event['end'] ?? <String, dynamic>{});
      final allDay = startData['dateTime'] == null;

      final start = DateTime.tryParse(
            (startData['dateTime'] ?? startData['date'] ?? '').toString(),
          ) ??
          DateTime.now();
      final end = DateTime.tryParse(
            (endData['dateTime'] ?? endData['date'] ?? '').toString(),
          ) ??
          start;

      return CalendarEventItem(
        id: (event['id'] ?? '').toString(),
        title: (event['summary'] ?? '(無題)').toString(),
        start: start.toLocal(),
        end: end.toLocal(),
        allDay: allDay,
        description: (event['description'] ?? '').toString(),
      );
    }).toList();
  }

  Future<CalendarEventItem> createEvent({
    required String title,
    required DateTime start,
    DateTime? end,
    String description = '',
  }) async {
    final finish = end ?? start.add(const Duration(hours: 1));
    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events',
    );

    final response = await _post(uri, <String, dynamic>{
      'summary': title,
      'description': description,
      'start': <String, String>{
        'dateTime': start.toUtc().toIso8601String(),
      },
      'end': <String, String>{
        'dateTime': finish.toUtc().toIso8601String(),
      },
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Calendar追加失敗 ${response.statusCode}: ${response.body}',
      );
    }

    final event = jsonDecode(response.body) as Map<String, dynamic>;
    return CalendarEventItem(
      id: (event['id'] ?? '').toString(),
      title: title,
      start: start,
      end: finish,
      description: description,
    );
  }

  Future<void> updateEvent(CalendarEventItem event) async {
    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events/'
          '${Uri.encodeComponent(event.id)}',
    );

    final response = await _patch(uri, <String, dynamic>{
      'summary': event.title,
      'description': event.description,
      'start': <String, String>{
        'dateTime': event.start.toUtc().toIso8601String(),
      },
      'end': <String, String>{
        'dateTime': event.end.toUtc().toIso8601String(),
      },
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Calendar更新失敗 ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<CalendarEventItem?> getEvent(String eventId) async {
    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events/${Uri.encodeComponent(eventId)}',
    );
    final response = await _get(uri);
    if (response.statusCode == 404 || response.statusCode == 410) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Calendar予定取得失敗 ${response.statusCode}: ${response.body}',
      );
    }
    final event = jsonDecode(response.body) as Map<String, dynamic>;
    final startData = Map<String, dynamic>.from(
      event['start'] ?? <String, dynamic>{},
    );
    final endData = Map<String, dynamic>.from(
      event['end'] ?? <String, dynamic>{},
    );
    final allDay = startData['dateTime'] == null;
    final start = DateTime.tryParse(
          (startData['dateTime'] ?? startData['date'] ?? '').toString(),
        ) ??
        DateTime.now();
    final end = DateTime.tryParse(
          (endData['dateTime'] ?? endData['date'] ?? '').toString(),
        ) ??
        start;
    return CalendarEventItem(
      id: (event['id'] ?? eventId).toString(),
      title: (event['summary'] ?? '(無題)').toString(),
      start: start.toLocal(),
      end: end.toLocal(),
      allDay: allDay,
      description: (event['description'] ?? '').toString(),
    );
  }

  Future<void> deleteEvent(String eventId) async {
    var headers = await _headers();
    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events/${Uri.encodeComponent(eventId)}',
    );
    var response = await http.delete(uri, headers: headers);
    if (response.statusCode == 401) {
      headers = await _renewHeaders(headers);
      response = await http.delete(uri, headers: headers);
    }
    if (response.statusCode == 404 || response.statusCode == 410) return;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Calendar削除失敗 ${response.statusCode}: ${response.body}',
      );
    }
  }

}
