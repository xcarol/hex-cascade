import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

const _kSaveKey = 'hex_cascade_save';

/// Handles saving and restoring game state locally.
/// On Android, `GamesService` can additionally persist to cloud snapshots.
class SaveService {
  static Future<void> saveGame(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSaveKey, state.toJson());
  }

  static Future<GameState?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_kSaveKey);
    if (data == null) return null;
    try {
      return GameState.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kSaveKey);
  }

  static Future<void> deleteSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSaveKey);
  }
}
