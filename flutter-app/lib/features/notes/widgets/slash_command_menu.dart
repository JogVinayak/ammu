import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SlashCommandItem {
  final String label;
  final String keyword;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const SlashCommandItem({
    required this.label,
    required this.keyword,
    required this.icon,
    required this.description,
    required this.onTap,
  });
}

class SlashCommandMenu extends StatelessWidget {
  final List<SlashCommandItem> commands;
  final String filter;

  const SlashCommandMenu({
    super.key,
    required this.commands,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = filter.isEmpty
        ? commands
        : commands
            .where((cmd) =>
                cmd.label.toLowerCase().contains(filter) ||
                cmd.keyword.toLowerCase().contains(filter))
            .toList();

    if (filtered.isEmpty) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: AppColors.surface,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('No matching commands',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppRadius.card),
      color: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300, maxWidth: 280),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final cmd = filtered[index];
            return _SlashCommandTile(
              icon: cmd.icon,
              label: cmd.label,
              description: cmd.description,
              onTap: cmd.onTap,
            );
          },
        ),
      ),
    );
  }
}

class _SlashCommandTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _SlashCommandTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
