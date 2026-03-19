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
}

/// Full serialisable state of an in-progress game.
class GameState {
  int score;
  int level;
  int movesInLevel;
  List<List<HexTile?>> board;
  Piece? currentPiece;

  static const int rows = 7;
  static const int cols = 7;
  static const int explosionThreshold = 20;

  GameState({
    this.score = 0,
    this.level = 1,
    this.movesInLevel = 0,
    List<List<HexTile?>>? board,
  }) : board = board ?? _emptyBoard() {
    generateNextPiece();
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

  void generateNextPiece() {
    currentPiece = PieceGenerator.generate(board);
  }
}
