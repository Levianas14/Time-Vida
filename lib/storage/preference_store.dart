import 'package:shared_preferences/shared_preferences.dart';

/// Serializes saves and skips unchanged values, preserving existing storage keys.
class PreferenceStore {
  Future<void> _pending = Future<void>.value();

  Future<void> save(Map<String, Object?> values) {
    final snapshot = Map<String, Object?>.unmodifiable(values);
    final operation = _pending.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in snapshot.entries) {
        if (prefs.get(entry.key) == entry.value) continue;
        final bool saved;
        switch (entry.value) {
          case null:
            saved = await prefs.remove(entry.key);
          case final String value:
            saved = await prefs.setString(entry.key, value);
          case final bool value:
            saved = await prefs.setBool(entry.key, value);
          case final int value:
            saved = await prefs.setInt(entry.key, value);
          default:
            throw ArgumentError.value(entry.value, entry.key);
        }
        if (!saved) throw StateError('Não foi possível salvar ${entry.key}.');
      }
    });
    // A failed write must not prevent subsequent saves from being attempted.
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return operation;
  }
}
