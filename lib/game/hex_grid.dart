import 'dart:math';
import 'package:flame/components.dart';
import '../models/game_state.dart';
import 'hex_tile_component.dart';
import 'cascade_engine.dart';
import 'hex_cascade_game.dart';

/// Manages the hex grid: layout, tile generation, and board mutations.
class HexGrid extends Component {
  final List<List<HexTileComponent?>> _components = List.generate(
    GameState.rows,
    (_) => List.filled(GameState.cols, null),
  );

  final Random _rng = Random();
  Vector2 gridOffset = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _calculateOffset();
  }

  void _calculateOffset() {
    // Centre the grid in the viewport, leaving room for HUD.
    final game = findGame() as HexCascadeGame;
    final vw = game.size.x;
    final vh = game.size.y;

    final totalW =
        GameState.cols * HexTileComponent.hexSize * sqrt(3) +
        HexTileComponent.hexSize * sqrt(3) / 2;
    final totalH =
        GameState.rows * HexTileComponent.hexSize * 1.5 +
        HexTileComponent.hexSize * 0.5;

    gridOffset = Vector2((vw - totalW) / 2, (vh - totalH) / 2 + 30);
  }

  void populateFromState(
    List<List<GameState?>> board,
    List<List<HexTile?>> stateTiles,
  ) {
    _clearComponents();
    for (int r = 0; r < GameState.rows; r++) {
      for (int c = 0; c < GameState.cols; c++) {
        final tile = stateTiles[r][c];
        if (tile != null) _addTile(r, c, tile.color);
      }
    }
  }

  void buildRandom() {
    _clearComponents();
    for (int r = 0; r < GameState.rows; r++) {
      for (int c = 0; c < GameState.cols; c++) {
        final color = TileColor.values[_rng.nextInt(TileColor.values.length)];
        _addTile(r, c, color);
      }
    }
  }

  void _clearComponents() {
    for (final row in _components) {
      for (final comp in row) {
        comp?.removeFromParent();
      }
      row.fillRange(0, row.length, null);
    }
  }

  void _addTile(int r, int c, TileColor color) {
    final pos = HexTileComponent.positionFor(r, c, offset: gridOffset);
    final comp = HexTileComponent(row: r, col: c, color: color, pos: pos);
    _components[r][c] = comp;
    add(comp);
  }

  /// Returns [GameState.board]-compatible tile matrix.
  List<List<HexTile?>> toStateTiles() {
    return List.generate(
      GameState.rows,
      (r) => List.generate(GameState.cols, (c) {
        final comp = _components[r][c];
        if (comp == null) return null;
        return HexTile(row: r, col: c, color: comp.color);
      }),
    );
  }

  /// Applies cascades from a tap at [row],[col].
  /// Returns score earned and whether anything changed.
  (int score, bool changed) handleTap(int row, int col) {
    final tiles = toStateTiles();
    final before = tiles[row][col];
    if (before == null) return (0, false);

    // Swap with a neighbor to trigger a potential cascade.
    final neighbors = _getNeighbors(row, col, GameState.rows, GameState.cols);
    if (neighbors.isEmpty) return (0, false);

    bool anyChange = false;
    int totalScore = 0;

    for (final (nr, nc) in neighbors) {
      if (tiles[nr][nc] == null) continue;
      // Swap colors.
      final tmp = tiles[row][col]!.color;
      tiles[row][col]!.color = tiles[nr][nc]!.color;
      tiles[nr][nc]!.color = tmp;

      final score = CascadeEngine.processCascades(tiles);
      if (score > 0) {
        totalScore += score;
        anyChange = true;
        break;
      } else {
        // Swap back.
        final tmp2 = tiles[row][col]!.color;
        tiles[row][col]!.color = tiles[nr][nc]!.color;
        tiles[nr][nc]!.color = tmp2;
      }
    }

    if (!anyChange) {
      // No match found — just try to remove a group at the tap position.
      final score = CascadeEngine.processCascades(tiles);
      if (score > 0) {
        totalScore += score;
        anyChange = true;
      }
    }

    if (anyChange) _syncFromTiles(tiles);
    return (totalScore, anyChange);
  }

  void _syncFromTiles(List<List<HexTile?>> tiles) {
    // Remove removed tiles.
    for (int r = 0; r < GameState.rows; r++) {
      for (int c = 0; c < GameState.cols; c++) {
        if (tiles[r][c] == null && _components[r][c] != null) {
          _components[r][c]!.removeFromParent();
          _components[r][c] = null;
        } else if (tiles[r][c] != null && _components[r][c] != null) {
          _components[r][c]!.color = tiles[r][c]!.color;
        } else if (tiles[r][c] != null && _components[r][c] == null) {
          _addTile(r, c, tiles[r][c]!.color);
        }
      }
    }
  }

  List<(int, int)> _getNeighbors(int r, int c, int rows, int cols) {
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

  void refillEmptyCells() {
    for (int r = 0; r < GameState.rows; r++) {
      for (int c = 0; c < GameState.cols; c++) {
        if (_components[r][c] == null) {
          final color = TileColor.values[_rng.nextInt(TileColor.values.length)];
          _addTile(r, c, color);
        }
      }
    }
  }
}
