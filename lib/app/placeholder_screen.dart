import 'package:flutter/material.dart';
import 'package:navmaas/core/theme/app_theme.dart';

/// A calm stand-in for tabs that arrive in later milestones.
class PlaceholderScreen extends StatelessWidget {
  const new({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          24,
          AppTheme.gutter,
          24,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(title, style: text.headlineSmall),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: text.bodyLarge!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
