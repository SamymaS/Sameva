import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../theme/app_colors.dart';

/// Mini-jeu Anagramme : reconstituer des mots fantaisie.
class AnagramGamePage extends StatefulWidget {
  const AnagramGamePage({super.key});

  @override
  State<AnagramGamePage> createState() => _AnagramGamePageState();
}

class _AnagramGamePageState extends State<AnagramGamePage> {
  static const _allWords = [
    'DRAGON',
    'MAGIE',
    'ELFE',
    'TROLL',
    'RUINE',
    'SORT',
    'ECLAT',
    'FORGE',
  ];
  static const _wordsPerGame = 3;

  final _random = Random();

  late List<String> _words;
  int _wordIndex = 0;
  int _score = 0;

  late List<String> _shuffled;
  final List<String> _answer = [];
  final List<bool> _used = [];
  bool _correct = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    final pool = List<String>.from(_allWords)..shuffle(_random);
    _words = pool.take(_wordsPerGame).toList();
    _setupWord();
  }

  void _setupWord() {
    final word = _words[_wordIndex];
    _shuffled = word.split('')..shuffle(_random);
    _answer.clear();
    _used.clear();
    _used.addAll(List.filled(_shuffled.length, false));
    _correct = false;
    _checked = false;
  }

  void _onLetterTap(int index) {
    if (_checked) return;
    if (_used[index]) {
      // Retirer la dernière lettre placée si elle correspond
      if (_answer.isNotEmpty) {
        final lastIdx = _used.lastIndexWhere((u) => u);
        if (lastIdx >= 0) {
          setState(() {
            _used[lastIdx] = false;
            _answer.removeLast();
          });
        }
      }
      return;
    }
    setState(() {
      _used[index] = true;
      _answer.add(_shuffled[index]);
    });
    if (_answer.length == _shuffled.length) {
      _checkAnswer();
    }
  }

  void _onRemoveLast() {
    if (_answer.isEmpty || _checked) return;
    final lastIdx = _used.lastIndexWhere((u) => u);
    if (lastIdx >= 0) {
      setState(() {
        _used[lastIdx] = false;
        _answer.removeLast();
      });
    }
  }

  void _checkAnswer() {
    final formed = _answer.join();
    final isCorrect = formed == _words[_wordIndex];
    setState(() {
      _checked = true;
      _correct = isCorrect;
      if (isCorrect) _score++;
    });
    Future.delayed(const Duration(milliseconds: 1000), _nextWord);
  }

  void _nextWord() {
    if (!mounted) return;
    if (_wordIndex + 1 >= _wordsPerGame) {
      _showResult();
      return;
    }
    setState(() {
      _wordIndex++;
      _setupWord();
    });
  }

  void _showResult() {
    final gold = _score * 30;
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
            Text('Mots trouvés : $_score / $_wordsPerGame',
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
        title: const Text('Anagramme',
            style: TextStyle(
                color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('${_wordIndex + 1} / $_wordsPerGame',
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text('Reconstituez le mot fantaisie',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // Zone réponse
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _checked
                    ? (_correct
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.2))
                    : AppColors.backgroundDarkPanel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _checked
                      ? (_correct ? AppColors.success : AppColors.error)
                      : AppColors.secondaryViolet.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: _answer
                          .map((l) => Text(l,
                              style: TextStyle(
                                  color: _checked
                                      ? (_correct
                                          ? AppColors.success
                                          : AppColors.error)
                                      : AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)))
                          .toList(),
                    ),
                  ),
                  if (_answer.isNotEmpty && !_checked)
                    IconButton(
                      onPressed: _onRemoveLast,
                      icon: const Icon(Icons.backspace_outlined,
                          color: AppColors.textMuted, size: 20),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Lettres mélangées
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(_shuffled.length, (i) {
                final used = _used[i];
                return GestureDetector(
                  onTap: () => _onLetterTap(i),
                  child: AnimatedOpacity(
                    opacity: used ? 0.3 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: used
                            ? AppColors.backgroundDarkPanel
                            : AppColors.secondaryViolet.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: used
                              ? AppColors.inputBorder
                              : AppColors.secondaryViolet,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _shuffled[i],
                          style: TextStyle(
                            color: used
                                ? AppColors.textMuted
                                : AppColors.secondaryVioletGlow,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            LinearProgressIndicator(
              value: (_wordIndex + 1) / _wordsPerGame,
              backgroundColor: AppColors.backgroundDarkPanel,
              color: AppColors.secondaryViolet,
            ),
          ],
        ),
      ),
    );
  }
}
