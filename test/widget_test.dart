import 'package:flutter_test/flutter_test.dart';
import 'package:pos_display/services/command_parser.dart';
import 'package:pos_display/models/display_model.dart';

void main() {
  group('CommandParser', () {
    final parser = CommandParser();

    test('parses item subtotal command correctly', () {
      final result = parser.parseLine('1/小計/1,280円/みかんジェラート/640×2ケ/1,240円');
      expect(result, isA<DisplayCommand>());
      final cmd = result as DisplayCommand;
      expect(cmd.model.type, DisplayType.itemSubtotal);
      expect(cmd.model.titleText, '小計');
      expect(cmd.model.mainAmountText, '1,280円');
      expect(cmd.model.details['商品名'], 'みかんジェラート');
    });

    test('parses total command correctly', () {
      final result = parser.parseLine('2/合計/9,120円/割引/200円');
      expect(result, isA<DisplayCommand>());
      final cmd = result as DisplayCommand;
      expect(cmd.model.type, DisplayType.total);
      expect(cmd.model.mainAmountText, '9,120円');
    });

    test('parses deposit command correctly', () {
      final result = parser.parseLine('3/お預かり/10,120円/お釣り/1,000円');
      expect(result, isA<DisplayCommand>());
      final cmd = result as DisplayCommand;
      expect(cmd.model.type, DisplayType.deposit);
    });

    test('parses text command correctly', () {
      final result = parser.parseLine('4/123456789/POS_TEST_001');
      expect(result, isA<DisplayCommand>());
      final cmd = result as DisplayCommand;
      expect(cmd.model.type, DisplayType.text);
      expect(cmd.model.details['伝票番号'], '123456789');
      expect(cmd.model.details['POS UID'], 'POS_TEST_001');
    });

    test('parses clear command correctly', () {
      final result = parser.parseLine('9/表示クリア');
      expect(result, isA<ClearCommand>());
    });

    test('handles multiline messages', () {
      final results = parser.parseMultiLine('1/小計/100円/商品/1個/100円\n2/合計/100円/割引/0円');
      expect(results.length, 2);
      expect(results[0], isA<DisplayCommand>());
      expect(results[1], isA<DisplayCommand>());
    });

    test('returns InvalidCommand for unknown commands', () {
      final result = parser.parseLine('5/unknown');
      expect(result, isA<InvalidCommand>());
    });

    test('ignores empty lines', () {
      final results = parser.parseMultiLine('\n\n');
      expect(results.isEmpty, true);
    });
  });
}
