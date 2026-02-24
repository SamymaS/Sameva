import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Mini-jeu Séquence (Simon Says) : reproduire la séquence de couleurs.
class SequenceGamePage extends StatefulWidget {
  const SequenceGamePage({super.key});

  @override
  State<SequenceGamePage> createState() => _SequenceGamePageState();
}

class _SequenceGamePageState extends State<SequenceGamePage>
    with TickerProviderStateMixin {
  static const _buttons = [
    _ButtonDef(color: Color(0xFFE53E3E), icon: Icons.bolt, label: 'Rouge'),
    _ButtonDef(color: Color(0xFF4299E1), icon: Icons.water_drop, label: 'Bleu'),
    _ButtonDef(color: Color(0xFF48BB78), icon: Icons.eco, label: 'Vert'),
    _ButtonDef(color: Color(0xFFECC94B), icon: Icons.star, label: 'Jaune'),
  ];

  final _random = Random();
  late List<AnimationController> _glowControllers;
  late List<Animation<double>> _glowAnims;

  final List<int> _sequence = [];
  int _playerIndex = 0;
  bool _isShowing = false;
  bool _canInput = false;
  bool _gameOver = false;
  int _level = 0;

  @override
  void initState() {
    super.initState();
    _glowControllers = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _glowAnims = _glowControllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(c))
        .toList();
    Future.delayed(const Duration(milliseconds: 500), _nextLevel);
  }

  @override
  void dispose() {
    for (final c in _glowControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextLevel() {
    if (!mounted) return;
    _sequence.add(_random.nextInt(4));
    _level++;
    setState(() {
      _playerIndex = 0;
      _isShowing = true;
      _canInput = false;
    });
    _showSequence();
  }

  Future<void> _showSequence() async {
    for (int i = 0; i < _sequence.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      final idx = _sequence[i];
      _glowControllers[idx].forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _glowControllers[idx].reverse();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    setState(() {
      _isShowing = false;
      _canInput = true;
    });
  }

  void _onButtonTap(int index) {
    if (!_canInput || _gameOver) return;
    _glowControllers[index].forward(from: 0);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _glowControllers[index].reverse();
    });

    if (index == _sequence[_playerIndex]) {
      _playerIndex++;
      if (_playerIndex >= _sequence.length) {
        // Niveau réussi
        setState(() => _canInput = false);
        Future.delayed(const Duration(milliseconds: 600), _nextLevel);
      }
    } else {
      // Erreur
      setState(() {
        _canInput = false;
        _gameOver = true;
      });
      Future.delayed(const Duration(milliseconds: 400), _showResult);
    }
  }

  void _showResult() {
    if (!mounted) return;
    final reached = _level - 1; // niveau raté, on compte les réussis
    final gold = (reached * 15).clamp(0, 100);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: const Text('Jeu terminé !',
            style: TextStyle(color: AppColors.primaryTurquoise)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Niveau atteint : $reached',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.gold, size: 22),
                const SizedBox(width: 6),
                Text('+$gold or',
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryTurquoise),
            onPressed: () {
              if (gold > 0) {
                final player = context.read<PlayerProvider>();
                final auth = context.read<AuthProvider>();
                if (player.stats != null) {
                  player.addGold(auth.userId ?? '', gold);
                }
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
        title: const Text('Tap Séquence',
            style: TextStyle(
                color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('Niveau $_level',
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            _isShowing
                ? 'Observez la séquence...'
                : _canInput
                    ? 'À vous de reproduire !'
                    : _gameOver
                        ? 'Erreur !'
                        : '',
            style: TextStyle(
              color: _gameOver ? AppColors.error : AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: List.generate(4, (i) {
                final def = _buttons[i];
                return AnimatedBuilder(
                  animation: _glowAnims[i],
                  builder: (_, __) {
                    final glow = _glowAnims[i].value;
                    return GestureDetector(
                      onTap: () => _onButtonTap(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: def.color.withValues(
                              alpha: 0.3 + glow * 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: def.color,
                            width: 2 + glow * 3,
                          ),
                          boxShadow: glow > 0.1
                              ? [
                                  BoxShadow(
                                    color: def.color.withValues(alpha: glow * 0.6),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(def.icon, color: def.color, size: 36),
                            const SizedBox(height: 8),
                            Text(def.label,
                                style: TextStyle(
                                    color: def.color,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Séquence : ${_sequence.length} étapes',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonDef {
  final Color color;
  final IconData icon;
  final String label;

  const _ButtonDef(
      {required this.color, required this.icon, required this.label});
}
