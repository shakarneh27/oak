import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Shared layout shell for landing-page sections: centers content, caps
/// its width on large screens, and applies the standard vertical rhythm —
/// one place to change instead of per-section padding math.
class SectionShell extends StatelessWidget {
  final Widget child;
  final Color? background;
  final EdgeInsetsGeometry padding;

  const SectionShell({
    super.key,
    required this.child,
    this.background,
    this.padding = const EdgeInsets.symmetric(
      vertical: AppSpacing.section,
      horizontal: AppSpacing.lg,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentMaxWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Standard section heading (title + optional subtitle) so every section
/// shares the same typography.
class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeading({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: textTheme.bodyLarge?.copyWith(
              color: textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
