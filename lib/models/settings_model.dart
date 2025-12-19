/// 文字色モード
enum TextColorMode {
  white,
  black,
}

/// 設定モデル
class SettingsModel {
  /// WebSocket待受ポート
  final int websocketPort;

  /// タイトルフォントサイズ
  final double titleFontSize;

  /// メイン金額フォントサイズ
  final double amountFontSize;

  /// 明細フォントサイズ
  final double detailFontSize;

  /// 太字を有効にするか
  final bool boldEnabled;

  /// 文字色モード
  final TextColorMode textColorMode;

  /// アイドルタイムアウト（秒）
  final int idleTimeoutSeconds;

  /// 画像表示秒数
  final int imageDurationSeconds;

  /// 動画最大秒数
  final int videoMaxSeconds;

  /// スライドショー用メディアパス
  final List<String> mediaPaths;

  const SettingsModel({
    this.websocketPort = 8765,
    this.titleFontSize = 48.0,
    this.amountFontSize = 120.0,
    this.detailFontSize = 32.0,
    this.boldEnabled = true,
    this.textColorMode = TextColorMode.white,
    this.idleTimeoutSeconds = 60,
    this.imageDurationSeconds = 5,
    this.videoMaxSeconds = 30,
    this.mediaPaths = const [],
  });

  SettingsModel copyWith({
    int? websocketPort,
    double? titleFontSize,
    double? amountFontSize,
    double? detailFontSize,
    bool? boldEnabled,
    TextColorMode? textColorMode,
    int? idleTimeoutSeconds,
    int? imageDurationSeconds,
    int? videoMaxSeconds,
    List<String>? mediaPaths,
  }) {
    return SettingsModel(
      websocketPort: websocketPort ?? this.websocketPort,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      amountFontSize: amountFontSize ?? this.amountFontSize,
      detailFontSize: detailFontSize ?? this.detailFontSize,
      boldEnabled: boldEnabled ?? this.boldEnabled,
      textColorMode: textColorMode ?? this.textColorMode,
      idleTimeoutSeconds: idleTimeoutSeconds ?? this.idleTimeoutSeconds,
      imageDurationSeconds: imageDurationSeconds ?? this.imageDurationSeconds,
      videoMaxSeconds: videoMaxSeconds ?? this.videoMaxSeconds,
      mediaPaths: mediaPaths ?? this.mediaPaths,
    );
  }

  /// 文字色を取得
  int get textColorValue {
    switch (textColorMode) {
      case TextColorMode.white:
        return 0xFFFFFFFF;
      case TextColorMode.black:
        return 0xFF000000;
    }
  }

  /// JSON変換（保存用）
  Map<String, dynamic> toJson() {
    return {
      'websocketPort': websocketPort,
      'titleFontSize': titleFontSize,
      'amountFontSize': amountFontSize,
      'detailFontSize': detailFontSize,
      'boldEnabled': boldEnabled,
      'textColorMode': textColorMode.index,
      'idleTimeoutSeconds': idleTimeoutSeconds,
      'imageDurationSeconds': imageDurationSeconds,
      'videoMaxSeconds': videoMaxSeconds,
      'mediaPaths': mediaPaths,
    };
  }

  /// JSONから復元
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      websocketPort: json['websocketPort'] ?? 8765,
      titleFontSize: (json['titleFontSize'] ?? 48.0).toDouble(),
      amountFontSize: (json['amountFontSize'] ?? 120.0).toDouble(),
      detailFontSize: (json['detailFontSize'] ?? 32.0).toDouble(),
      boldEnabled: json['boldEnabled'] ?? true,
      textColorMode: TextColorMode.values[json['textColorMode'] ?? 0],
      idleTimeoutSeconds: json['idleTimeoutSeconds'] ?? 60,
      imageDurationSeconds: json['imageDurationSeconds'] ?? 5,
      videoMaxSeconds: json['videoMaxSeconds'] ?? 30,
      mediaPaths: List<String>.from(json['mediaPaths'] ?? []),
    );
  }
}
