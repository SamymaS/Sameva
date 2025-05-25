import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Créer une quête',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF3B3B3B),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF9F89FF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Titre de la quête',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildInputField(_titleController, hint: 'Ex: Lire un chapitre'),
            const SizedBox(height: 20),

            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildInputField(_descriptionController,
                hint: 'Ex: Lire le chapitre 3 du livre XYZ', maxLines: 4),
            const SizedBox(height: 20),

            const Text(
              'Durée estimée (en heures)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _estimatedHours,
              min: 0.5,
              max: 10,
              divisions: 19,
              label: _estimatedHours.toStringAsFixed(1),
              onChanged: (value) {
                setState(() => _estimatedHours = value);
              },
              activeColor: const Color(0xFFB5E9FF),
            ),
            const SizedBox(height: 20),

            const Text(
              'Difficulté',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Row(
              children: List.generate(5, (index) => _buildDifficultyStar(index)),
            ),
            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                onPressed: _submitQuest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9F89FF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Créer la quête',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller,
      {String hint = '', int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDifficultyStar(int index) {
    return IconButton(
      onPressed: () {
        setState(() => _difficulty = index + 1);
      },
      icon: Icon(
        Icons.star,
        color: index < _difficulty ? const Color(0xFFFFC107) : Colors.grey.shade300,
      ),
    );
  }

  void _submitQuest() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    // Pour la suite : envoyer vers le système de quêtes ou affichage console
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quête créée avec succès !')),
    );
    Navigator.pop(context);
  }
}
