import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/app_colors.dart';

/// Mini-jeu runner/endless
class RunnerGame extends StatefulWidget {
  const RunnerGame({super.key});

  @override
  State<RunnerGame> createState() => _RunnerGameState();
}

class _RunnerGameState extends State<RunnerGame> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Position du joueur
  double _playerY = 300;
  bool _isJumping = false;
  double _jumpVelocity = 0;
  
  // Obstacles
  List<Obstacle> _obstacles = [];
  double _obstacleSpeed = 3;
  
  // Score
  int _score = 0;
  int _distance = 0;
  bool _gameOver = false;
  
  // Dimensions
  final double _gameWidth = 400;
  final double _gameHeight = 500;
  final double _playerSize = 40;
  final double _gravity = 0.8;
  final double _jumpStrength = -18;
  final double _groundY = 450;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_gameLoop);
    _controller.repeat();
  }
  
  void _gameLoop() {
    if (_gameOver) return;
    
    setState(() {
      // Gravité et saut
      _jumpVelocity += _gravity;
      _playerY += _jumpVelocity;
      
      // Collision avec le sol
      if (_playerY >= _groundY - _playerSize) {
        _playerY = _groundY - _playerSize;
        _jumpVelocity = 0;
        _isJumping = false;
      }
      
      // Générer des obstacles
      if (_obstacles.isEmpty || _obstacles.last.x < _gameWidth - 200) {
        _obstacles.add(Obstacle(_gameWidth, _groundY - 30));
      }
      
      // Déplacer les obstacles
      _obstacles.removeWhere((obstacle) {
        obstacle.x -= _obstacleSpeed;
        
        // Collision avec le joueur
        if (_checkCollision(obstacle)) {
          _gameOver = true;
          _controller.stop();
          return true;
        }
        
        // Supprimer les obstacles hors écran
        if (obstacle.x < -50) {
          _score += 10;
          return true;
        }
        
        return false;
      });
      
      // Augmenter la difficulté
      _distance++;
      if (_distance % 500 == 0) {
        _obstacleSpeed += 0.5;
      }
    });
  }
  
  bool _checkCollision(Obstacle obstacle) {
    return _playerX + _playerSize > obstacle.x &&
        _playerX < obstacle.x + obstacle.width &&
        _playerY + _playerSize > obstacle.y &&
        _playerY < obstacle.y + obstacle.height;
  }
  
  double get _playerX => 80;
  
  void _jump() {
    if (!_isJumping) {
      _jumpVelocity = _jumpStrength;
      _isJumping = true;
    }
  }
  
  void _restart() {
    setState(() {
      _obstacles.clear();
      _playerY = 300;
      _jumpVelocity = 0;
      _score = 0;
      _distance = 0;
      _obstacleSpeed = 3;
      _gameOver = false;
      _controller.repeat();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('Runner Endless'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Score
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Score: $_score',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'Distance: ${(_distance / 10).round()}m',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            // Zone de jeu
            Container(
              width: _gameWidth,
              height: _gameHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Stack(
                children: [
                  // Sol
                  Positioned(
                    left: 0,
                    top: _groundY,
                    child: Container(
                      width: _gameWidth,
                      height: _gameHeight - _groundY,
                      color: const Color(0xFF4a4a6a),
                    ),
                  ),
                  // Obstacles
                  ..._obstacles.map((obstacle) => Positioned(
                    left: obstacle.x,
                    top: obstacle.y,
                    child: Container(
                      width: obstacle.width,
                      height: obstacle.height,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )),
                  // Joueur
                  Positioned(
                    left: _playerX,
                    top: _playerY,
                    child: Container(
                      width: _playerSize,
                      height: _playerSize,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Bouton saut
            if (!_gameOver)
              GestureDetector(
                onTap: _jump,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_upward, color: Colors.white, size: 40),
                ),
              ),
            // Game Over
            if (_gameOver)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Game Over!',
                      style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score final: $_score',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _restart,
                      child: const Text('Recommencer'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Obstacle {
  double x;
  final double y;
  final double width = 30;
  final double height = 30;
  
  Obstacle(this.x, this.y);
}



