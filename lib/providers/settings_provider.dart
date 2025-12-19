import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';

/// 設定を管理するProvider
class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();
  SettingsModel _settings = const SettingsModel();
  bool _isLoaded = false;

  /// 現在の設定
  SettingsModel get settings => _settings;

  /// 読み込み済みか
  bool get isLoaded => _isLoaded;

  /// 設定を読み込み
  Future<void> load() async {
    _settings = await _service.load();
    _isLoaded = true;
    notifyListeners();
  }

  /// 設定を更新して保存
  Future<void> update(SettingsModel settings) async {
    _settings = settings;
    await _service.save(settings);
    notifyListeners();
  }

  /// WebSocketポートを更新
  Future<void> updatePort(int port) async {
    await update(_settings.copyWith(websocketPort: port));
  }

  /// タイトルフォントサイズを更新
  Future<void> updateTitleFontSize(double size) async {
    await update(_settings.copyWith(titleFontSize: size));
  }

  /// 金額フォントサイズを更新
  Future<void> updateAmountFontSize(double size) async {
    await update(_settings.copyWith(amountFontSize: size));
  }

  /// 明細フォントサイズを更新
  Future<void> updateDetailFontSize(double size) async {
    await update(_settings.copyWith(detailFontSize: size));
  }

  /// 太字設定を更新
  Future<void> updateBoldEnabled(bool enabled) async {
    await update(_settings.copyWith(boldEnabled: enabled));
  }

  /// 文字色モードを更新
  Future<void> updateTextColorMode(TextColorMode mode) async {
    await update(_settings.copyWith(textColorMode: mode));
  }

  /// アイドルタイムアウトを更新
  Future<void> updateIdleTimeout(int seconds) async {
    await update(_settings.copyWith(idleTimeoutSeconds: seconds));
  }

  /// 画像表示秒数を更新
  Future<void> updateImageDuration(int seconds) async {
    await update(_settings.copyWith(imageDurationSeconds: seconds));
  }

  /// 動画最大秒数を更新
  Future<void> updateVideoMaxSeconds(int seconds) async {
    await update(_settings.copyWith(videoMaxSeconds: seconds));
  }

  /// メディアパスを更新
  Future<void> updateMediaPaths(List<String> paths) async {
    await update(_settings.copyWith(mediaPaths: paths));
  }

  /// メディアパスを追加
  Future<void> addMediaPath(String path) async {
    final newPaths = [..._settings.mediaPaths, path];
    await update(_settings.copyWith(mediaPaths: newPaths));
  }

  /// メディアパスを削除
  Future<void> removeMediaPath(String path) async {
    final newPaths = _settings.mediaPaths.where((p) => p != path).toList();
    await update(_settings.copyWith(mediaPaths: newPaths));
  }
}
