import 'package:flutter/material.dart';
import 'dart:math';
import '../../../theme/app_colors.dart';

/// Puzzle Quest - Jeu de puzzle (taquin)
class PuzzleQuestGame extends StatefulWidget {
  const PuzzleQuestGame({super.key});

  @override
  State<PuzzleQuestGame> createState() => _PuzzleQuestGameState();
}

class _PuzzleQuestGameState extends State<PuzzleQuestGame> {
  List<int> _puzzle = [];
  int _emptyIndex = 8;
  int _moves = 0;
  bool _isSolved = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializePuzzle();
  }

  void _initializePuzzle() {
    setState(() {
      _puzzle = List.generate(9, (index) => index);
      _moves = 0;
      _isSolved = false;
      _emptyIndex = 8;
    });
    _shufflePuzzle();
  }

  void _shufflePuzzle() {
    // Mélanger le puzzle (sans le dernier carré qui est vide)
    for (int i = 0; i < 100; i++) {
      final possibleMoves = _getPossibleMoves();
      if (possibleMoves.isNotEmpty) {
        final move = possibleMoves[_random.nextInt(possibleMoves.length)];
        _swapTiles(move);
      }
    }
    setState(() {
      _moves = 0;
    });
  }

  List<int> _getPossibleMoves() {
    final row = _emptyIndex ~/ 3;
    final col = _emptyIndex % 3;
    final moves = <int>[];

    if (row > 0) moves.add(_emptyIndex - 3); // Haut
    if (row < 2) moves.add(_emptyIndex + 3); // Bas
    if (col > 0) moves.add(_emptyIndex - 1); // Gauche
    if (col < 2) moves.add(_emptyIndex + 1); // Droite

    return moves;
  }

  void _swapTiles(int index) {
    final temp = _puzzle[index];
    _puzzle[index] = _puzzle[_emptyIndex];
    _puzzle[_emptyIndex] = temp;
    _emptyIndex = index;
  }

  void _onTileTap(int index) {
    if (_isSolved) return;

    final possibleMoves = _getPossibleMoves();
    if (possibleMoves.contains(index)) {
      setState(() {
        _swapTiles(index);
        _moves++;
        _checkWin();
      });
    }
  }

  void _checkWin() {
    bool isWin = true;
    for (int i = 0; i < 8; i++) {
      if (_puzzle[i] != i + 1) {
        isWin = false;
        break;
      }
    }
    
    if (isWin && _emptyIndex == 8) {
      setState(() {
        _isSolved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Puzzle Quest'),
        backgroundColor: AppColors.epic,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Informations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoCard(
                    icon: Icons.swap_horiz,
                    label: 'Mouvements',
                    value: '$_moves',
                    color: AppColors.primary,
                  ),
                  if (_isSolved)
                    _InfoCard(
                      icon: Icons.emoji_events,
                      label: 'Résolu !',
                      value: '✓',
                      color: AppColors.success,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Grille de puzzle
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        final value = _puzzle[index];
                        final isEmpty = index == _emptyIndex;
                        
                        return GestureDetector(
                          onTap: () => _onTileTap(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isEmpty 
                                  ? Colors.transparent
                                  : AppColors.primary.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isEmpty 
                                    ? Colors.transparent
                                    : AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: isEmpty
                                ? null
                                : Center(
                                    child: Text(
                                      '$value',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Boutons
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _initializePuzzle,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Mélanger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                  if (_isSolved)
                    ElevatedButton.icon(
                      onPressed: _initializePuzzle,
                      icon: const Icon(Icons.emoji_events),
                      label: const Text('Nouveau puzzle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}




