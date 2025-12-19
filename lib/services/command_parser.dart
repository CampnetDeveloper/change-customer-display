import 'dart:developer' as developer;
import '../models/display_model.dart';

/// コマンドパースの結果
sealed class ParseResult {}

/// 表示コマンド（1/2/3/4）
class DisplayCommand extends ParseResult {
  final DisplayModel model;
  DisplayCommand(this.model);
}

/// クリアコマンド（9）
class ClearCommand extends ParseResult {}

/// 無効なコマンド（無視）
class InvalidCommand extends ParseResult {
  final String reason;
  InvalidCommand(this.reason);
}

/// コマンドパーサー
/// 受信したテキストを解析し、DisplayModelに変換する
class CommandParser {
  /// 複数行のテキストを解析（1メッセージに複数行が含まれる場合の対応）
  List<ParseResult> parseMultiLine(String message) {
    final lines = message.split('\n');
    return lines.map((line) => parseLine(line)).where((result) {
      if (result is InvalidCommand) {
        return result.reason.isNotEmpty;
      }
      return true;
    }).toList();
  }

  /// 1行を解析
  ParseResult parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return InvalidCommand('');
    }

    try {
      final tokens = trimmed.split('/');
      if (tokens.isEmpty) {
        return InvalidCommand('空のトークン');
      }

      final command = tokens[0];
      switch (command) {
        case '1':
          return _parseItemSubtotal(tokens);
        case '2':
          return _parseTotal(tokens);
        case '3':
          return _parseDeposit(tokens);
        case '4':
          return _parseText(tokens);
        case '9':
          return ClearCommand();
        default:
          return InvalidCommand('未知のコマンド: $command');
      }
    } catch (e, stackTrace) {
      developer.log(
        'コマンドパースエラー',
        error: e,
        stackTrace: stackTrace,
        name: 'CommandParser',
      );
      return InvalidCommand('パースエラー: $e');
    }
  }

  /// コマンド1: 商品個別小計
  /// フォーマット: 1/小計/小計金額/商品名/数量/商品金額
  ParseResult _parseItemSubtotal(List<String> tokens) {
    if (tokens.length < 6) {
      developer.log(
        '商品個別小計のトークン不足: ${tokens.length}個',
        name: 'CommandParser',
      );
      return InvalidCommand('商品個別小計のトークン不足');
    }

    return DisplayCommand(DisplayModel.itemSubtotal(
      title: tokens[1],
      subtotal: tokens[2],
      itemName: tokens[3],
      quantity: tokens[4],
      itemPrice: tokens[5],
    ));
  }

  /// コマンド2: 合計金額表示
  /// フォーマット: 2/合計/合計金額/割引/割引金額
  ParseResult _parseTotal(List<String> tokens) {
    if (tokens.length < 5) {
      developer.log(
        '合計金額のトークン不足: ${tokens.length}個',
        name: 'CommandParser',
      );
      return InvalidCommand('合計金額のトークン不足');
    }

    return DisplayCommand(DisplayModel.total(
      title: tokens[1],
      total: tokens[2],
      discountLabel: tokens[3],
      discountAmount: tokens[4],
    ));
  }

  /// コマンド3: お預かり金額表示
  /// フォーマット: 3/お預り/預かり金額/お釣り/釣り銭額
  ParseResult _parseDeposit(List<String> tokens) {
    if (tokens.length < 5) {
      developer.log(
        'お預かり金額のトークン不足: ${tokens.length}個',
        name: 'CommandParser',
      );
      return InvalidCommand('お預かり金額のトークン不足');
    }

    return DisplayCommand(DisplayModel.deposit(
      title: tokens[1],
      deposit: tokens[2],
      changeLabel: tokens[3],
      changeAmount: tokens[4],
    ));
  }

  /// コマンド4: 文字列表示
  /// フォーマット: 4/bill_no/pos_uid
  ParseResult _parseText(List<String> tokens) {
    if (tokens.length < 3) {
      developer.log(
        '文字列表示のトークン不足: ${tokens.length}個',
        name: 'CommandParser',
      );
      return InvalidCommand('文字列表示のトークン不足');
    }

    // URLデコードを試みる
    String billNo = tokens[1];
    String posUid = tokens[2];
    try {
      billNo = Uri.decodeComponent(billNo);
    } catch (_) {
      // デコード失敗時はそのまま使用
    }
    try {
      posUid = Uri.decodeComponent(posUid);
    } catch (_) {
      // デコード失敗時はそのまま使用
    }

    return DisplayCommand(DisplayModel.text(
      billNo: billNo,
      posUid: posUid,
    ));
  }
}
