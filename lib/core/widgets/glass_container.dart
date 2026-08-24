import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double blur;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool enableGlow;
  final Clip clipBehavior;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blur = 16.0,
    this.width,
    this.height,
    this.onTap,
    this.enableGlow = false,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? AppColors.darkBg900.withOpacity(0.65)
        : Colors.white.withOpacity(0.85);
    final defaultBorder = isDark
        ? AppColors.darkGlassBorder
        : AppColors.lightGlassBorder;

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? defaultBorder,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          if (enableGlow)
            BoxShadow(
              color: AppColors.violet500.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          hoverColor: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.02),
          child: container,
        ),
      );
    }

    return container;
  }
}
