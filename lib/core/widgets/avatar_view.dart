import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarView extends StatelessWidget {
  final String? url;
  final String? name;
  final double size;
  final bool showRing;
  final bool isVerified;
  final VoidCallback? onTap;

  const AvatarView({
    super.key,
    this.url,
    this.name,
    this.size = 40.0,
    this.showRing = false,
    this.isVerified = false,
    this.onTap,
  });

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);

    Widget avatarCore = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: (url == null || url!.isEmpty) ? AppColors.brandGradient : null,
        color: (url != null && url!.isNotEmpty) ? Colors.black12 : null,
      ),
      child: ClipOval(
        child: (url != null && url!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder: (context, url) => Container(
                  color: AppColors.violet500.withOpacity(0.2),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );

    if (showRing) {
      avatarCore = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.brandGradient,
        ),
        child: avatarCore,
      );
    }

    if (isVerified) {
      avatarCore = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCore,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: AppColors.violet400,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: avatarCore,
        ),
      );
    }

    return avatarCore;
  }
}
