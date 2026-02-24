import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../theme/app_colors.dart';
import 'memory_game_page.dart';

/// Hub des mini-jeux.
class MinigamesPage extends StatelessWidget {
  const MinigamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Mini-Jeux',
          style: TextStyle(
              color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MemoryGameTile(),
        ],
      ),
    );
  }
}

class _MemoryGameTile extends StatelessWidget {
  bool get _canPlay {
    final box = Hive.box('settings');
    final lastStr = box.get('lastMemoryGameAt') as String?;
    if (lastStr == null) return true;
    final last = DateTime.parse(lastStr);
    return DateTime.now().difference(last).inHours >= 24;
  }

  Duration get _cooldownRemaining {
    final box = Hive.box('settings');
    final lastStr = box.get('lastMemoryGameAt') as String?;
    if (lastStr == null) return Duration.zero;
    final last = DateTime.parse(lastStr);
    final elapsed = DateTime.now().difference(last);
    final remaining = const Duration(hours: 24) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = _canPlay;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondaryViolet.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.secondaryViolet.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.extension_outlined,
              color: AppColors.secondaryVioletGlow, size: 28),
        ),
        title: const Text(
          'Mémoire de sorts',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.gold, size: 14),
                const SizedBox(width: 4),
                const Text(
                  '10–100 or selon votre temps',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (!canPlay) ...[
              Text(
                'Disponible dans ${_formatTimer(_cooldownRemaining)}',
                style: const TextStyle(
                    color: AppColors.warning, fontSize: 12),
              ),
            ] else ...[
              const Text(
                'Disponible maintenant !',
                style: TextStyle(color: AppColors.success, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: FilledButton(
          onPressed: canPlay
              ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MemoryGamePage(),
                    ),
                  )
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: canPlay
                ? AppColors.secondaryViolet
                : AppColors.secondaryViolet.withValues(alpha: 0.3),
          ),
          child: const Text('Jouer'),
        ),
      ),
    );
  }

  String _formatTimer(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
