/// 表示モード
enum DisplayMode {
  slideshow, // 待機中（スライドショー）
  display, // 受信内容の表示
}

/// 表示タイプ（コマンドの種類）
enum DisplayType {
  none, // 未設定
  itemSubtotal, // 1: 商品個別小計
  total, // 2: 合計金額表示
  deposit, // 3: お預かり金額表示
  text, // 4: 文字列表示
}

/// 表示データモデル
class DisplayModel {
  final DisplayMode mode;
  final DisplayType type;
  final String titleText;
  final String mainAmountText;
  final Map<String, String> details;
  final DateTime lastReceivedAt;

  const DisplayModel({
    this.mode = DisplayMode.slideshow,
    this.type = DisplayType.none,
    this.titleText = '',
    this.mainAmountText = '',
    this.details = const {},
    required this.lastReceivedAt,
  });

  DisplayModel copyWith({
    DisplayMode? mode,
    DisplayType? type,
    String? titleText,
    String? mainAmountText,
    Map<String, String>? details,
    DateTime? lastReceivedAt,
  }) {
    return DisplayModel(
      mode: mode ?? this.mode,
      type: type ?? this.type,
      titleText: titleText ?? this.titleText,
      mainAmountText: mainAmountText ?? this.mainAmountText,
      details: details ?? this.details,
      lastReceivedAt: lastReceivedAt ?? this.lastReceivedAt,
    );
  }

  /// スライドショー状態を作成
  factory DisplayModel.slideshow() {
    return DisplayModel(
      mode: DisplayMode.slideshow,
      type: DisplayType.none,
      lastReceivedAt: DateTime.now(),
    );
  }

  /// 商品個別小計（コマンド1）
  factory DisplayModel.itemSubtotal({
    required String title,
    required String subtotal,
    required String itemName,
    required String quantity,
    required String itemPrice,
  }) {
    return DisplayModel(
      mode: DisplayMode.display,
      type: DisplayType.itemSubtotal,
      titleText: title,
      mainAmountText: subtotal,
      details: {
        '商品名': itemName,
        '数量': quantity,
        '商品金額': itemPrice,
      },
      lastReceivedAt: DateTime.now(),
    );
  }

  /// 合計金額（コマンド2）
  factory DisplayModel.total({
    required String title,
    required String total,
    required String discountLabel,
    required String discountAmount,
  }) {
    return DisplayModel(
      mode: DisplayMode.display,
      type: DisplayType.total,
      titleText: title,
      mainAmountText: total,
      details: {
        discountLabel: discountAmount,
      },
      lastReceivedAt: DateTime.now(),
    );
  }

  /// お預かり（コマンド3）
  factory DisplayModel.deposit({
    required String title,
    required String deposit,
    required String changeLabel,
    required String changeAmount,
  }) {
    return DisplayModel(
      mode: DisplayMode.display,
      type: DisplayType.deposit,
      titleText: title,
      mainAmountText: deposit,
      details: {
        changeLabel: changeAmount,
      },
      lastReceivedAt: DateTime.now(),
    );
  }

  /// 文字列表示（コマンド4）
  factory DisplayModel.text({
    required String billNo,
    required String posUid,
  }) {
    return DisplayModel(
      mode: DisplayMode.display,
      type: DisplayType.text,
      titleText: '',
      mainAmountText: '',
      details: {
        '伝票番号': billNo,
        'POS UID': posUid,
      },
      lastReceivedAt: DateTime.now(),
    );
  }
}
