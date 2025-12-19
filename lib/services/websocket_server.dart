import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;

/// WebSocketサーバーの状態
enum ServerStatus {
  stopped,
  starting,
  running,
  error,
}

/// WebSocketサーバーサービス
/// AndroidがWebSocketサーバーとして待ち受け、iPadからの接続を受け付ける
class WebSocketServerService {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  ServerStatus _status = ServerStatus.stopped;
  int _port = 8765;
  String? _errorMessage;

  /// 現在のステータス
  ServerStatus get status => _status;

  /// 現在のポート
  int get port => _port;

  /// 接続中のクライアント数
  int get clientCount => _clients.length;

  /// エラーメッセージ
  String? get errorMessage => _errorMessage;

  /// メッセージ受信コールバック
  void Function(String message)? onMessage;

  /// ステータス変更コールバック
  void Function(ServerStatus status)? onStatusChanged;

  /// サーバーを開始
  Future<void> start(int port) async {
    if (_status == ServerStatus.running) {
      developer.log('サーバーは既に起動中です', name: 'WebSocketServer');
      return;
    }

    _port = port;
    _status = ServerStatus.starting;
    _errorMessage = null;
    onStatusChanged?.call(_status);

    try {
      // 0.0.0.0でバインドして全てのインターフェースからの接続を許可
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _status = ServerStatus.running;
      onStatusChanged?.call(_status);

      developer.log(
        'WebSocketサーバー開始: ポート $port',
        name: 'WebSocketServer',
      );

      _server!.listen(
        _handleRequest,
        onError: (error) {
          developer.log(
            'サーバーエラー',
            error: error,
            name: 'WebSocketServer',
          );
        },
        onDone: () {
          developer.log('サーバー停止', name: 'WebSocketServer');
          _status = ServerStatus.stopped;
          onStatusChanged?.call(_status);
        },
      );
    } catch (e, stackTrace) {
      developer.log(
        'サーバー開始エラー',
        error: e,
        stackTrace: stackTrace,
        name: 'WebSocketServer',
      );
      _status = ServerStatus.error;
      _errorMessage = e.toString();
      onStatusChanged?.call(_status);
    }
  }

  /// リクエストハンドラ
  void _handleRequest(HttpRequest request) async {
    try {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleWebSocket(socket);
      } else {
        // WebSocket以外のリクエストには簡易レスポンス
        request.response
          ..statusCode = HttpStatus.ok
          ..write('POS Display WebSocket Server')
          ..close();
      }
    } catch (e, stackTrace) {
      developer.log(
        'リクエスト処理エラー',
        error: e,
        stackTrace: stackTrace,
        name: 'WebSocketServer',
      );
    }
  }

  /// WebSocket接続ハンドラ
  void _handleWebSocket(WebSocket socket) {
    _clients.add(socket);
    developer.log(
      'クライアント接続: 現在 ${_clients.length} 台',
      name: 'WebSocketServer',
    );
    onStatusChanged?.call(_status);

    socket.listen(
      (data) {
        if (data is String) {
          developer.log('受信: $data', name: 'WebSocketServer');
          onMessage?.call(data);
        }
      },
      onError: (error) {
        developer.log(
          'WebSocketエラー',
          error: error,
          name: 'WebSocketServer',
        );
        _removeClient(socket);
      },
      onDone: () {
        developer.log('クライアント切断', name: 'WebSocketServer');
        _removeClient(socket);
      },
    );
  }

  /// クライアントを削除
  void _removeClient(WebSocket socket) {
    _clients.remove(socket);
    developer.log(
      'クライアント削除: 現在 ${_clients.length} 台',
      name: 'WebSocketServer',
    );
    onStatusChanged?.call(_status);
  }

  /// サーバーを停止
  Future<void> stop() async {
    for (final client in _clients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _clients.clear();

    await _server?.close();
    _server = null;
    _status = ServerStatus.stopped;
    onStatusChanged?.call(_status);

    developer.log('WebSocketサーバー停止', name: 'WebSocketServer');
  }

  /// サーバーを再起動
  Future<void> restart(int port) async {
    await stop();
    await start(port);
  }

  /// IPアドレスを取得
  Future<List<String>> getLocalIpAddresses() async {
    final addresses = <String>[];
    try {
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            addresses.add(addr.address);
          }
        }
      }
    } catch (e) {
      developer.log(
        'IPアドレス取得エラー',
        error: e,
        name: 'WebSocketServer',
      );
    }
    return addresses;
  }
}
