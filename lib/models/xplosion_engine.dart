import 'game_state.dart';

class ExplosionResult {
  final List<List<HexTile?>> board;
  final int pointsScored;
  final bool placedTileConsumed;

  const ExplosionResult({
    required this.board,
    required this.pointsScored,
    required this.placedTileConsumed,
  });
}

class ExplosionEngine {
  static ExplosionResult process({
    required List<List<HexTile?>> board,
    required int row,
    required int col,
    required int value,
    required int threshold,
    bool isSpecial = false,
  }) {
    final newBoard = _copyBoard(board);
    int points = 0;
    bool consumed = false;

    if (isSpecial) {
      final tile = newBoard[row][col];
      if (tile != null) {
        newBoard[row][col] = HexTile(
          row: row,
          col: col,
          value: (tile.value ?? 0) + value,
          color: tile.color,
        );
      }
    } else {
      newBoard[row][col] = HexTile(row: row, col: col, value: value);
      _accumulateNeighbours(newBoard, row, col, value);
    }
    bool anyExplosion = true;
    while (anyExplosion) {
      anyExplosion = false;
      for (int r = 0; r < GameState.rows; r++) {
        for (int c = 0; c < GameState.cols; c++) {
          final tile = newBoard[r][c];
          if (tile != null && (tile.value ?? 0) >= threshold) {
            final originalValue = tile.value!;
            points += originalValue;
            newBoard[r][c] = null;
            if (r == row && c == col) consumed = true;
            newBoard[row][col] = null;
            _addOneToNeighbours(newBoard, r, c);
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
      placedTileConsumed: consumed,
    );
  }

  static void _addOneToNeighbours(
    List<List<HexTile?>> board,
    int row,
    int col,
  ) {
    for (final n in _getNeighbours(row, col)) {
      final r = n[0];
      final c = n[1];
      final tile = board[r][c];
      if (tile != null) {
        board[r][c] = HexTile(
          row: r,
          col: c,
          value: (tile.value ?? 0) + 1,
          color: tile.color,
        );
      }
    }
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
        board[r][c] = HexTile(
          row: r,
          col: c,
          value: value + (tile.value ?? 0),
          color: tile.color,
        );
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
