import 'game_state.dart';
import 'piece_generator.dart';

class ExplosionResult {
  final List<List<HexTile?>> board;
  final int pointsScored;
  final int newThreshold;

  const ExplosionResult({
    required this.board,
    required this.pointsScored,
    required this.newThreshold,
  });
}

class ExplosionEngine {
  static ExplosionResult process({
    required List<List<HexTile?>> board,
    required int row,
    required int col,
    required Piece piece,
    required int threshold,
  }) {
    final newBoard = _copyBoard(board);
    int points = 0;
    int newThreshold = threshold;

    if (piece.isSubtract) {
      // Minus piece: removes the piece from the board
      newBoard[row][col] = null;
      return ExplosionResult(
        board: newBoard,
        pointsScored: 0,
        newThreshold: newThreshold,
      );
    }

    // Number or plus piece: places and accumulates
    final currentTile = newBoard[row][col];
    final currentValue = currentTile?.value ?? 0;
    final newValue = currentValue + piece.value;

    // Checks if the new value exceeds the threshold → new threshold
    if (newValue > newThreshold) {
      newThreshold = newValue;
    }

    if (newValue >= threshold) {
      // Explodes!
      points += newValue;
      newBoard[row][col] = null;
      _accumulateNeighbours(newBoard, row, col, piece.value);
    } else {
      // Places the piece
      newBoard[row][col] = HexTile(row: row, col: col, value: newValue);
      if (piece.isSum) {
        // adds the piece value to the score
        points += piece.value;
      } else {
        // Accumulates to neighbors and the score
        points += _accumulateNeighboursAndScore(
          newBoard,
          row,
          col,
          piece.value,
        );
      }
    }

    // Chain explosions with multiplier
    int chainMultiplier = 2;
    bool anyExplosion = true;
    while (anyExplosion) {
      anyExplosion = false;
      for (int r = 0; r < GameState.rows; r++) {
        for (int c = 0; c < GameState.cols; c++) {
          final tile = newBoard[r][c];
          if (tile != null && tile.value >= threshold) {
            // Checks if it generates a new threshold
            if (tile.value > newThreshold && newThreshold == threshold) {
              newThreshold = tile.value;
            }
            points += tile.value * chainMultiplier;
            newBoard[r][c] = null;
            _accumulateNeighbours(newBoard, r, c, chainMultiplier);
            chainMultiplier++;
            anyExplosion = true;
            break;
          }
        }
        if (anyExplosion) break;
      }
    }

    return ExplosionResult(
      board: newBoard,
      pointsScored: points,
      newThreshold: newThreshold,
    );
  }

  static int _accumulateNeighboursAndScore(
    List<List<HexTile?>> board,
    int row,
    int col,
    int value,
  ) {
    int points = 0;
    for (final n in _getNeighbours(row, col)) {
      final r = n[0];
      final c = n[1];
      final tile = board[r][c];
      if (tile != null) {
        board[r][c] = HexTile(row: r, col: col, value: (tile.value) + value);
        points += value; // adds to the score
      }
    }
    return points;
  }

  static void _accumulateNeighbours(
    List<List<HexTile?>> board,
    int row,
    int col,
    int value,
  ) {
    for (final n in _getNeighbours(row, col)) {
      final r = n[0];
      final c = n[1];
      final tile = board[r][c];
      if (tile != null) {
        board[r][c] = HexTile(row: r, col: c, value: tile.value + value);
      }
    }
  }

  static List<List<int>> _getNeighbours(int row, int col) {
    final isOdd = row % 2 == 1;
    return [
          [row - 1, isOdd ? col : col - 1],
          [row - 1, isOdd ? col + 1 : col],
          [row, col - 1],
          [row, col + 1],
          [row + 1, isOdd ? col : col - 1],
          [row + 1, isOdd ? col + 1 : col],
        ]
        .where(
          (n) =>
              n[0] >= 0 &&
              n[0] < GameState.rows &&
              n[1] >= 0 &&
              n[1] < GameState.cols,
        )
        .toList();
  }

  static List<List<HexTile?>> _copyBoard(List<List<HexTile?>> board) {
    return List.generate(
      GameState.rows,
      (r) => List.generate(
        GameState.cols,
        (c) => board[r][c] == null
            ? null
            : HexTile(
                row: r,
                col: c,
                value: board[r][c]!.value,
                color: board[r][c]!.color,
              ),
      ),
    );
  }
}
