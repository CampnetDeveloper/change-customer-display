import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/display_model.dart';
import '../services/command_parser.dart';
import '../services/websocket_server.dart';

/// 表示状態を管理するProvider
class DisplayProvider extends ChangeNotifier {
  final WebSocketServerService _server = WebSocketServerService();
  final CommandParser _parser = CommandParser();
  Timer? _idleTimer;
  int _idleTimeoutSeconds = 60;

  DisplayModel _displayModel = DisplayModel.slideshow();

  /// 現在の表示モデル
  DisplayModel get displayModel => _displayModel;

  /// サーバーステータス
  ServerStatus get serverStatus => _server.status;

  /// サーバーポート
  int get serverPort => _server.port;

  /// 接続クライアント数
  int get clientCount => _server.clientCount;

  /// エラーメッセージ
  String? get errorMessage => _server.errorMessage;

  DisplayProvider() {
    _server.onMessage = _handleMessage;
    _server.onStatusChanged = (_) => notifyListeners();
  }

  /// サーバーを開始
  Future<void> startServer(int port) async {
    await _server.start(port);
    notifyListeners();
  }

  /// サーバーを停止
  Future<void> stopServer() async {
    await _server.stop();
    notifyListeners();
  }

  /// アイドルタイムアウトを設定
  void setIdleTimeout(int seconds) {
    _idleTimeoutSeconds = seconds;
  }

  /// メッセージを処理（WebSocket受信時およびプレビュー時に使用）
  void _handleMessage(String message) {
    developer.log('メッセージ処理: $message', name: 'DisplayProvider');

    // 複数行対応
    final results = _parser.parseMultiLine(message);
    for (final result in results) {
      _processParseResult(result);
    }
  }

  /// コマンドを直接処理（プレビュー用 - 同じロジックを使用）
  void processCommand(String command) {
    developer.log('プレビューコマンド: $command', name: 'DisplayProvider');
    _handleMessage(command);
  }

  /// パース結果を処理
  void _processParseResult(ParseResult result) {
    switch (result) {
      case DisplayCommand(:final model):
        _displayModel = model;
        _resetIdleTimer();
        notifyListeners();
        break;
      case ClearCommand():
        _displayModel = DisplayModel.slideshow();
        _cancelIdleTimer();
        notifyListeners();
        break;
      case InvalidCommand(:final reason):
        if (reason.isNotEmpty) {
          developer.log('無効なコマンド: $reason', name: 'DisplayProvider');
        }
        break;
    }
  }

  /// アイドルタイマーをリセット
  void _resetIdleTimer() {
    _cancelIdleTimer();
    _idleTimer = Timer(Duration(seconds: _idleTimeoutSeconds), () {
      developer.log('アイドルタイムアウト', name: 'DisplayProvider');
      _displayModel = DisplayModel.slideshow();
      notifyListeners();
    });
  }

  /// アイドルタイマーをキャンセル
  void _cancelIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// IPアドレスを取得
  Future<List<String>> getLocalIpAddresses() {
    return _server.getLocalIpAddresses();
  }

  /// スライドショーに戻す
  void toSlideshow() {
    _displayModel = DisplayModel.slideshow();
    _cancelIdleTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelIdleTimer();
    _server.stop();
    super.dispose();
  }
}
