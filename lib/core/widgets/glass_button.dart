import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum GlassButtonVariant {
  primary,
  secondary,
  ghost,
  danger,
}

class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? text;
  final IconData? icon;
  final GlassButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GlassButton({
    super.key,
    required this.onPressed,
    this.child,
    this.text,
    this.icon,
    this.variant = GlassButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 42.0,
    this.padding,
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    Border? border;
    List<BoxShadow>? shadows;

    switch (variant) {
      case GlassButtonVariant.primary:
        bg = AppColors.violet500;
        fg = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.violet500.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case GlassButtonVariant.secondary:
        bg = isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05);
        fg = isDark ? AppColors.darkInk100 : AppColors.lightInk100;
        border = Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
        );
        break;
      case GlassButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkInk300 : AppColors.lightInk300;
        break;
      case GlassButtonVariant.danger:
        bg = AppColors.coral500.withOpacity(0.15);
        fg = AppColors.coral400;
        border = Border.all(color: AppColors.coral500.withOpacity(0.3));
        break;
    }

    if (!isEnabled) {
      bg = bg.withOpacity(0.4);
      fg = fg.withOpacity(0.4);
      shadows = null;
    }

    Widget content = child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                if (text != null) const SizedBox(width: 8),
              ],
              if (text != null)
                Text(
                  text!,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ],
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          hoverColor: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
