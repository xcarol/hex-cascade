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
  static int _movesSinceRefill = 0;
  static const int _refillEvery = 3;
  static final Random _random = Random();
  static List<Piece> _bag = [];

  static Piece generate(
    List<List<HexTile?>> board,
    int moveCount,
    int threshold,
  ) {
    _movesSinceRefill++;
    if (_bag.isEmpty || _movesSinceRefill >= _refillEvery) {
      _refillBag(board, moveCount, threshold);
      _movesSinceRefill = 0;
    }

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
    final filledCells = board
        .expand((row) => row)
        .where((t) => t != null)
        .toList();
    final totalCells = board.length * board[0].length;
    final fillRatio = filledCells.length / totalCells;
    final dispersion = _boardDispersion(board);
    final organized = dispersion < threshold * 0.3;

    // Numbers: logarithmic growth
    final numberCount = _numberCount(fillRatio);
    final numbers = List.generate(
      numberCount,
      (_) => Piece(
        value: _numberValue(threshold, fillRatio),
        type: PieceType.number,
      ),
    );

    // Sums: more frequent when organized and there are tiles close to the threshold
    final sumCount = _sumCount(board, threshold, organized);
    final sums = List.generate(
      sumCount,
      (_) => Piece(value: _sumValue(threshold, organized), type: PieceType.sum),
    );

    // Subtracts: more frequent when the board is full and disorganized
    final subtractCount = _substractCount(fillRatio, organized);
    final subtracts = List.generate(
      subtractCount,
      (_) => Piece(value: 0, type: PieceType.subtract),
    );

    _bag = [...numbers, ...sums, ...subtracts];
  }

  // Dispersion: difference between maximum and minimum value of the board
  static double _boardDispersion(List<List<HexTile?>> board) {
    final values = board
        .expand((row) => row)
        .where((t) => t != null)
        .map((t) => t!.value)
        .toList();
    if (values.length < 2) return 0;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max - min).toDouble();
  }

  // Numbers: more when the board is empty (initial difficulty)
  // fewer when the board is full (to not block)
  static int _numberCount(double fillRatio) {
    if (fillRatio < 0.3) return 8; // empty board: many numbers
    if (fillRatio < 0.6) return 6; // middle: normal
    return 4; // full: fewer numbers
  }

  // Value of numbers: large when empty (difficult), small when full (manageable)
  // Logarithmic growth with respect to the threshold
  static int _numberValue(int threshold, double fillRatio) {
    final maxValue = (log(threshold) / log(10) * 3).round().clamp(
      1,
      threshold ~/ 3,
    );
    final minValue = (log(threshold) / log(10)).round().clamp(1, maxValue);

    if (fillRatio < 0.3) {
      // Empty board: large values
      final min = (maxValue * 0.6).round().clamp(minValue, maxValue);
      return min + _random.nextInt((maxValue - min + 1).clamp(1, maxValue));
    } else if (fillRatio < 0.6) {
      // Middle board: varied values between minimum and maximum
      return minValue +
          _random.nextInt((maxValue - minValue + 1).clamp(1, maxValue));
    } else {
      // Full board: values close to minimum
      final max = (maxValue * 0.6).round().clamp(minValue, maxValue);
      return minValue + _random.nextInt((max - minValue + 1).clamp(1, max));
    }
  }

  // Sums: more when organized and there are tiles close to the threshold
  static int _sumCount(
    List<List<HexTile?>> board,
    int threshold,
    bool organized,
  ) {
    final nearThreshold = board
        .expand((row) => row)
        .where((t) => t != null && t.value >= threshold * 0.7)
        .length;

    if (!organized) return 1; // disorganized: few sums
    return (2 + nearThreshold).clamp(2, 5); // organized: more sums
  }

  // Value of sums: useful when organized, small when disorganized
  static int _sumValue(int threshold, bool organized) {
    final max = (log(threshold) / log(10) * 2).round().clamp(1, threshold ~/ 4);
    if (!organized) return 1; // disorganized: small sums
    return _random.nextInt(max) + 1;
  }

  // Subtracts: more when full and disorganized
  static int _substractCount(double fillRatio, bool organized) {
    if (fillRatio < 0.7) return 0; // ← goes up from 0.5 to 0.7
    if (organized) return 1;
    return 2;
  }

  static void reset() {
    _bag = [];
    _movesSinceRefill = 0;
  }
}
