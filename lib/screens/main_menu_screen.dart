import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';
import '../services/save_service.dart';
import '../services/games_service.dart';
import '../models/game_state.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  bool _hasSave = false;
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _init();
  }

  Future<void> _init() async {
    await GamesService.signIn();
    final has = await SaveService.hasSavedGame();
    if (mounted) setState(() => _hasSave = has);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _newGame() async {
    await SaveService.deleteSave();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(state: GameState())),
    );
  }

  Future<void> _continueGame() async {
    final state = await SaveService.loadGame() ?? GameState();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(state: state)),
    );
  }

  void _showLeaderboard() {
    if (!GamesService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les classificacions estan disponibles només en Android amb Google Play.',
          ),
        ),
      );
      return;
    }
    GamesService.showLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1A3550), Color(0xFF0D1B2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: _pulseAnim,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF64FFDA), Color(0xFF00B0FF)],
                    ).createShader(bounds),
                    child: const Text(
                      'HEX\nCASCADE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'PUZZLE GAME',
                  style: TextStyle(
                    color: Color(0xFF64FFDA),
                    fontSize: 14,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const Spacer(),
                _MenuButton(
                  label: 'NOVA PARTIDA',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _newGame,
                  primary: true,
                ),
                if (_hasSave) ...[
                  const SizedBox(height: 16),
                  _MenuButton(
                    label: 'CONTINUAR',
                    icon: Icons.restore_rounded,
                    onPressed: _continueGame,
                  ),
                ],
                const SizedBox(height: 16),
                _MenuButton(
                  label: 'CLASSIFICACIÓ',
                  icon: Icons.leaderboard_rounded,
                  onPressed: _showLeaderboard,
                ),
                if (UniversalPlatform.isDesktop) ...[
                  const SizedBox(height: 16),
                  _MenuButton(
                    label: 'SORTIR',
                    icon: Icons.exit_to_app_rounded,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? const Color(0xFF64FFDA)
              : Colors.white.withOpacity(0.08),
          foregroundColor: primary ? const Color(0xFF0D1B2A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: primary
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF64FFDA), width: 1),
          ),
          elevation: primary ? 6 : 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
