// lib/pages/create_quest_page.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreateQuestPage extends StatefulWidget {
  const CreateQuestPage({super.key});

  @override
  State<CreateQuestPage> createState() => _CreateQuestPageState();
}

class _CreateQuestPageState extends State<CreateQuestPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  double _estimatedHours = 1;
  int _difficulty = 1;
  String _selectedCategory = 'quotidienne';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Nouvelle Quête',
          style: AppStyles.titleStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategorySelector(),
              const SizedBox(height: 32),
              _buildInputSection(
                title: 'Titre de la quête',
                hint: 'Ex : Méditer pendant 10 minutes',
                controller: _titleController,
              ),
              const SizedBox(height: 24),
              _buildInputSection(
                title: 'Description',
                hint: 'Décris ta quête en détail...',
                controller: _descriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              _buildDurationSection(),
              const SizedBox(height: 24),
              _buildDifficultySection(),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.radius,
        boxShadow: [AppStyles.softShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _categoryButton('Quotidienne', 'quotidienne', AppColors.secondary),
          _categoryButton('Hebdomadaire', 'hebdomadaire', AppColors.primary),
          _categoryButton('Spéciale', 'speciale', AppColors.accent),
        ],
      ),
    );
  }

  Widget _categoryButton(String label, String value, Color color) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: AppStyles.radius,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppStyles.subtitleStyle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppStyles.radius,
            boxShadow: [AppStyles.softShadow],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Durée estimée', style: AppStyles.subtitleStyle),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppStyles.radius,
            boxShadow: [AppStyles.softShadow],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_estimatedHours.toStringAsFixed(1)} heures'),
                  Text(_getDurationLabel()),
                ],
              ),
              Slider(
                value: _estimatedHours,
                min: 0.5,
                max: 10,
                divisions: 19,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withOpacity(0.2),
                onChanged: (value) => setState(() => _estimatedHours = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDurationLabel() {
    if (_estimatedHours <= 1) return 'Très courte';
    if (_estimatedHours <= 3) return 'Courte';
    if (_estimatedHours <= 6) return 'Moyenne';
    if (_estimatedHours <= 8) return 'Longue';
    return 'Épique';
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Niveau de difficulté', style: AppStyles.subtitleStyle),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppStyles.radius,
            boxShadow: [AppStyles.softShadow],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) => _buildDifficultyStar(index)),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyStar(int index) {
    return IconButton(
      onPressed: () => setState(() => _difficulty = index + 1),
      icon: Icon(
        Icons.star_rounded,
        size: 32,
        color: index < _difficulty 
            ? AppColors.primary 
            : AppColors.primary.withOpacity(0.2),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitQuest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppStyles.radius),
          elevation: 0,
        ),
        child: const Text(
          'Créer ma quête',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _submitQuest() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Le titre de la quête est obligatoire'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.radius),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ta nouvelle quête a été créée avec succès !'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radius),
      ),
    );
    Navigator.pop(context);
  }
}