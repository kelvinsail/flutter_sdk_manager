import 'package:shared_preferences/shared_preferences.dart';

class SpManager {
  SpManager._internal();

  factory SpManager() => _instance;

  static late final SpManager _instance = SpManager._internal();

  final Future<SharedPreferencesWithCache> _prefs =
  SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions());

  ///保存字符串
  void setString(String key, String value) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    prefs.setString(key, value);
  }

  ///获取字符串
  Future<String?> getString(String key, {dynamic defaultValue}) async {
    final SharedPreferencesWithCache prefs = await _prefs;
    return prefs.getString(key) ?? defaultValue;
  }
}