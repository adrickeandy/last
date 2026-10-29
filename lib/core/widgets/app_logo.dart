import 'package:flutter/material.dart';

/// The Plateau High Zone (PHZ) logo, shown in the sidebar, loading screen,
/// landing, login and register screens. The image lives in
/// assets/images/phz_logo.png — replace that one file to change the logo
/// everywhere in the app.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40, this.radius});

  /// Width and height of the logo (it is square).
  final double size;

  /// Corner radius. Defaults to a soft rounded square.
  final double? radius;

  static const String assetPath = 'assets/images/phz_logo.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size * 0.22),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
