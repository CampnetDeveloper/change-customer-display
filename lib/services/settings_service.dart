import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

/// 設定保存・読み込みサービス
class SettingsService {
  static const String _settingsKey = 'pos_display_settings';

  /// 設定を保存
  Future<void> save(SettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, json);
      developer.log('設定保存完了', name: 'SettingsService');
    } catch (e, stackTrace) {
      developer.log(
        '設定保存エラー',
        error: e,
        stackTrace: stackTrace,
        name: 'SettingsService',
      );
    }
  }

  /// 設定を読み込み
  Future<SettingsModel> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_settingsKey);
      if (json != null) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        developer.log('設定読み込み完了', name: 'SettingsService');
        return SettingsModel.fromJson(map);
      }
    } catch (e, stackTrace) {
      developer.log(
        '設定読み込みエラー',
        error: e,
        stackTrace: stackTrace,
        name: 'SettingsService',
      );
    }
    // デフォルト設定を返す
    return const SettingsModel();
  }
}
