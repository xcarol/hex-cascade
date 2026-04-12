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
    final sumCount = _sumCount(board, threshold, organized, fillRatio);
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

  static int _numberValue(int threshold, double fillRatio) {
    if (fillRatio < 0.3) {
      // Empty board: force larger numbers to pressure the player to organize
      int maxVal = (threshold * 0.7).round().clamp(1, threshold - 1);
      int minVal = (threshold * 0.4).round().clamp(1, maxVal);
      return minVal + _random.nextInt((maxVal - minVal + 1));
    } else if (fillRatio > 0.6) {
      // Full board: allow smaller numbers to fit them and avoid blocking
      int maxVal = (threshold * 0.35).round().clamp(1, threshold ~/ 2);
      if (maxVal < 1) maxVal = 1;
      return 1 + _random.nextInt(maxVal); // Minimum 1 logic is implicit
    } else {
      // Middle or intermediate filling
      int maxVal = (threshold * 0.5).round().clamp(1, threshold - 2);
      int minVal = (threshold * 0.15).round().clamp(1, maxVal);
      return minVal + _random.nextInt((maxVal - minVal + 1));
    }
  }

  // Sums: appear later when the board is fuller, and scale with tiles near the limit
  static int _sumCount(
    List<List<HexTile?>> board,
    int threshold,
    bool organized,
    double fillRatio,
  ) {
    if (fillRatio < 0.35) return 0; // Delay appearance of sum pieces

    // 'the higher the probability of an explosion' -> we have tiles near the threshold
    final nearThreshold = board
        .expand((row) => row)
        .where((t) => t != null && t.value >= threshold * 0.7)
        .length;

    int baseCount = (fillRatio >= 0.7) ? 2 : 1;
    // The more pieces near the limit and fuller the board, the more sum pieces we give
    return (baseCount + nearThreshold).clamp(1, 5);
  }

  // Value of sums: useful when organized, small when disorganized
  static int _sumValue(int threshold, bool organized) {
    // Sub-linear growth like numbers, but lower values
    var maxVal = pow(threshold, 0.6).round().clamp(1, threshold ~/ 4);
    // Avoid full clamping to 1 if maxVal hits 0 in rare conditions
    if (maxVal < 1) maxVal = 1;
    
    if (!organized) {
      maxVal = (maxVal * 0.5).round().clamp(1, maxVal); // Half maximum when disorganized (not strictly 1)
    }
    return _random.nextInt(maxVal) + 1;
  }

  // Subtracts: more when full and organized
  static int _substractCount(double fillRatio, bool organized) {
    if (fillRatio < 0.6) return 0; // Only when starting to get full
    
    int count = 1; // Base case when full
    if (fillRatio > 0.8) count++; // More full -> more subtracts to survive
    
    // 'they should tend to appear when the board is fuller and better organized'
    if (organized) {
      count++; // Bonus subtracts when organized
    }
    return count;
  }

  static void reset() {
    _bag = [];
    _movesSinceRefill = 0;
  }
}
