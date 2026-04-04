import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/piece_generator.dart';
import '../models/xplosion_engine.dart';
import '../services/games_service.dart';
import 'hex_board.dart';
import 'hex_cell.dart' show PlacementMode;

typedef ScoreCallback = void Function(int score, int threshold);
typedef GameOverCallback = void Function(int finalScore);
typedef RackCallback = void Function(List<Piece?> rack);

class HexCascadeGame extends FlameGame {
  final ScoreCallback? onScoreChanged;
  final GameOverCallback? onGameOver;
  final RackCallback? onRackChanged;

  final GameState state;
  late final HexBoard _hexGrid;
  int? _selectedRackIndex;
  final List<GameStateSnapshot> _history = [];

  HexCascadeGame({
    required this.state,
    this.onScoreChanged,
    this.onGameOver,
    this.onRackChanged,
  }) : super();

  @override
  Color backgroundColor() => const Color(0xFF0D1B2A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _hexGrid = HexBoard(onCellTapped: _onCellTapped);
    await add(_hexGrid);

    if (state.board.every((row) => row.every((t) => t == null))) {
      _hexGrid.build();
    } else {
      _hexGrid.populateFromState(state.board);
    }

    onRackChanged?.call(state.rack);
  }

  void selectRackPiece(int? rackIndex) {
    _selectedRackIndex = rackIndex;
    if (rackIndex == null) {
      _updatePlacementMode(null);
      return;
    }
    final piece = state.rack[rackIndex];
    if (piece == null) return;
    _updatePlacementMode(piece);
  }

  void _onCellTapped(int row, int col) {
    _saveState();
    if (_selectedRackIndex == null) return;
    final piece = state.rack[_selectedRackIndex!];
    if (piece == null) return;

    final tile = state.board[row][col];

    if (piece.isNumber) {
      if (tile != null) return;
      if (!state.isBoardEmpty && !_hasAdjacentTile(row, col)) return;
    }
    if (piece.isSum && tile == null && !_hasAdjacentTile(row, col)) return;
    if (piece.isSubtract && tile == null) return;

    final result = ExplosionEngine.process(
      board: state.board,
      row: row,
      col: col,
      piece: piece,
      threshold: state.explosionThreshold,
    );

    state.board = result.board;
    state.score += result.pointsScored;
    state.explosionThreshold = result.newThreshold;

    if (result.capturedTile != null) {
      state.rack[_selectedRackIndex!] = Piece(
        value: result.capturedTile!.value,
        type: PieceType.number,
      );
    } else {
      state.playPiece(_selectedRackIndex!);
    }

    _selectedRackIndex = null;
    onScoreChanged?.call(state.score, state.explosionThreshold);
    onRackChanged?.call(state.rack);
    _hexGrid.populateFromState(state.board);
    _updatePlacementMode(null);

    if (_isGameOver()) {
      onGameOver?.call(state.score);
    }
  }

  bool _hasAdjacentTile(int row, int col) {
    return _getNeighbours(row, col)
        .any((n) => state.board[n[0]][n[1]] != null);
  }

  List<List<int>> _getNeighbours(int row, int col) {
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

  bool _isGameOver() {
    if (!state.isBoardFull) return false;
    for (final piece in state.rack) {
      if (piece == null) continue;
      for (int r = 0; r < GameState.rows; r++) {
        for (int c = 0; c < GameState.cols; c++) {
          final tile = state.board[r][c];
          if (piece.isSubtract && tile != null) return false;
          if (piece.isSum && tile != null) return false;
        }
      }
    }
    return true;
  }

  void _updatePlacementMode(Piece? piece) {
    if (piece == null) {
      _hexGrid.setPlacementMode(PlacementMode.none);
      return;
    }
    if (piece.isNumber) {
      _hexGrid.setPlacementMode(PlacementMode.normalOccupied);
    } else if (piece.isSum) {
      _hexGrid.setPlacementMode(PlacementMode.special);
    } else {
      _hexGrid.setPlacementMode(PlacementMode.negative);
    }
  }

  Future<void> submitScore() async {
    await GamesService.submitScore(state.score);
  }

  void _saveState() {
    _history.add(state.createSnapshot());
    if (_history.length > 20) {
      _history.removeAt(0);
    }
  }

  bool canUndo() => _history.isNotEmpty;

  void undo() {
    if (_history.isEmpty) return;

    final snapshot = _history.removeLast();
    state.board = snapshot.board;
    state.score = snapshot.score;
    state.explosionThreshold = snapshot.explosionThreshold;
    state.moveCount = snapshot.moveCount;
    state.rack = snapshot.rack;

    onScoreChanged?.call(state.score, state.explosionThreshold);
    onRackChanged?.call(state.rack);
    _hexGrid.populateFromState(state.board);
  }
}

