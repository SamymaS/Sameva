import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Mini-jeu Suite de nombres : trouver le terme manquant.
class NumbersGamePage extends StatefulWidget {
  const NumbersGamePage({super.key});

  @override
  State<NumbersGamePage> createState() => _NumbersGamePageState();
}

class _NumbersGamePageState extends State<NumbersGamePage> {
  static const _totalQuestions = 5;

  final _random = Random();

  int _questionIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;

  late _Question _current;

  @override
  void initState() {
    super.initState();
    _current = _generateQuestion();
  }

  _Question _generateQuestion() {
    final type = _random.nextInt(3);
    late List<int> terms;
    late int answer;
    late int missingIndex;

    switch (type) {
      case 0: // arithmétique
        final start = _random.nextInt(10) + 1;
        final step = _random.nextInt(5) + 2;
        terms = List.generate(5, (i) => start + i * step);
        missingIndex = _random.nextInt(5);
        answer = terms[missingIndex];
      case 1: // géométrique
        final start = _random.nextInt(3) + 1;
        final ratio = _random.nextInt(2) + 2;
        terms = List.generate(5, (i) => start * pow(ratio, i).toInt());
        missingIndex = _random.nextInt(5);
        answer = terms[missingIndex];
      case _: // dégressif
        final start = _random.nextInt(20) + 30;
        final step = _random.nextInt(4) + 2;
        terms = List.generate(5, (i) => start - i * step);
        missingIndex = _random.nextInt(5);
        answer = terms[missingIndex];
    }

    // 3 leurres
    final lures = <int>{};
    while (lures.length < 3) {
      final delta = _random.nextInt(10) - 5;
      final lure = answer + delta;
      if (lure != answer) lures.add(lure);
    }

    final choices = [...lures, answer]..shuffle(_random);

    return _Question(
      terms: terms,
      missingIndex: missingIndex,
      answer: answer,
      choices: choices,
    );
  }

  void _onAnswer(int value) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = value;
      _answered = true;
      if (value == _current.answer) _score++;
    });
    Future.delayed(const Duration(milliseconds: 900), _nextQuestion);
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_questionIndex + 1 >= _totalQuestions) {
      _showResult();
      return;
    }
    setState(() {
      _questionIndex++;
      _answered = false;
      _selectedAnswer = null;
      _current = _generateQuestion();
    });
  }

  void _showResult() {
    final gold = _score * 20;
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
            Text('Score : $_score / $_totalQuestions',
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
    final q = _current;
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text('Suite de nombres',
            style: TextStyle(
                color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('${_questionIndex + 1} / $_totalQuestions',
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text('Trouvez le terme manquant (?)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < q.terms.length; i++) ...[
                  _TermBox(
                    value: i == q.missingIndex ? null : q.terms[i],
                    highlight: i == q.missingIndex,
                  ),
                  if (i < q.terms.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('→',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 18)),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 48),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3,
              children: q.choices.map((c) {
                Color bg = AppColors.backgroundDarkPanel;
                if (_answered) {
                  if (c == q.answer) {
                    bg = AppColors.success;
                  } else if (c == _selectedAnswer) {
                    bg = AppColors.error;
                  }
                }
                return GestureDetector(
                  onTap: () => _onAnswer(c),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _answered && c == q.answer
                            ? AppColors.success
                            : AppColors.secondaryViolet.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: Text('$c',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_questionIndex + 1) / _totalQuestions,
              backgroundColor: AppColors.backgroundDarkPanel,
              color: AppColors.secondaryViolet,
            ),
          ],
        ),
      ),
    );
  }
}

class _TermBox extends StatelessWidget {
  final int? value;
  final bool highlight;

  const _TermBox({this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.secondaryViolet.withValues(alpha: 0.3)
            : AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? AppColors.secondaryViolet : AppColors.inputBorder,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          value != null ? '$value' : '?',
          style: TextStyle(
            color: highlight
                ? AppColors.secondaryVioletGlow
                : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _Question {
  final List<int> terms;
  final int missingIndex;
  final int answer;
  final List<int> choices;

  _Question({
    required this.terms,
    required this.missingIndex,
    required this.answer,
    required this.choices,
  });
}
