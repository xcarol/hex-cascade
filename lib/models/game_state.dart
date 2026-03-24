import 'dart:convert';

import 'package:hex_cascade/models/piece_generator.dart';

/// Colours available for hex tiles.
enum TileColor { red, blue, green, yellow, purple, cyan }

/// A single tile on the board.
class HexTile {
  final int row;
  final int col;
  final int? value;
  final TileColor? color;
  final bool isEmpty;

  HexTile({
    required this.row,
    required this.col,
    this.value,
    this.color,
    this.isEmpty = false,
  });

  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
    'value': value,
    'color': color?.index,
    'isEmpty': isEmpty,
  };

  factory HexTile.fromJson(Map<String, dynamic> json) => HexTile(
    row: json['row'] as int,
    col: json['col'] as int,
    value: json['value'] as int?,
    color: json['color'] != null
        ? TileColor.values[json['color'] as int]
        : null,
    isEmpty: json['isEmpty'] as bool,
  );

  HexTile copy() => HexTile(
        row: row,
        col: col,
        value: value,
        color: color,
        isEmpty: isEmpty,
      );
}

/// Full serialisable state of an in-progress game.
class GameState {
  int score;
  int level;
  int movesInLevel;
  List<List<HexTile?>> board;
  Piece? currentPiece;
  int moveCount = 0;

  static const int rows = 5;
  static const int cols = 5;
  static const int baseThreshold = 10;

  GameState({
    this.score = 0,
    this.level = 1,
    this.movesInLevel = 0,
    List<List<HexTile?>>? board,
  }) : board = board ?? _emptyBoard() {
    generateNextPiece();
  }

  int get explosionThreshold => baseThreshold + (level - 1) * 5;

  bool get isBoardEmpty {
    return board.every((row) => row.every((tile) => tile == null));
  }

  static List<List<HexTile?>> _emptyBoard() =>
      List.generate(rows, (r) => List.generate(cols, (c) => null));

  String toJson() {
    final tiles = <Map<String, dynamic>>[];
    for (final row in board) {
      for (final tile in row) {
        if (tile != null) tiles.add(tile.toJson());
      }
    }
    return jsonEncode({
      'score': score,
      'level': level,
      'movesInLevel': movesInLevel,
      'tiles': tiles,
    });
  }

  factory GameState.fromJson(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final state = GameState(
      score: data['score'] as int,
      level: data['level'] as int,
      movesInLevel: data['movesInLevel'] as int,
    );
    for (final tileData in (data['tiles'] as List)) {
      final tile = HexTile.fromJson(tileData as Map<String, dynamic>);
      state.board[tile.row][tile.col] = tile;
    }
    return state;
  }

  bool get isBoardFull {
    return board.every((row) => row.every((tile) => tile != null));
  }

  void generateNextPiece() {
    currentPiece = PieceGenerator.generate(board, moveCount);
  }

  GameStateSnapshot createSnapshot() {
    final boardCopy =
        board.map((row) => row.map((tile) => tile?.copy()).toList()).toList();
    return GameStateSnapshot(
      board: boardCopy,
      score: score,
      level: level,
      currentPiece: currentPiece?.copy(),
      moveCount: moveCount,
    );
  }
}

class GameStateSnapshot {
  final List<List<HexTile?>> board;
  final int score;
  final int level;
  final Piece? currentPiece;
  final int moveCount;

  GameStateSnapshot({
    required this.board,
    required this.score,
    required this.level,
    this.currentPiece,
    required this.moveCount,
  });
}
