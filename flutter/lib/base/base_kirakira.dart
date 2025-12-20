import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/user_storage.dart';
import '../models/symbol.dart';

/// キラキラレベル管理用のミックスイン
/// SharedPreferencesを使ってローカルにキラキラレベルを保存・読み込み
mixin KirakiraLevelMixin<T extends StatefulWidget> on State<T> {
  static const String _keyKirakiraLevel = 'kirakira_level';

  int _kirakiraLevel = 0;

  int get kirakiraLevel => _kirakiraLevel;

  /// キラキラレベルを読み込み
  Future<void> loadKirakiraLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt(_keyKirakiraLevel) ?? 0;
    if (mounted) {
      setState(() {
        _kirakiraLevel = level;
      });
    }
  }

  /// キラキラレベルを保存
  Future<void> saveKirakiraLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyKirakiraLevel, level);
    if (mounted) {
      setState(() {
        _kirakiraLevel = level;
      });
    }
  }

  /// キラキラレベルをリセット（0に設定）
  Future<void> resetKirakiraLevel() async {
    await saveKirakiraLevel(0);
  }

  /// キラキラレベルをサーバーに同期
  /// ユーザーのシンボルを取得してキラキラレベルを更新
  Future<void> syncKirakiraLevelToServer({
    required int level,
    bool showSuccessMessage = false,
    String? successMessage,
  }) async {
    try {
      final userUuid = await UserStorage.getUserUuid();
      if (userUuid == null) {
        throw Exception('ユーザーが登録されていません');
      }

      // ユーザーのシンボルを取得
      final userSymbols = await ApiService.getSymbolsByUser(userUuid: userUuid);
      if (userSymbols.symbols.isEmpty) {
        throw Exception('シンボルが見つかりません');
      }

      final symbol = userSymbols.symbols.first;

      // キラキラレベルを更新
      await ApiService.updateSymbol(
        symbol.uuid,
        SymbolUpdateRequest(kirakiraLevel: level),
      );

      // ローカルに保存
      await saveKirakiraLevel(level);

      if (mounted && showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage ?? 'キラキラレベルが${level}になりました！')),
        );
      }
    } catch (e) {
      debugPrint('キラキラレベルの更新に失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
      rethrow;
    }
  }

  /// キラキラレベルをインクリメントしてサーバーに同期
  Future<void> incrementAndSyncKirakiraLevel({
    bool showSuccessMessage = true,
  }) async {
    final newLevel = _kirakiraLevel + 1;
    await syncKirakiraLevelToServer(
      level: newLevel,
      showSuccessMessage: showSuccessMessage,
      successMessage: 'キラキラレベルが${newLevel}になりました！',
    );
  }

  /// キラキラレベルが最大値を超えていないかチェックし、超えていたら修正
  Future<void> fixKirakiraLevelIfExceedsMax({
    int maxLevel = 2,
    bool showMessage = true,
  }) async {
    if (_kirakiraLevel > maxLevel) {
      debugPrint('キラキラレベルが${_kirakiraLevel}になっているため、${maxLevel}に修正します');
      await syncKirakiraLevelToServer(
        level: maxLevel,
        showSuccessMessage: showMessage,
        successMessage: 'キラキラレベルを最大値($maxLevel)に修正しました',
      );
    }
  }

  /// キラキラレベルが最大値に達しているかチェック
  bool isKirakiraLevelMax({int maxLevel = 2}) {
    return _kirakiraLevel >= maxLevel;
  }
}

/// キラキラレベル管理用のユーティリティクラス（StatefulWidget以外で使用）
class KirakiraLevelService {
  static const String _keyKirakiraLevel = 'kirakira_level';

  /// キラキラレベルを読み込み
  static Future<int> loadKirakiraLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyKirakiraLevel) ?? 0;
  }

  /// キラキラレベルを保存
  static Future<void> saveKirakiraLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyKirakiraLevel, level);
  }

  /// キラキラレベルをリセット（0に設定）
  static Future<void> resetKirakiraLevel() async {
    await saveKirakiraLevel(0);
  }

  /// キラキラレベルをサーバーに同期
  static Future<void> syncKirakiraLevelToServer(int level) async {
    final userUuid = await UserStorage.getUserUuid();
    if (userUuid == null) {
      throw Exception('ユーザーが登録されていません');
    }

    // ユーザーのシンボルを取得
    final userSymbols = await ApiService.getSymbolsByUser(userUuid: userUuid);
    if (userSymbols.symbols.isEmpty) {
      throw Exception('シンボルが見つかりません');
    }

    final symbol = userSymbols.symbols.first;

    // キラキラレベルを更新
    await ApiService.updateSymbol(
      symbol.uuid,
      SymbolUpdateRequest(kirakiraLevel: level),
    );

    // ローカルに保存
    await saveKirakiraLevel(level);
  }
}
