import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Mini-jeu Mémoire de sorts : 8 paires d'icônes à retrouver.
class MemoryGamePage extends StatefulWidget {
  const MemoryGamePage({super.key});

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage>
    with TickerProviderStateMixin {
  static const _icons = [
    Icons.bolt,
    Icons.local_fire_department,
    Icons.ac_unit,
    Icons.water_drop,
    Icons.eco,
    Icons.diamond,
    Icons.star,
    Icons.cloud,
  ];

  late final List<int> _board; // indices dans _icons (16 cartes = 8 paires)
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  final List<int> _flipped = []; // indices des cartes retournées (max 2)
  final Set<int> _matched = {}; // indices des cartes matchées
  int _moves = 0;
  bool _isChecking = false;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _board = _buildBoard();

    _controllers = List.generate(
      16,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _anims = _controllers
        .map((c) => Tween<double>(begin: 0, end: pi).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    _stopwatch.start();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _stopwatch.stop();
    super.dispose();
  }

  List<int> _buildBoard() {
    final pairs = [...List.generate(8, (i) => i), ...List.generate(8, (i) => i)];
    pairs.shuffle(Random());
    return pairs;
  }

  void _onCardTap(int cardIndex) {
    if (_isChecking) return;
    if (_matched.contains(cardIndex)) return;
    if (_flipped.contains(cardIndex)) return;
    if (_flipped.length >= 2) return;

    _controllers[cardIndex].forward();
    setState(() => _flipped.add(cardIndex));

    if (_flipped.length == 2) {
      setState(() => _isChecking = true);
      _moves++;
      _checkMatch();
    }
  }

  void _checkMatch() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final a = _flipped[0];
      final b = _flipped[1];

      if (_board[a] == _board[b]) {
        setState(() {
          _matched.addAll([a, b]);
          _flipped.clear();
          _isChecking = false;
        });
        if (_matched.length == 16) {
          _stopwatch.stop();
          _onWin();
        }
      } else {
        _controllers[a].reverse();
        _controllers[b].reverse();
        setState(() {
          _flipped.clear();
          _isChecking = false;
        });
      }
    });
  }

  void _onWin() {
    // Déclencher la boîte de dialogue de victoire
    final seconds = _stopwatch.elapsed.inSeconds;
    final gold = seconds < 60
        ? 100
        : seconds < 120
            ? 60
            : seconds < 180
                ? 30
                : 10;

    Hive.box('settings')
        .put('lastMemoryGameAt', DateTime.now().toIso8601String());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: const Text('Victoire !',
            style: TextStyle(color: AppColors.primaryTurquoise)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Temps : ${seconds}s · Coups : $_moves',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.gold, size: 22),
                const SizedBox(width: 6),
                Text(
                  '+$gold or',
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryTurquoise),
            onPressed: () {
              final player = context.read<PlayerProvider>();
              final auth = context.read<AuthProvider>();
              final userId = auth.userId ?? '';
              if (player.stats != null) {
                player.addGold(userId, gold);
              }
              Navigator.of(context)
                ..pop()
                ..pop();
            },
            child: const Text('Récupérer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Mémoire de sorts',
          style: TextStyle(
              color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  'Coups : $_moves',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${_matched.length ~/ 2} / 8 paires trouvées',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 16,
                itemBuilder: (_, i) => _CardTile(
                  index: i,
                  iconData: _icons[_board[i]],
                  isFlipped: _flipped.contains(i) || _matched.contains(i),
                  isMatched: _matched.contains(i),
                  animation: _anims[i],
                  onTap: () => _onCardTap(i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final int index;
  final IconData iconData;
  final bool isFlipped;
  final bool isMatched;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _CardTile({
    required this.index,
    required this.iconData,
    required this.isFlipped,
    required this.isMatched,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final angle = animation.value;
        final isFront = angle > pi / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: GestureDetector(
            onTap: isFlipped ? null : onTap,
            child: Container(
              decoration: BoxDecoration(
                color: isMatched
                    ? AppColors.primaryTurquoise.withValues(alpha: 0.2)
                    : isFront
                        ? AppColors.backgroundDeepViolet
                        : AppColors.backgroundDarkPanel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isMatched
                      ? AppColors.primaryTurquoise
                      : isFront
                          ? AppColors.secondaryViolet
                          : AppColors.inputBorder,
                  width: isMatched ? 2 : 1.5,
                ),
              ),
              child: isFront
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(pi),
                      child: Icon(
                        iconData,
                        color: isMatched
                            ? AppColors.primaryTurquoise
                            : AppColors.secondaryVioletGlow,
                        size: 32,
                      ),
                    )
                  : const Icon(
                      Icons.auto_fix_high,
                      color: AppColors.inputBorder,
                      size: 28,
                    ),
            ),
          ),
        );
      },
    );
  }
}
