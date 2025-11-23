import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/app_colors.dart';

/// Mini-jeu plateformer avec plusieurs niveaux
class PlatformerGame extends StatefulWidget {
  const PlatformerGame({super.key});

  @override
  State<PlatformerGame> createState() => _PlatformerGameState();
}

class _PlatformerGameState extends State<PlatformerGame> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Position du joueur
  double _playerX = 50;
  double _playerY = 300;
  double _playerVelocityY = 0;
  bool _isJumping = false;
  bool _isMovingLeft = false;
  bool _isMovingRight = false;
  
  // Niveau actuel
  int _currentLevel = 1;
  int _score = 0;
  bool _gameOver = false;
  bool _levelComplete = false;
  
  // Plateformes pour chaque niveau
  List<Platform> _platforms = [];
  
  // Collectibles
  List<Collectible> _collectibles = [];
  
  // Dimensions
  final double _gameWidth = 400;
  final double _gameHeight = 600;
  final double _playerSize = 30;
  final double _gravity = 0.8;
  final double _jumpStrength = -15;
  final double _moveSpeed = 3;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_gameLoop);
    _initializeLevel();
    _controller.repeat();
  }
  
  void _initializeLevel() {
    _platforms = _getLevelPlatforms(_currentLevel);
    _collectibles = _getLevelCollectibles(_currentLevel);
    _playerX = 50;
    _playerY = 300;
    _playerVelocityY = 0;
    _score = 0;
    _gameOver = false;
    _levelComplete = false;
  }
  
  List<Platform> _getLevelPlatforms(int level) {
    switch (level) {
      case 1:
        return [
          Platform(100, 400, 100, 20),
          Platform(250, 350, 100, 20),
          Platform(50, 500, 80, 20),
          Platform(300, 450, 100, 20),
          Platform(150, 250, 100, 20), // Plateforme finale
        ];
      case 2:
        return [
          Platform(50, 450, 80, 20),
          Platform(180, 400, 80, 20),
          Platform(300, 350, 80, 20),
          Platform(100, 300, 80, 20),
          Platform(250, 250, 80, 20),
          Platform(50, 200, 80, 20), // Plateforme finale
        ];
      case 3:
        return [
          Platform(50, 500, 60, 20),
          Platform(150, 450, 60, 20),
          Platform(250, 400, 60, 20),
          Platform(100, 350, 60, 20),
          Platform(300, 300, 60, 20),
          Platform(50, 250, 60, 20),
          Platform(200, 200, 60, 20),
          Platform(100, 150, 60, 20), // Plateforme finale
        ];
      default:
        return _getLevelPlatforms(1);
    }
  }
  
  List<Collectible> _getLevelCollectibles(int level) {
    final collectibles = <Collectible>[];
    final platforms = _getLevelPlatforms(level);
    
    for (int i = 0; i < platforms.length - 1; i++) {
      final platform = platforms[i];
      collectibles.add(Collectible(
        platform.x + platform.width / 2,
        platform.y - 20,
      ));
    }
    
    return collectibles;
  }
  
  void _gameLoop() {
    if (_gameOver || _levelComplete) return;
    
    setState(() {
      // Gravité
      _playerVelocityY += _gravity;
      
      // Mouvement horizontal
      if (_isMovingLeft) {
        _playerX -= _moveSpeed;
        if (_playerX < 0) _playerX = 0;
      }
      if (_isMovingRight) {
        _playerX += _moveSpeed;
        if (_playerX > _gameWidth - _playerSize) _playerX = _gameWidth - _playerSize;
      }
      
      // Mouvement vertical
      _playerY += _playerVelocityY;
      
      // Collision avec les plateformes
      bool onPlatform = false;
      for (var platform in _platforms) {
        if (_checkPlatformCollision(platform)) {
          _playerY = platform.y - _playerSize;
          _playerVelocityY = 0;
          onPlatform = true;
          _isJumping = false;
          break;
        }
      }
      
      // Vérifier si le joueur tombe
      if (_playerY > _gameHeight) {
        _gameOver = true;
        _controller.stop();
        return;
      }
      
      // Collecter les collectibles
      _collectibles.removeWhere((collectible) {
        final distance = math.sqrt(
          math.pow(_playerX - collectible.x, 2) + math.pow(_playerY - collectible.y, 2),
        );
        if (distance < 25) {
          _score += 10;
          return true;
        }
        return false;
      });
      
      // Vérifier si le niveau est complété
      if (_platforms.isNotEmpty) {
        final finalPlatform = _platforms.last;
        if (_playerX >= finalPlatform.x &&
            _playerX <= finalPlatform.x + finalPlatform.width &&
            _playerY <= finalPlatform.y - _playerSize &&
            _playerY >= finalPlatform.y - _playerSize - 10) {
          _levelComplete = true;
          _controller.stop();
        }
      }
    });
  }
  
  bool _checkPlatformCollision(Platform platform) {
    return _playerX + _playerSize > platform.x &&
        _playerX < platform.x + platform.width &&
        _playerY + _playerSize > platform.y &&
        _playerY + _playerSize < platform.y + 20 &&
        _playerVelocityY >= 0;
  }
  
  void _jump() {
    if (!_isJumping) {
      _playerVelocityY = _jumpStrength;
      _isJumping = true;
    }
  }
  
  void _nextLevel() {
    setState(() {
      _currentLevel++;
      _levelComplete = false;
      _initializeLevel();
      _controller.repeat();
    });
  }
  
  void _restart() {
    setState(() {
      _currentLevel = 1;
      _initializeLevel();
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
        title: Text('Plateformer - Niveau $_currentLevel'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Score et niveau
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
                    'Niveau: $_currentLevel',
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
                  // Plateformes
                  ..._platforms.map((platform) => Positioned(
                    left: platform.x,
                    top: platform.y,
                    child: Container(
                      width: platform.width,
                      height: platform.height,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )),
                  // Collectibles
                  ..._collectibles.map((collectible) => Positioned(
                    left: collectible.x - 10,
                    top: collectible.y - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Contrôles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bouton gauche
                GestureDetector(
                  onTapDown: (_) => setState(() => _isMovingLeft = true),
                  onTapUp: (_) => setState(() => _isMovingLeft = false),
                  onTapCancel: () => setState(() => _isMovingLeft = false),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 40),
                // Bouton saut
                GestureDetector(
                  onTap: _jump,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 40),
                // Bouton droite
                GestureDetector(
                  onTapDown: (_) => setState(() => _isMovingRight = true),
                  onTapUp: (_) => setState(() => _isMovingRight = false),
                  onTapCancel: () => setState(() => _isMovingRight = false),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              ],
            ),
            // Messages de fin
            if (_gameOver)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Game Over!',
                      style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _restart,
                      child: const Text('Recommencer'),
                    ),
                  ],
                ),
              ),
            if (_levelComplete)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Niveau Complété!',
                      style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _nextLevel,
                      child: Text(_currentLevel < 3 ? 'Niveau Suivant' : 'Terminé!'),
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

class Platform {
  final double x;
  final double y;
  final double width;
  final double height;
  
  Platform(this.x, this.y, this.width, this.height);
}

class Collectible {
  final double x;
  final double y;
  
  Collectible(this.x, this.y);
}


