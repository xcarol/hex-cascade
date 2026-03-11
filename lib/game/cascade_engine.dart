import 'dart:collection';
import '../models/game_state.dart';

/// Finds connected groups of same-colour tiles (BFS) and removes them if
/// they form a group of [minGroupSize] or more, then drops tiles down.
class CascadeEngine {
  static const int minGroupSize = 3;

  /// Processes the board:  finds groups → removes → drops → returns score.
  static int processCascades(List<List<HexTile?>> board) {
    int totalScore = 0;
    bool found = true;

    while (found) {
      found = false;
      final groups = _findAllGroups(board);
      final toRemove = groups.where((g) => g.length >= minGroupSize).toList();

      if (toRemove.isEmpty) {
        break;
      }
      found = true;

      for (final group in toRemove) {
        final bonus = group.length * group.length; // size-squared bonus
        totalScore += bonus;
        for (final pos in group) {
          board[pos.$1][pos.$2] = null;
        }
      }

      // Drop tiles downward to fill gaps.
      _dropTiles(board);
    }

    return totalScore;
  }

  static List<List<(int, int)>> _findAllGroups(List<List<HexTile?>> board) {
    final visited = <(int, int)>{};
    final groups = <List<(int, int)>>[];

    for (int r = 0; r < board.length; r++) {
      for (int c = 0; c < board[r].length; c++) {
        final tile = board[r][c];
        if (tile == null || tile.isEmpty || visited.contains((r, c))) continue;

        final group = _bfs(board, r, c, tile.color, visited);
        if (group.isNotEmpty) groups.add(group);
      }
    }
    return groups;
  }

  static List<(int, int)> _bfs(
    List<List<HexTile?>> board,
    int startR,
    int startC,
    TileColor color,
    Set<(int, int)> visited,
  ) {
    final queue = Queue<(int, int)>();
    final group = <(int, int)>[];

    queue.add((startR, startC));
    visited.add((startR, startC));

    while (queue.isNotEmpty) {
      final (r, c) = queue.removeFirst();
      group.add((r, c));

      for (final (nr, nc) in _hexNeighbors(
        r,
        c,
        board.length,
        board[0].length,
      )) {
        if (visited.contains((nr, nc))) continue;
        final neighbor = board[nr][nc];
        if (neighbor == null || neighbor.isEmpty || neighbor.color != color)
          continue;

        visited.add((nr, nc));
        queue.add((nr, nc));
      }
    }
    return group;
  }

  /// Returns valid hex neighbours for offset coordinates (odd-r layout).
  static List<(int, int)> _hexNeighbors(int r, int c, int rows, int cols) {
    final List<(int, int)> dirs;
    if (r % 2 == 0) {
      dirs = [(-1, -1), (-1, 0), (0, -1), (0, 1), (1, -1), (1, 0)];
    } else {
      dirs = [(-1, 0), (-1, 1), (0, -1), (0, 1), (1, 0), (1, 1)];
    }
    return dirs
        .map((d) => (r + d.$1, c + d.$2))
        .where((p) => p.$1 >= 0 && p.$1 < rows && p.$2 >= 0 && p.$2 < cols)
        .toList();
  }

  /// Drops tiles downward column by column to fill empty cells.
  static void _dropTiles(List<List<HexTile?>> board) {
    final rows = board.length;
    final cols = board[0].length;

    for (int c = 0; c < cols; c++) {
      // Collect non-null tiles in the column (bottom-to-top).
      final tiles = <HexTile>[];
      for (int r = rows - 1; r >= 0; r--) {
        if (board[r][c] != null) tiles.add(board[r][c]!);
      }
      // Re-fill from bottom.
      for (int r = rows - 1; r >= 0; r--) {
        final idx = rows - 1 - r;
        board[r][c] = idx < tiles.length ? tiles[idx] : null;
      }
    }
  }
}
