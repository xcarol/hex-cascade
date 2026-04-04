import 'dart:math';
import 'game_state.dart';

enum PieceType { number, sum, subtract }

class Piece {
  final int value;
  final PieceType type;

  const Piece({required this.value, required this.type});

  bool get isNumber => type == PieceType.number;
  bool get isSum => type == PieceType.sum;
  bool get isSubtract => type == PieceType.subtract;

  Piece copy() => Piece(value: value, type: type);
}

class PieceGenerator {
  static final Random _random = Random();
  static List<Piece> _bag = [];

  static Piece generate(
    List<List<HexTile?>> board,
    int moveCount,
    int threshold,
  ) {
    if (_bag.isEmpty) _refillBag(board, moveCount, threshold);
    final index = _random.nextInt(_bag.length);
    final piece = _bag[index];
    _bag.removeAt(index);
    return piece;
  }

  static void _refillBag(
    List<List<HexTile?>> board,
    int moveCount,
    int threshold,
  ) {
    final numberValue = _numberValue(threshold);
    final sumValue = _sumValue(threshold);
    final filledCells = board
        .expand((row) => row)
        .where((tile) => tile != null)
        .length;
    final totalCells = board.length * board[0].length;
    final fillRatio = filledCells / totalCells;

    // Base proportions: 6 numbers, 2 pluses, 1 minus
    final numbers = List.generate(6, (_) => Piece(
      value: numberValue,
      type: PieceType.number,
    ));

    // Pluses: more frequent when there are pieces close to the threshold
    final sumCount = _sumCount(board, threshold);
    final sums = List.generate(sumCount, (_) => Piece(
      value: sumValue,
      type: PieceType.sum,
    ));

    // Minuses: more frequent when the board is full and organized
    final subtractCount = _subtractCount(fillRatio);
    final subtracts = List.generate(subtractCount, (_) => Piece(
      value: 0,
      type: PieceType.subtract,
    ));

    _bag = [...numbers, ...sums, ...subtracts];
  }

  // Logarithmic growth of the value of numeric pieces
  static int _numberValue(int threshold) {
    final base = (log(threshold) / log(10) * 3).round().clamp(1, threshold ~/ 3);
    return _random.nextInt(base) + 1;
  }

  // Value of plus pieces: grows slower than the threshold
  static int _sumValue(int threshold) {
    final max = (log(threshold) / log(10) * 2).round().clamp(1, threshold ~/ 4);
    return _random.nextInt(max) + 1;
  }

  // More pluses when there are pieces close to the threshold
  static int _sumCount(List<List<HexTile?>> board, int threshold) {
    final nearThreshold = board
        .expand((row) => row)
        .where((t) => t != null && (t.value) >= threshold * 0.7)
        .length;
    return (2 + nearThreshold).clamp(2, 5);
  }

  // More minuses when the board is full
  static int _subtractCount(double fillRatio) {
    if (fillRatio < 0.5) return 0;
    if (fillRatio < 0.7) return 1;
    return 2;
  }

  static void reset() {
    _bag = [];
  }
}