import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'create_quest_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final double _xpProgress = 0.6; // À remplacer par la vraie progression
  final int _level = 5; // À remplacer par le vrai niveau
  final int _coins = 250; // À remplacer par le vrai nombre de pièces

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressSection(),
            _buildTabBar(),
            Expanded(child: _buildTabBarView()),
            _buildBottomBar(),
          ],
        ),
      ),
      floatingActionButton: _buildAddQuestButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar et niveau
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [AppStyles.softShadow],
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 30),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [AppStyles.softShadow],
                  ),
                  child: Text(
                    'Nv.$_level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Informations utilisateur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, Héros !',
                  style: AppStyles.titleStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  'Une nouvelle journée d\'aventures t\'attend',
                  style: AppStyles.subtitleStyle,
                ),
              ],
            ),
          ),

          // Pièces
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppStyles.radius,
              boxShadow: [AppStyles.softShadow],
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B3B3B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
              Text(
                'Progression du niveau',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(_xpProgress * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _xpProgress,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.radius,
        boxShadow: [AppStyles.softShadow],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: AppStyles.radius,
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: const [
          Tab(text: 'Journalières'),
          Tab(text: 'En cours'),
          Tab(text: 'Terminées'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildQuestList(_dailyQuests),
        _buildQuestList(_ongoingQuests),
        _buildQuestList(_completedQuests),
      ],
    );
  }

  Widget _buildQuestList(List<Map<String, dynamic>> quests) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        return _buildQuestCard(quest);
      },
    );
  }

  Widget _buildQuestCard(Map<String, dynamic> quest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.radius,
        boxShadow: [AppStyles.softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {/* Gérer le tap sur la quête */},
          borderRadius: AppStyles.radius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(quest['category']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quest['category'],
                        style: TextStyle(
                          color: _getCategoryColor(quest['category']),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${quest['xp']} XP',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  quest['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B3B3B),
                  ),
                ),
                if (quest['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    quest['description'],
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${quest['duration']} h',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ...List.generate(
                      quest['difficulty'],
                      (index) => const Icon(Icons.star,
                          size: 16, color: Color(0xFFFFC107)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'quotidienne':
        return AppColors.secondary;
      case 'hebdomadaire':
        return AppColors.primary;
      case 'spéciale':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildBottomBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [AppStyles.softShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomBarItem(Icons.home, 'Accueil', true),
          _buildBottomBarItem(Icons.star_border, 'Récompenses', false),
          const SizedBox(width: 40), // Espace pour le FAB
          _buildBottomBarItem(Icons.person_outline, 'Profil', false),
          _buildBottomBarItem(Icons.settings_outlined, 'Paramètres', false),
        ],
      ),
    );
  }

  Widget _buildBottomBarItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAddQuestButton() {
    return Container(
      height: 65,
      width: 65,
      margin: const EdgeInsets.only(top: 30),
      child: FittedBox(
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateQuestPage()),
            );
          },
          backgroundColor: AppColors.primary,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: const Icon(
              Icons.add,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Données de test
  final List<Map<String, dynamic>> _dailyQuests = [
    {
      'title': 'Méditation matinale',
      'description': '10 minutes de méditation en pleine conscience',
      'category': 'Quotidienne',
      'duration': 0.5,
      'difficulty': 2,
      'xp': 50,
    },
    {
      'title': 'Lecture enrichissante',
      'description': 'Lire un chapitre de ton livre actuel',
      'category': 'Quotidienne',
      'duration': 1,
      'difficulty': 3,
      'xp': 75,
    },
  ];

  final List<Map<String, dynamic>> _ongoingQuests = [
    {
      'title': 'Projet créatif',
      'description': 'Avancer sur ton projet personnel',
      'category': 'Hebdomadaire',
      'duration': 2,
      'difficulty': 4,
      'xp': 150,
    },
  ];

  final List<Map<String, dynamic>> _completedQuests = [
    {
      'title': 'Sport matinal',
      'description': '30 minutes d\'exercice',
      'category': 'Quotidienne',
      'duration': 0.5,
      'difficulty': 3,
      'xp': 100,
    },
  ];
}
