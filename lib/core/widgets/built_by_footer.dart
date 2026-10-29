import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Credit + copyright note shown at the bottom of every profile.
class BuiltByFooter extends StatelessWidget {
  const BuiltByFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkInk400 : AppColors.lightInk400;
    final year = DateTime.now().year;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Built by LATIM HENRY ODIDA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: isDark ? AppColors.darkInk300 : AppColors.lightInk300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\u00A9 $year Plateau High Zone (PHZ). All rights reserved.\n'
            'Unauthorized copying or redistribution of this app is prohibited.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.4, color: muted),
          ),
        ],
      ),
    );
  }
}
