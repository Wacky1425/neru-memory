import 'package:flutter_test/flutter_test.dart';
import 'package:neru_memory/core/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AppState loads with a valid theme mode', () async {
    final state = await AppState.load();
    expect(state.themeMode.name, isNotEmpty);
  });
}
