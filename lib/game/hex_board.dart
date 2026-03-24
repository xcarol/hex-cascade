import 'dart:math';
import 'package:flame/components.dart';
import '../models/game_state.dart';
import 'hex_cell.dart';
import 'hex_game.dart';

/// Manages the hex grid: layout, tile generation, and board mutations.
class HexBoard extends Component {
  final void Function(int row, int col)? onCellTapped;

  HexBoard({this.onCellTapped});

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

    final w = HexCell.hexSize * sqrt(3);
    final horizontalTotal = (GameState.cols - 0.5) * w;
    final totalH =
        (GameState.rows - 1) * HexCell.hexSize * 1.5 + HexCell.hexSize * 2;
    gridOffset = Vector2((vw - horizontalTotal) / 2, (vh - totalH) / 2 + 30);
  }

  void setPlacementMode(PlacementMode mode) {
    for (final row in _components) {
      for (final cell in row) {
        cell?.placementMode = mode;
      }
    }
  }

  void populateFromState(List<List<HexTile?>> stateTiles) {
    _clearComponents();
    for (int r = 0; r < GameState.rows; r++) {
      for (int c = 0; c < GameState.cols; c++) {
        final tile = stateTiles[r][c];
        _addTile(r, c, value: tile?.value, color: tile?.color);
      }
    }
  }

  void build() {
    _clearComponents();
    for (int r = 0; r < GameState.rows; r++) {
      for (int c = 0; c < GameState.cols; c++) {
        _addTile(r, c);
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

  void _addTile(int r, int c, {int? value, TileColor? color}) {
    final pos = HexCell.positionFor(r, c, offset: gridOffset);
    final comp = HexCell(
      row: r,
      col: c,
      value: value,
      color: color,
      pos: pos,
      onTapped: onCellTapped,
    );
    _components[r][c] = comp;
    add(comp);
  }
}
