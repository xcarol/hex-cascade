import 'dart:math';
import 'package:flame/components.dart';
import '../models/game_state.dart';
import 'hex_cell.dart';
import 'hex_game.dart';

/// Manages the hex grid: layout, tile generation, and board mutations.
class HexBoard extends Component {
  final List<List<HexCell?>> _components = List.generate(
    GameState.rows,
    (_) => List.filled(GameState.cols, null),
  );

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
        GameState.cols * HexCell.hexSize * sqrt(3) +
        HexCell.hexSize * sqrt(3) / 2;
    final totalH =
        GameState.rows * HexCell.hexSize * 1.5 +
        HexCell.hexSize * 0.5;

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

  void build() {
    _clearComponents();
    for (int r = 0; r < GameState.rows; r++) {
      for (int c = 0; c < GameState.cols; c++) {
        final color = TileColor.values[0];
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
    final pos = HexCell.positionFor(r, c, offset: gridOffset);
    final comp = HexCell(row: r, col: c, color: color, pos: pos);
    _components[r][c] = comp;
    add(comp);
  }
}
