import 'package:flutter/material.dart';
import 'package:navmaas/core/theme/navmaas_colors.dart';
import 'package:navmaas/core/theme/navmaas_icons.dart';

/// An amber notice with the warning icon (DESIGN_SYSTEM: notices use amber,
/// never red).
class NoticeBox extends StatelessWidget {
  const new({required this.text, this.icon = NavmaasIcon.notice, super.key});

  final String text;
  final NavmaasIcon icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.navmaas;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.amberSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: NmIcon(icon, size: 20, color: colors.onAmberSoft),
            ),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onAmberSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
