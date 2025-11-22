import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/app_colors.dart';

/// Mini-jeu match-3
class Match3Game extends StatefulWidget {
  const Match3Game({super.key});

  @override
  State<Match3Game> createState() => _Match3GameState();
}

class _Match3GameState extends State<Match3Game> {
  static const int gridSize = 8;
  List<List<int>> _grid = [];
  int _score = 0;
  int _moves = 30;
  bool _gameOver = false;
  int? _selectedRow;
  int? _selectedCol;
  
  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }
  
  void _initializeGrid() {
    _grid = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => math.Random().nextInt(_colors.length)),
    );
    // Éviter les matches initiaux
    while (_hasMatches()) {
      _grid = List.generate(
        gridSize,
        (_) => List.generate(gridSize, (_) => math.Random().nextInt(_colors.length)),
      );
    }
  }
  
  bool _hasMatches() {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (_checkMatch(row, col)) return true;
      }
    }
    return false;
  }
  
  bool _checkMatch(int row, int col) {
    final color = _grid[row][col];
    int horizontal = 1;
    int vertical = 1;
    
    // Horizontal
    for (int c = col + 1; c < gridSize && _grid[row][c] == color; c++) horizontal++;
    for (int c = col - 1; c >= 0 && _grid[row][c] == color; c--) horizontal++;
    
    // Vertical
    for (int r = row + 1; r < gridSize && _grid[r][col] == color; r++) vertical++;
    for (int r = row - 1; r >= 0 && _grid[r][col] == color; r--) vertical++;
    
    return horizontal >= 3 || vertical >= 3;
  }
  
  void _onCellTap(int row, int col) {
    if (_gameOver) return;
    
    if (_selectedRow == null && _selectedCol == null) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
    } else {
      if (_selectedRow == row && _selectedCol == col) {
        setState(() {
          _selectedRow = null;
          _selectedCol = null;
        });
      } else {
        // Échanger
        final temp = _grid[row][col];
        _grid[row][col] = _grid[_selectedRow!][_selectedCol!];
        _grid[_selectedRow!][_selectedCol!] = temp;
        
        // Vérifier les matches
        if (_checkMatch(row, col) || _checkMatch(_selectedRow!, _selectedCol!)) {
          _moves--;
          _processMatches();
        } else {
          // Annuler l'échange
          final temp2 = _grid[row][col];
          _grid[row][col] = _grid[_selectedRow!][_selectedCol!];
          _grid[_selectedRow!][_selectedCol!] = temp2;
        }
        
        setState(() {
          _selectedRow = null;
          _selectedCol = null;
        });
        
        if (_moves <= 0) {
          _gameOver = true;
        }
      }
    }
  }
  
  void _processMatches() {
    bool foundMatch = true;
    
    while (foundMatch) {
      foundMatch = false;
      final toRemove = <List<int>>[];
      
      for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
          if (_checkMatch(row, col)) {
            toRemove.add([row, col]);
            foundMatch = true;
          }
        }
      }
      
      if (foundMatch) {
        // Supprimer les matches
        for (var pos in toRemove) {
          _grid[pos[0]][pos[1]] = -1;
        }
        
        // Faire tomber les gemmes
        for (int col = 0; col < gridSize; col++) {
          int writeIndex = gridSize - 1;
          for (int row = gridSize - 1; row >= 0; row--) {
            if (_grid[row][col] != -1) {
              _grid[writeIndex][col] = _grid[row][col];
              if (writeIndex != row) _grid[row][col] = -1;
              writeIndex--;
            }
          }
          // Remplir les vides
          for (int row = writeIndex; row >= 0; row--) {
            _grid[row][col] = math.Random().nextInt(_colors.length);
          }
        }
        
        _score += toRemove.length * 10;
      }
    }
  }
  
  void _restart() {
    setState(() {
      _score = 0;
      _moves = 30;
      _gameOver = false;
      _selectedRow = null;
      _selectedCol = null;
      _initializeGrid();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('Match-3'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score et mouvements
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Score: $_score',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Mouvements: $_moves',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Grille
            Expanded(
              child: Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: gridSize * gridSize,
                    itemBuilder: (context, index) {
                      final row = index ~/ gridSize;
                      final col = index % gridSize;
                      final isSelected = _selectedRow == row && _selectedCol == col;
                      
                      return GestureDetector(
                        onTap: () => _onCellTap(row, col),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _grid[row][col] >= 0
                                ? _colors[_grid[row][col]]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_gameOver)
              Column(
                children: [
                  const Text(
                    'Game Over!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score final: $_score',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _restart,
                    child: const Text('Recommencer'),
                  ),
                ],
              )
            else
              const Text(
                'Touchez deux gemmes pour les échanger',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

