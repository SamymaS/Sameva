import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Mini-jeu Réaction rapide : toucher 10 cibles dans le temps imparti.
class ReactionGamePage extends StatefulWidget {
  const ReactionGamePage({super.key});

  @override
  State<ReactionGamePage> createState() => _ReactionGamePageState();
}

class _ReactionGamePageState extends State<ReactionGamePage>
    with SingleTickerProviderStateMixin {
  static const _totalTargets = 10;
  static const _timeoutSeconds = 1.5;

  final _random = Random();
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  int _hits = 0;
  int _current = 0; // index de la cible en cours (0-9)
  bool _active = false;
  bool _finished = false;

  Offset _targetPos = Offset.zero;
  Timer? _timeoutTimer;
  final List<int> _reactionTimes = [];
  final Stopwatch _targetStopwatch = Stopwatch();

  double _areaWidth = 300;
  double _areaHeight = 400;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    Future.microtask(_startGame);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _hits = 0;
      _current = 0;
      _active = true;
      _finished = false;
      _reactionTimes.clear();
    });
    _showNextTarget();
  }

  void _showNextTarget() {
    if (!mounted) return;
    const margin = 30.0;
    _targetPos = Offset(
      margin + _random.nextDouble() * (_areaWidth - margin * 2),
      margin + _random.nextDouble() * (_areaHeight - margin * 2),
    );
    _scaleController.forward(from: 0);
    _targetStopwatch
      ..reset()
      ..start();

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(
      Duration(milliseconds: (_timeoutSeconds * 1000).round()),
      _onTimeout,
    );
    setState(() {});
  }

  void _onTimeout() {
    if (!mounted || !_active) return;
    _reactionTimes.add((_timeoutSeconds * 1000).round()); // penalité max
    _nextOrFinish();
  }

  void _onHit() {
    if (!_active || _finished) return;
    _timeoutTimer?.cancel();
    _targetStopwatch.stop();
    _reactionTimes.add(_targetStopwatch.elapsedMilliseconds);
    _hits++;
    _nextOrFinish();
  }

  void _nextOrFinish() {
    _current++;
    if (_current >= _totalTargets) {
      setState(() {
        _active = false;
        _finished = true;
      });
      _showResult();
    } else {
      _showNextTarget();
    }
  }

  void _showResult() {
    final gold = _hits * 10;
    final avgMs = _reactionTimes.isEmpty
        ? 0
        : _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        title: const Text('Résultat',
            style: TextStyle(color: AppColors.primaryTurquoise)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cibles touchées : $_hits / $_totalTargets',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Temps moyen : ${avgMs}ms',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
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
        title: const Text(
          'Réaction rapide',
          style: TextStyle(
              color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '$_current / $_totalTargets',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Touchez les cibles dès qu\'elles apparaissent !',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                _areaWidth = constraints.maxWidth;
                _areaHeight = constraints.maxHeight;
                return Stack(
                  children: [
                    Container(color: AppColors.backgroundNightBlue),
                    if (_active)
                      Positioned(
                        left: _targetPos.dx - 28,
                        top: _targetPos.dy - 28,
                        child: ScaleTransition(
                          scale: _scaleAnim,
                          child: GestureDetector(
                            onTap: _onHit,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryViolet,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondaryViolet
                                        .withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.flash_on,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
