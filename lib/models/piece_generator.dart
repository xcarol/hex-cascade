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

  static Piece generate(List<List<HexTile?>> board, int moveCount) {
    final filledCells = board
        .expand((row) => row)
        .where((tile) => tile != null)
        .toList();

    final canBeSpecial = filledCells.length >= 5;

    if (canBeSpecial && _shouldGenerateSpecial(filledCells, moveCount)) {
      return Piece(
        value: _specialValue(filledCells),
        type: PieceType.special,
      );
    }

    return Piece(
      value: _normalValue(filledCells, moveCount),
      type: PieceType.normal,
    );
  }

  static bool _shouldGenerateSpecial(List<HexTile?> filledCells, int moveCount) {
    final highValueCells = filledCells
        .where((t) => (t?.value ?? 0) >= 12)
        .length;
    final baseChance = (highValueCells * 2).clamp(0, 20);
    return _random.nextInt(100) < baseChance;
  }

  static int _specialValue(List<HexTile?> filledCells) {
    final maxValue = filledCells
        .map((t) => t?.value ?? 0)
        .reduce((a, b) => a > b ? a : b);

    final needed = 20 - maxValue;
    if (needed <= 3 && needed >= 1) return needed;
    return _random.nextInt(3) + 1;
  }

  static int _normalValue(List<HexTile?> filledCells, int moveCount) {
    final randomness = (moveCount / 30).clamp(0.0, 1.0);

    if (filledCells.isEmpty || _random.nextDouble() < randomness) {
      return _random.nextInt(3) + 1;
    }

    final avg = filledCells
        .map((t) => t?.value ?? 0)
        .reduce((a, b) => a + b) / filledCells.length;

    final avgRounded = avg.round().clamp(1, 3);

    final offset = _random.nextInt(3) - 1;
    return (avgRounded + offset).clamp(1, 3);
  }
}
