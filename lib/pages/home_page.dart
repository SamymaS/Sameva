import 'package:flutter/material.dart';
import 'create_quest_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7FF),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Bienvenue, Samy ✨',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B3B3B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tu es prêt pour une nouvelle quête ?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF9F89FF),
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progression
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: 0.6,
                backgroundColor: const Color(0xFFE0D8F8),
                color: const Color(0xFF80FFB0),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Quêtes du jour',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // Cartes de quêtes
            _buildQuestCard('Lire 1 chapitre du livre', '30 XP · 10 💰'),
            _buildQuestCard('Faire 15 min de sport', '50 XP · 15 💰'),
            _buildQuestCard('Planifier la semaine', '20 XP · 5 💰', disabled: true),

            const Spacer(),

            // Bouton ajouter une quête
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateQuestPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB5E9FF),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('+ Nouvelle quête'),
              ),
            ),

            const SizedBox(height: 20),

            // Navigation simple (placeholder)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Icon(Icons.home, color: Color(0xFF9F89FF)),
                Icon(Icons.star_border, color: Colors.grey),
                Icon(Icons.lock_outline, color: Colors.grey),
                Icon(Icons.person_outline, color: Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuestCard(String title, String subtitle, {bool disabled = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: disabled ? const Color(0xFFF5F5F5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!disabled)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: disabled ? Colors.grey.shade400 : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: disabled ? Colors.grey.shade300 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
