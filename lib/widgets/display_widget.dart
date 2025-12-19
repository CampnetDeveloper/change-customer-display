import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/display_model.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';

/// 受信内容を表示するウィジェット（横向き最適化）
class DisplayWidget extends StatelessWidget {
  final DisplayModel displayModel;

  const DisplayWidget({
    super.key,
    required this.displayModel,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final textColor = Color(settings.textColorValue);
    final fontWeight = settings.boldEnabled ? FontWeight.bold : FontWeight.normal;

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: _buildContent(context, settings, textColor, fontWeight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SettingsModel settings, Color textColor, FontWeight fontWeight) {
    switch (displayModel.type) {
      case DisplayType.itemSubtotal:
        return _buildItemSubtotalLayout(settings, textColor, fontWeight);
      case DisplayType.total:
        return _buildTotalLayout(settings, textColor, fontWeight);
      case DisplayType.deposit:
        return _buildDepositLayout(settings, textColor, fontWeight);
      case DisplayType.text:
        return _buildTextLayout(settings, textColor, fontWeight);
      case DisplayType.none:
        return const SizedBox.shrink();
    }
  }

  /// 商品個別小計レイアウト（横向き：左に金額、右に商品情報）
  Widget _buildItemSubtotalLayout(SettingsModel settings, Color textColor, FontWeight fontWeight) {
    final itemName = displayModel.details['商品名'] ?? '';
    final quantity = displayModel.details['数量'] ?? '';
    final itemPrice = displayModel.details['商品金額'] ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 左側：小計金額
        Expanded(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayModel.titleText,
                style: TextStyle(
                  fontSize: settings.titleFontSize,
                  fontWeight: fontWeight,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  displayModel.mainAmountText,
                  style: TextStyle(
                    fontSize: settings.amountFontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 区切り線
        Container(
          width: 2,
          height: 150,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          color: textColor.withValues(alpha: 0.3),
        ),
        // 右側：商品情報
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemName,
                style: TextStyle(
                  fontSize: settings.detailFontSize * 1.3,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                quantity,
                style: TextStyle(
                  fontSize: settings.detailFontSize,
                  fontWeight: fontWeight,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                itemPrice,
                style: TextStyle(
                  fontSize: settings.detailFontSize * 1.2,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 合計金額レイアウト（横並び：左に合計、右に割引）
  Widget _buildTotalLayout(SettingsModel settings, Color textColor, FontWeight fontWeight) {
    final discountEntry = displayModel.details.entries.firstOrNull;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 左側：合計金額
        Expanded(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayModel.titleText,
                style: TextStyle(
                  fontSize: settings.titleFontSize,
                  fontWeight: fontWeight,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  displayModel.mainAmountText,
                  style: TextStyle(
                    fontSize: settings.amountFontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 右側：割引（目立つ赤枠）
        if (discountEntry != null)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(left: 24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    discountEntry.key,
                    style: TextStyle(
                      fontSize: settings.titleFontSize * 0.8,
                      fontWeight: fontWeight,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '-${discountEntry.value}',
                      style: TextStyle(
                        fontSize: settings.amountFontSize * 0.7,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// お預かりレイアウト（横向き：左にお預かり、右にお釣り - 両方大きく）
  Widget _buildDepositLayout(SettingsModel settings, Color textColor, FontWeight fontWeight) {
    final changeEntry = displayModel.details.entries.firstOrNull;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 左側：お預かり
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayModel.titleText,
                style: TextStyle(
                  fontSize: settings.titleFontSize,
                  fontWeight: fontWeight,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  displayModel.mainAmountText,
                  style: TextStyle(
                    fontSize: settings.amountFontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 中央：矢印
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Icon(
            Icons.arrow_forward,
            size: 48,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
        // 右側：お釣り（大きく目立つように）
        if (changeEntry != null)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    changeEntry.key,
                    style: TextStyle(
                      fontSize: settings.titleFontSize,
                      fontWeight: fontWeight,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      changeEntry.value,
                      style: TextStyle(
                        fontSize: settings.amountFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 文字列表示レイアウト（中央揃え）
  Widget _buildTextLayout(SettingsModel settings, Color textColor, FontWeight fontWeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: displayModel.details.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${entry.key}: ',
                style: TextStyle(
                  fontSize: settings.detailFontSize,
                  fontWeight: fontWeight,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              Text(
                entry.value,
                style: TextStyle(
                  fontSize: settings.detailFontSize * 1.3,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
