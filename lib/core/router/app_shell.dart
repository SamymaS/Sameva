import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../presentation/view_models/quest_view_model.dart';
import '../../ui/widgets/common/dock_bar.dart';

/// Cadre des onglets : la page de l'onglet courant et le dock flottant.
/// Chaque onglet garde sa propre pile de navigation (StatefulShellRoute).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    // viewPadding.bottom est stable même quand le clavier est ouvert.
    final navBarHeight = MediaQuery.viewPaddingOf(context).bottom;
    const dockBarHeight = 68.0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: dockBarHeight + navBarHeight),
            child: shell,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Consumer<QuestViewModel>(
              builder: (_, qvm, __) {
                final missedCount = qvm.getMissedQuests().length;
                return DockBar(
                  currentIndex: shell.currentIndex,
                  // Toucher l'onglet courant ramène à sa racine.
                  onTap: (i) => shell.goBranch(i,
                      initialLocation: i == shell.currentIndex),
                  badges: missedCount > 0 ? {1: missedCount} : const {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
