import 'dart:math';
import 'game_state.dart';

enum PieceType { normal, special }

class Piece {
  final int value;
  final PieceType type;

  const Piece({required this.value, required this.type});

  bool get isSpecial => type == PieceType.special;
}

class PieceGenerator {
  static final Random _random = Random();

  static Piece generate(List<List<HexTile?>> board) {
    final filledCells = board
        .expand((row) => row)
        .where((tile) => tile != null)
        .length;
    final canBeSpecial = filledCells >= 5;
    final isSpecial = canBeSpecial && _random.nextInt(5) == 0;

    if (isSpecial) {
      return Piece(
        value: _random.nextInt(3) + 1, // +1, +2, +3
        type: PieceType.special,
      );
    }

    return Piece(
      value: _random.nextInt(3) + 1, // 1, 2, 3
      type: PieceType.normal,
    );
  }
}
