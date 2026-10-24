import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class QuickInterventionBar extends StatelessWidget {
  final VoidCallback onBreatheTap;
  final VoidCallback onJournalTap;
  final VoidCallback onMoodTap;
  final VoidCallback onReachOutTap;

  const QuickInterventionBar({
    super.key,
    required this.onBreatheTap,
    required this.onJournalTap,
    required this.onMoodTap,
    required this.onReachOutTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.air_rounded,
            label: '4-7-8 Breathe',
            color: AppColors.primaryTeal,
            onTap: onBreatheTap,
          ),
          _buildActionButton(
            context: context,
            icon: Icons.edit_note_rounded,
            label: 'Reflect',
            color: AppColors.softLavender,
            onTap: onJournalTap,
          ),
          _buildActionButton(
            context: context,
            icon: Icons.sentiment_satisfied_alt_rounded,
            label: 'Check-in',
            color: AppColors.sageGreen,
            onTap: onMoodTap,
          ),
          _buildActionButton(
            context: context,
            icon: Icons.favorite_border_rounded,
            label: 'Support',
            color: AppColors.statusElevated,
            onTap: onReachOutTap,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
