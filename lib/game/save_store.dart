import 'package:shared_preferences/shared_preferences.dart';

/// Where saved games live. The default implementation uses the platform's
/// local key-value storage; tests use [MemorySaveStore].
abstract class SaveStore {
  Future<String?> read();
  Future<void> write(String json);
}

class PrefsSaveStore implements SaveStore {
  static const String key = 'eldrin.save.v1';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json);
  }
}

class MemorySaveStore implements SaveStore {
  String? _data;

  @override
  Future<String?> read() async => _data;

  @override
  Future<void> write(String json) async => _data = json;
}
