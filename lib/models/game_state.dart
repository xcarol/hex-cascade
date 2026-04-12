import 'dart:convert';
import 'piece_generator.dart';

enum TileColor { red, blue, green, yellow, purple, cyan }

class HexTile {
  final int row;
  final int col;
  final int value;
  final TileColor? color;

  HexTile({
    required this.row,
    required this.col,
    required this.value,
    this.color,
  });

  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
    'value': value,
    'color': color?.index,
  };

  factory HexTile.fromJson(Map<String, dynamic> json) => HexTile(
    row: json['row'] as int,
    col: json['col'] as int,
    value: json['value'] as int,
    color: json['color'] != null
        ? TileColor.values[json['color'] as int]
        : null,
  );

  HexTile copy() => HexTile(
        row: row,
        col: col,
        value: value,
        color: color,
      );
}

class GameState {
  int score;
  int explosionThreshold;
  int moveCount;
  List<List<HexTile?>> board;
  List<Piece?> rack;

  static const int rows = 5;
  static const int cols = 5;
  static const int rackSize = 1;

  GameState({
    this.score = 0,
    this.explosionThreshold = 10,
    this.moveCount = 0,
    List<List<HexTile?>>? board,
    List<Piece?>? rack,
  }) : board = board ?? _emptyBoard(),
       rack = rack ?? List.filled(rackSize, null) {
    PieceGenerator.reset();
    _fillRack();
  }

  static List<List<HexTile?>> _emptyBoard() => List.generate(
    rows, (r) => List.generate(cols, (c) => null),
  );

  bool get isBoardFull =>
    board.every((row) => row.every((tile) => tile != null));

  bool get isBoardEmpty =>
    board.every((row) => row.every((tile) => tile == null));

  void _fillRack() {
    for (int i = 0; i < rackSize; i++) {
      if (rack[i] == null) {
        rack[i] = PieceGenerator.generate(board, moveCount, explosionThreshold);
      }
    }
  }

  void playPiece(int rackIndex) {
    rack[rackIndex] = null;
    rack[rackIndex] = PieceGenerator.generate(board, moveCount, explosionThreshold);
    moveCount++;
  }

  String toJson() {
    final tiles = <Map<String, dynamic>>[];
    for (final row in board) {
      for (final tile in row) {
        if (tile != null) tiles.add(tile.toJson());
      }
    }
    return jsonEncode({
      'score': score,
      'explosionThreshold': explosionThreshold,
      'moveCount': moveCount,
      'tiles': tiles,
      'rack': rack.map((p) => p == null ? null : {
        'value': p.value,
        'type': p.type.index,
      }).toList(),
    });
  }

  factory GameState.fromJson(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final state = GameState(
      score: data['score'] as int,
      explosionThreshold: data['explosionThreshold'] as int,
      moveCount: data['moveCount'] as int,
    );
    for (final tileData in (data['tiles'] as List)) {
      final tile = HexTile.fromJson(tileData as Map<String, dynamic>);
      state.board[tile.row][tile.col] = tile;
    }
    final rackData = data['rack'] as List;
    for (int i = 0; i < rackData.length; i++) {
      if (rackData[i] != null) {
        state.rack[i] = Piece(
          value: rackData[i]['value'] as int,
          type: PieceType.values[rackData[i]['type'] as int],
        );
      }
    }
    return state;
  }
  GameStateSnapshot createSnapshot() {
    final boardCopy =
        board.map((row) => row.map((tile) => tile?.copy()).toList()).toList();
    final rackCopy = rack.map((p) => p?.copy()).toList();
    
    return GameStateSnapshot(
      score: score,
      explosionThreshold: explosionThreshold,
      moveCount: moveCount,
      board: boardCopy,
      rack: rackCopy,
    );
  }
}

class GameStateSnapshot {
  int score;
  int explosionThreshold;
  int moveCount;
  List<List<HexTile?>> board;
  List<Piece?> rack;

  GameStateSnapshot({
    required this.score,
    required this.explosionThreshold,
    required this.moveCount,
    required this.board,
    required this.rack,
  });
}
