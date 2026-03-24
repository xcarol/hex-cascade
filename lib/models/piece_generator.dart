import 'dart:math';
import 'game_state.dart';

enum PieceType { normal, special, negative }

class Piece {
  final int value;
  final PieceType type;

  const Piece({required this.value, required this.type});

  bool get isNegative => type == PieceType.negative;
  bool get isSpecial => type == PieceType.special;
  bool get isNormal => type == PieceType.normal;

  Piece copy() => Piece(value: value, type: type);
}

class PieceGenerator {
  static final Random _random = Random();

  static Piece generate(
    List<List<HexTile?>> board,
    int moveCount,
    int threshold,
  ) {
    final filledCells = board
        .expand((row) => row)
        .where((tile) => tile != null)
        .toList();

    // Negativa: només si hi ha cel·les ocupades i entropia suficient
    if (filledCells.isNotEmpty &&
        _shouldGenerateNegative(filledCells, moveCount)) {
      return Piece(value: -(_random.nextInt(3) + 1), type: PieceType.negative);
    }

    // Especial: només si hi ha una cel·la que pot explotar
    if (filledCells.isNotEmpty &&
        _shouldGenerateSpecial(filledCells, threshold)) {
      final value = _specialValue(filledCells, threshold);
      if (value != null) {
        return Piece(value: value, type: PieceType.special);
      }
    }

    // Normal: sempre a cel·la buida
    return Piece(value: _random.nextInt(3) + 1, type: PieceType.normal);
  }

  static bool _shouldGenerateNegative(
    List<HexTile?> filledCells,
    int moveCount,
  ) {
    final entropyChance = (moveCount / 2).clamp(0, 40).toInt();
    return _random.nextInt(100) < entropyChance;
  }

  static bool _shouldGenerateSpecial(
    List<HexTile?> filledCells,
    int threshold,
  ) {
    final cellsNearThreshold = filledCells
        .where((t) => (t?.value ?? 0) >= threshold - 3)
        .length;
    return cellsNearThreshold > 0 && _random.nextInt(100) < 30;
  }

  static int? _specialValue(List<HexTile?> filledCells, int threshold) {
    final candidates = filledCells
        .map((t) => threshold - (t?.value ?? 0))
        .where((needed) => needed >= 1 && needed <= 3)
        .toList();
    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }
}
