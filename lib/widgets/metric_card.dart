import 'package:flutter/material.dart';

/// A themed label + large value card, e.g. the Zakat result or a
/// Fasting-tracker stat, replacing plain hardcoded-style Cards.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlighted
            ? null
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        gradient: highlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary, colorScheme.secondary],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: highlighted
            ? null
            : Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: highlighted
                    ? colorScheme.onPrimary.withValues(alpha: 0.22)
                    : colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: highlighted ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: highlighted
                        ? colorScheme.onPrimary.withValues(alpha: 0.8)
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: highlighted ? colorScheme.onPrimary : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
