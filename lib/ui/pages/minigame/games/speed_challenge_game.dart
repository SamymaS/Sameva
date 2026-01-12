import 'package:flutter/material.dart';
import 'dart:math';
import '../../../theme/app_colors.dart';

/// Speed Challenge - Jeu de rapidité
class SpeedChallengeGame extends StatefulWidget {
  const SpeedChallengeGame({super.key});

  @override
  State<SpeedChallengeGame> createState() => _SpeedChallengeGameState();
}

class _SpeedChallengeGameState extends State<SpeedChallengeGame> {
  int _score = 0;
  int _target = 0;
  int _timeLeft = 30;
  bool _isPlaying = false;
  bool _isGameOver = false;
  List<Color> _buttonColors = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateNewTarget();
  }

  void _generateNewTarget() {
    setState(() {
      _target = _random.nextInt(4);
      _buttonColors = List.generate(4, (index) {
        if (index == _target) {
          return AppColors.success;
        }
        return AppColors.error;
      });
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _timeLeft = 30;
    });
    _gameTimer();
  }

  void _gameTimer() {
    if (!_isPlaying || _isGameOver) return;
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isPlaying && !_isGameOver) {
        setState(() {
          _timeLeft--;
        });
        
        if (_timeLeft > 0) {
          _gameTimer();
        } else {
          _endGame();
        }
      }
    });
  }

  void _onButtonTap(int index) {
    if (!_isPlaying || _isGameOver) return;

    if (index == _target) {
      setState(() {
        _score += 10;
      });
      _generateNewTarget();
    } else {
      setState(() {
        _score = (_score - 5).clamp(0, double.infinity).toInt();
      });
    }
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
  }

  void _restart() {
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Speed Challenge'),
        backgroundColor: AppColors.success,
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
                    icon: Icons.timer,
                    label: 'Temps',
                    value: '$_timeLeft',
                    color: _timeLeft <= 10 ? AppColors.error : AppColors.primary,
                  ),
                  _InfoCard(
                    icon: Icons.star,
                    label: 'Score',
                    value: '$_score',
                    color: AppColors.legendary,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Instructions
              if (!_isPlaying && !_isGameOver)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Appuyez sur le bouton VERT le plus rapidement possible !',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vous avez 30 secondes pour marquer un maximum de points.',
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Commencer'),
                      ),
                    ],
                  ),
                ),
              
              // Grille de boutons
              if (_isPlaying || _isGameOver) ...[
                Expanded(
                  child: Center(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final isTarget = index == _target;
                        final color = _buttonColors[index];
                        
                        return GestureDetector(
                          onTap: () => _onButtonTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isTarget ? AppColors.success : AppColors.error,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isTarget ? Icons.check_circle : Icons.cancel,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              
              // Message de fin de jeu
              if (_isGameOver) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Temps écoulé !',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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









