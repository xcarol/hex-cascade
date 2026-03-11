import 'package:universal_platform/universal_platform.dart';
import 'package:games_services/games_services.dart';

/// Replace these with your real Google Play Console IDs.
const _kLeaderboardId = 'YOUR_LEADERBOARD_ID';

/// Platform-aware wrapper around the `games_services` plugin.
/// On non-Android platforms all methods are no-ops.
class GamesService {
  static bool get _isSupported => UniversalPlatform.isAndroid;

  static bool _signedIn = false;

  static Future<bool> signIn() async {
    if (!_isSupported) return false;
    try {
      await GamesServices.signIn();
      _signedIn = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool get isSignedIn => _signedIn && _isSupported;

  static Future<void> submitScore(int score) async {
    if (!isSignedIn) return;
    try {
      await GamesServices.submitScore(
        score: Score(
          iOSLeaderboardID: '',
          androidLeaderboardID: _kLeaderboardId,
          value: score,
        ),
      );
    } catch (_) {}
  }

  static Future<void> showLeaderboard() async {
    if (!isSignedIn) return;
    try {
      await GamesServices.showLeaderboards(
        iOSLeaderboardID: '',
        androidLeaderboardID: _kLeaderboardId,
      );
    } catch (_) {}
  }

  /// Saves a game snapshot to Google Play cloud.
  static Future<void> saveSnapshot(String data) async {
    if (!isSignedIn) return;
    try {
      await SaveGame.saveGame(data: data, name: 'hex_cascade_save');
    } catch (_) {}
  }

  /// Loads the last saved snapshot from Google Play cloud.
  static Future<String?> loadSnapshot() async {
    if (!isSignedIn) return null;
    try {
      return await SaveGame.loadGame(name: 'hex_cascade_save');
    } catch (_) {
      return null;
    }
  }
}
