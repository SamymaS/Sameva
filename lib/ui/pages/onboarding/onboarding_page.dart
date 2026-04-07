import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cat/cat_widget.dart';

// ── Données des races ────────────────────────────────────────────────────────

typedef _Race = ({String id, String label, String desc, String trait, String traitIcon});

const List<_Race> _races = [
  (id: 'michi',  label: 'Michi',  desc: 'Sage & calme',    trait: 'Contemplatif',   traitIcon: '🧘'),
  (id: 'lune',   label: 'Lune',   desc: 'Mystérieux',       trait: 'Nocturne',       traitIcon: '🌙'),
  (id: 'braise', label: 'Braise', desc: 'Énergique',         trait: 'Combatif',       traitIcon: '🔥'),
  (id: 'neige',  label: 'Neige',  desc: 'Doux & timide',    trait: 'Protecteur',     traitIcon: '❄️'),
  (id: 'cosmos', label: 'Cosmos', desc: 'Mystique',          trait: 'Visionnaire',    traitIcon: '✨'),
  (id: 'sakura', label: 'Sakura', desc: 'Joyeux',            trait: 'Chanceux',       traitIcon: '🌸'),
];

// ── Page principale ──────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  String _selectedRace = 'michi';
  final _catNameCtrl = TextEditingController(text: 'Michi');

  static const _totalPages = 4;

  String _defaultName(String race) => switch (race) {
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final name = _catNameCtrl.text.trim().isEmpty
        ? _defaultName(_selectedRace)
        : _catNameCtrl.text.trim();
    if (mounted) {
      await context.read<CatViewModel>().createMainCat(_selectedRace, name);
    }
    await Hive.box('settings').put('has_onboarded', true);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _confirmSkip() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundDarkPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ignorer l\'introduction ?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Ton chat sera créé avec un nom et une race par défaut. '
          'Tu pourras le personnaliser depuis la page Chat.',
          style: TextStyle(color: AppColors.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryViolet),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ignorer'),
          ),
        ],
      ),
    );
    if (ok == true) await _finish();
  }

  void _onRaceSelected(String race) {
    setState(() {
      // Auto-update le nom uniquement si l'utilisateur n'a pas personnalisé
      final prevDefault = _defaultName(_selectedRace);
      final currentName = _catNameCtrl.text.trim();
      if (currentName.isEmpty || currentName == prevDefault) {
        _catNameCtrl.text = _defaultName(race);
      }
      _selectedRace = race;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < _totalPages - 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _confirmSkip,
                child: const Text(
                  'Ignorer',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _OnboardingSlide(
                  isActive: _currentPage == 0,
                  title: 'Transforme ta vie\nen aventure',
                  subtitle:
                      'Définis des quêtes, gagne de l\'XP\net progresse chaque jour',
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.primaryViolet,
                  glowColor: AppColors.primaryVioletGlow,
                ),
                _OnboardingSlide(
                  isActive: _currentPage == 1,
                  title: 'Des quêtes épiques',
                  subtitle:
                      'Crée des objectifs clairs et motivants\navec des récompenses à la clé',
                  icon: Icons.assignment_turned_in_rounded,
                  color: AppColors.gold,
                  glowColor: AppColors.gold,
                ),
                _OnboardingSlide(
                  isActive: _currentPage == 2,
                  title: 'Gagne des récompenses',
                  subtitle:
                      'XP, pièces d\'or, objets rares et succès\nt\'attendent à chaque quête accomplie',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.mintMagic,
                  glowColor: AppColors.mintMagic,
                ),
                _CatSelectionSlide(
                  isActive: _currentPage == 3,
                  selectedRace: _selectedRace,
                  catNameCtrl: _catNameCtrl,
                  onRaceSelected: _onRaceSelected,
                ),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        children: [
          // Indicateurs de page
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _totalPages,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? AppColors.primaryVioletLight
                      : AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bouton principal
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryViolet,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _currentPage == _totalPages - 1
                  ? _finish
                  : () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      ),
              child: Text(
                _currentPage == _totalPages - 1
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
        ],
      ),
    );
  }
}

// ── Slide animé (feature slides 1–3) ────────────────────────────────────────

class _OnboardingSlide extends StatefulWidget {
  final bool isActive;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color glowColor;

  const _OnboardingSlide({
    required this.isActive,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.glowColor,
  });

  @override
  State<_OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<_OnboardingSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (widget.isActive) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_OnboardingSlide old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha: 0.25),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(widget.icon, size: 84, color: widget.color),
              ),
            ),
          ),
          const SizedBox(height: 40),
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide sélection de chat ──────────────────────────────────────────────────

class _CatSelectionSlide extends StatefulWidget {
  final bool isActive;
  final String selectedRace;
  final TextEditingController catNameCtrl;
  final ValueChanged<String> onRaceSelected;

  const _CatSelectionSlide({
    required this.isActive,
    required this.selectedRace,
    required this.catNameCtrl,
    required this.onRaceSelected,
  });

  @override
  State<_CatSelectionSlide> createState() => _CatSelectionSlideState();
}

class _CatSelectionSlideState extends State<_CatSelectionSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (widget.isActive) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_CatSelectionSlide old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final race = _races.firstWhere((r) => r.id == widget.selectedRace);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 56 + MediaQuery.of(context).padding.top, 24, 24),
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

              // ── Spotlight du chat sélectionné ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                child: CatWidget(
                  key: ValueKey(widget.selectedRace),
                  race: widget.selectedRace,
                  size: 120,
                  mood: 'excited',
                ),
              ),
              const SizedBox(height: 12),

              // ── Carte personnalité ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Container(
                  key: ValueKey(widget.selectedRace),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryViolet.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryVioletLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(race.traitIcon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        race.trait,
                        style: GoogleFonts.nunito(
                          color: AppColors.primaryVioletLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${race.desc}',
                        style: GoogleFonts.nunito(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Grille des races ──
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.88,
                children: _races.map((r) {
                  final isSelected = widget.selectedRace == r.id;
                  return GestureDetector(
                    onTap: () => widget.onRaceSelected(r.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryViolet.withValues(alpha: 0.22)
                            : AppColors.backgroundDarkPanel,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryVioletLight
                              : AppColors.inputBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryViolet.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CatWidget(race: r.id, size: 60, mood: 'happy'),
                          const SizedBox(height: 4),
                          Text(
                            r.label,
                            style: GoogleFonts.nunito(
                              color: isSelected
                                  ? AppColors.primaryVioletLight
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Champ de nom ──
              TextField(
                controller: widget.catNameCtrl,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Donne un nom à ton chat…',
                  hintStyle: GoogleFonts.nunito(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.pets_rounded,
                      color: AppColors.primaryVioletLight, size: 20),
                  filled: true,
                  fillColor: AppColors.backgroundDarkPanel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.primaryVioletLight, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
