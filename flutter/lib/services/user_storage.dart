import 'package:shared_preferences/shared_preferences.dart';

/// ユーザーUUIDをローカルストレージで管理するクラス
class UserStorage {
  static const String _keyUserUuid = 'current_user_uuid';
  static const String _keyDisplaySteps = 'display_steps'; // 表示する歩数
  static const String _keyLastRecordedSteps =
      'last_recorded_steps'; // 直前に記録した歩数

  /// 現在のユーザーUUIDを保存
  static Future<void> saveUserUuid(String uuid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserUuid, uuid);
  }

  /// 現在のユーザーUUIDを取得
  static Future<String?> getUserUuid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserUuid);
  }

  /// 現在のユーザーUUIDをクリア
  static Future<void> clearUserUuid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserUuid);
  }

  /// ユーザーが登録されているかチェック
  static Future<bool> hasUser() async {
    final uuid = await getUserUuid();
    return uuid != null && uuid.isNotEmpty;
  }

  /// 表示する歩数を保存（計測中の歩数）
  static Future<void> saveDisplaySteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDisplaySteps, steps);
  }

  /// 表示する歩数を取得
  static Future<int?> getDisplaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDisplaySteps);
  }

  /// 表示する歩数をクリア
  static Future<void> clearDisplaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDisplaySteps);
  }

  /// 直前に記録した歩数を保存
  static Future<void> saveLastRecordedSteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastRecordedSteps, steps);
  }

  /// 直前に記録した歩数を取得
  static Future<int?> getLastRecordedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastRecordedSteps);
  }
}
