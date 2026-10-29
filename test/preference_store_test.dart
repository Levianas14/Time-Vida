import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo_vivo/storage/preference_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
    () => SharedPreferences.setMockInitialValues({'existing': 'preserved'}),
  );

  test('rapid saves preserve order and capture values at call time', () async {
    final store = PreferenceStore();
    final values = <String, Object?>{'events': 'first', 'minutes': 25};
    final first = store.save(values);
    values['events'] = 'changed after save';
    await first;
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('events'), 'first');
    await Future.wait([
      store.save({'events': 'second', 'dark': true}),
      store.save({'events': 'latest', 'dark': false}),
    ]);
    expect(prefs.getString('events'), 'latest');
    expect(prefs.getBool('dark'), false);
    expect(prefs.getInt('minutes'), 25);
    expect(prefs.getString('existing'), 'preserved');
  });

  test(
    'removing a preference and repeated saves preserve unrelated data',
    () async {
      final store = PreferenceStore();
      await store.save({'dark': true});
      await store.save({'dark': true});
      await store.save({'dark': null});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('dark'), false);
      expect(prefs.getString('existing'), 'preserved');
    },
  );

  test('a failed save does not block later saves', () async {
    final store = PreferenceStore();
    await expectLater(
      store.save({'unsupported': Object()}),
      throwsArgumentError,
    );
    await store.save({'events': 'recovered'});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('events'), 'recovered');
  });
}
