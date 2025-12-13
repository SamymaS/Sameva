import 'package:flutter/material.dart';
import 'dart:math';
import 'app_colors.dart';

/// Memory Quest - Jeu de mémoire
class MemoryQuestGame extends StatefulWidget {
  const MemoryQuestGame({super.key});

  @override
  State<MemoryQuestGame> createState() => _MemoryQuestGameState();
}

class _MemoryQuestGameState extends State<MemoryQuestGame> {
  List<int> _sequence = [];
  List<int> _playerSequence = [];
  int _level = 1;
  bool _isShowingSequence = false;
  int _currentSequenceIndex = 0; // Index de la tuile actuellement affichée
  bool _isGameOver = false;
  bool _isGameWon = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _startNewLevel();
  }

  void _startNewLevel() {
    setState(() {
      _sequence.clear();
      _playerSequence.clear();
      _isGameOver = false;
      _isGameWon = false;
      
      // Générer la séquence pour ce niveau
      final random = Random();
      for (int i = 0; i < _level + 2; i++) {
        _sequence.add(random.nextInt(4));
      }
      
      _isShowingSequence = true;
    });
    
    // Afficher la séquence
    _showSequence();
  }

  Future<void> _showSequence() async {
    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      
      setState(() {
        _currentSequenceIndex = i;
        _isShowingSequence = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (!mounted) return;
      
      setState(() {
        _isShowingSequence = false;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (mounted) {
      setState(() {
        _isShowingSequence = false;
        _currentSequenceIndex = -1;
      });
    }
  }

  void _onTileTap(int index) {
    if (_isShowingSequence || _isGameOver || _isGameWon) return;

    setState(() {
      _playerSequence.add(index);
    });

    // Vérifier si la séquence est correcte
    if (_playerSequence.length <= _sequence.length) {
      if (_playerSequence[_playerSequence.length - 1] != _sequence[_playerSequence.length - 1]) {
        // Mauvaise réponse
        _gameOver();
      } else if (_playerSequence.length == _sequence.length) {
        // Niveau complété
        _levelComplete();
      }
    }
  }

  void _levelComplete() {
    setState(() {
      _score += _level * 10;
      _level++;
      _playerSequence.clear();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startNewLevel();
      }
    });
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
    });
  }

  void _restart() {
    setState(() {
      _level = 1;
      _score = 0;
      _isGameOver = false;
      _isGameWon = false;
    });
    _startNewLevel();
  }

  Color _getTileColor(int index) {
    final colors = [
      const Color(0xFF60A5FA), // Bleu
      const Color(0xFF22C55E), // Vert
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFA855F7), // Violet
    ];
    
    final baseColor = colors[index];
    
    // Si on affiche la séquence, vérifier si cette tuile doit être active
    if (_isShowingSequence && 
        _currentSequenceIndex >= 0 && 
        _currentSequenceIndex < _sequence.length &&
        _sequence[_currentSequenceIndex] == index) {
      return baseColor; // Tuile active dans la séquence
    }
    
    return baseColor.withOpacity(0.2); // Tuile inactive
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Memory Quest'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Informations du jeu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoCard(
                    icon: Icons.star,
                    label: 'Niveau',
                    value: '$_level',
                    color: AppColors.legendary,
                  ),
                  _InfoCard(
                    icon: Icons.emoji_events,
                    label: 'Score',
                    value: '$_score',
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Grille de jeu
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final isActive = _isShowingSequence && 
                            _currentSequenceIndex >= 0 &&
                            _currentSequenceIndex < _sequence.length &&
                            _sequence[_currentSequenceIndex] == index;
                        
                        return GestureDetector(
                          onTap: () => _onTileTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _getTileColor(index),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive ? Colors.white : AppColors.border,
                                width: isActive ? 3 : 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.circle,
                                size: 40,
                                color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Messages de fin de jeu
              if (_isGameOver) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Game Over!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score final: $_score',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _restart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Rejouer'),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (_isShowingSequence && !_isGameOver) ...[
                const SizedBox(height: 16),
                const Text(
                  'Regardez la séquence...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
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

