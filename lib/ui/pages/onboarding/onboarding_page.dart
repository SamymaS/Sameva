import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cat/cat_widget.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Sélection du chat
  String _selectedRace = 'michi';
  final TextEditingController _catNameCtrl = TextEditingController();

  String _defaultCatName(String race) => switch (race) {
        'michi'  => 'Michi',
        'lune'   => 'Luna',
        'braise' => 'Braise',
        'neige'  => 'Flocon',
        'cosmos' => 'Cosmos',
        'sakura' => 'Sakura',
        _        => 'Chat',
      };

  @override
  void dispose() {
    _catNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    // Créer le chat compagnon (nom par défaut si champ vide)
    final catName = _catNameCtrl.text.trim().isEmpty
        ? _defaultCatName(_selectedRace)
        : _catNameCtrl.text.trim();
    if (mounted) {
      await context.read<CatViewModel>().createMainCat(_selectedRace, catName);
    }

    await Hive.box('settings').put('has_onboarded', true);

    if (!mounted) return;
    // Revenir à la route racine : le `home` MaterialApp est le Consumer qui choisit
    // onboarding / login / shell selon Hive + auth. Ne pas pousser `/login` seul,
    // sinon on perd ce Consumer et la connexion ne bascule plus l'écran.
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildSlide(
        title: 'Transforme ta vie en aventure',
        subtitle: 'Définis des quêtes, gagne de l\'XP et progresse chaque jour',
        icon: Icons.auto_awesome,
        color: AppColors.primaryViolet,
      ),
      _buildSlide(
        title: 'Des quêtes épiques',
        subtitle: 'Crée des objectifs clairs et motivants avec des récompenses',
        icon: Icons.assignment_turned_in,
        color: AppColors.gold,
      ),
      _buildSlide(
        title: 'Progresse et gagne des récompenses',
        subtitle:
            'Obtiens de l\'XP, des pièces et des objets en accomplissant tes quêtes',
        icon: Icons.emoji_events,
        color: AppColors.mintMagic,
      ),
      _buildCatSlide(),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Ignorer uniquement sur les 3 premières slides
          if (_currentPage < pages.length - 1)
            TextButton(
              onPressed: _finishOnboarding,
              child: const Text('Ignorer',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: pages.length,
              itemBuilder: (_, i) => pages[i],
            ),
          ),
          const SizedBox(height: 8),
          // Indicateurs de page
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: _currentPage == i ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? AppColors.primaryVioletLight
                      : AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bouton suivant / commencer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _currentPage == pages.length - 1
                    ? _finishOnboarding
                    : () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut),
                child: Text(
                  _currentPage == pages.length - 1
                      ? 'Commencer l\'aventure !'
                      : 'Suivant',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide standard ──────────────────────────────────────────────────────────

  Widget _buildSlide({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide sélection de chat ─────────────────────────────────────────────────

  Widget _buildCatSlide() {
    const races = [
      (id: 'michi',  label: 'Michi',  desc: 'Sage & calme'),
      (id: 'lune',   label: 'Lune',   desc: 'Mystérieux'),
      (id: 'braise', label: 'Braise', desc: 'Énergique'),
      (id: 'neige',  label: 'Neige',  desc: 'Doux & timide'),
      (id: 'cosmos', label: 'Cosmos', desc: 'Mystique'),
      (id: 'sakura', label: 'Sakura', desc: 'Joyeux'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Text(
            'Choisis ton chat compagnon',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Il t\'accompagnera tout au long de ton aventure',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Grille 2×3 des races
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: races.map((r) {
              final selected = _selectedRace == r.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedRace = r.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryViolet.withValues(alpha: 0.18)
                        : AppColors.backgroundDarkPanel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryVioletLight
                          : AppColors.inputBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CatWidget(race: r.id, size: 72, mood: 'happy'),
                      const SizedBox(height: 6),
                      Text(
                        r.label,
                        style: GoogleFonts.nunito(
                          color: selected
                              ? AppColors.primaryVioletLight
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        r.desc,
                        style: GoogleFonts.nunito(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Aperçu du chat sélectionné
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CatWidget(race: _selectedRace, size: 90, mood: 'excited'),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
                  controller: _catNameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Nom de ton chat…',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.backgroundDarkPanel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primaryVioletLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primaryVioletLight, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
