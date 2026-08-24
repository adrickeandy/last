import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final features = [
      {
        'icon': Icons.lock_outline_rounded,
        'title': 'Confessions',
        'desc': 'Say it anonymously. No names, no judgment.',
        'color': AppColors.coral400,
      },
      {
        'icon': Icons.groups_rounded,
        'title': 'Clubs',
        'desc': 'Find your people — coding, debate, drama, esports.',
        'color': AppColors.violet400,
      },
      {
        'icon': Icons.calendar_month_rounded,
        'title': 'Events',
        'desc': 'Never miss a hackathon, workshop, or campus game night.',
        'color': AppColors.lime400,
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'title': 'Marketplace',
        'desc': 'Buy and sell textbooks, gadgets, and gear with fellow students.',
        'color': AppColors.coral500,
      },
    ];

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'X',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'CampusX',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                letterSpacing: -0.5,
                              ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GlassButton(
                          variant: GlassButtonVariant.ghost,
                          text: 'Log in',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        GlassButton(
                          variant: GlassButtonVariant.primary,
                          text: 'Get started',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 80),

                // Hero Section
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
                      height: 1.15,
                    ),
                    children: [
                      const TextSpan(text: 'Where your campus\n'),
                      WidgetSpan(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.violet400, AppColors.coral400, AppColors.lime400],
                          ).createShader(bounds),
                          child: const Text(
                            'actually talks.',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Text(
                    'Feeds, confessions, clubs, events, marketplace, and an AI tutor — built exclusively for your classmates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDark ? AppColors.darkInk300 : AppColors.lightInk300,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Call to action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlassButton(
                      variant: GlassButtonVariant.primary,
                      height: 48,
                      text: 'Join CampusX',
                      icon: Icons.arrow_forward_rounded,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    GlassButton(
                      variant: GlassButtonVariant.secondary,
                      height: 48,
                      text: 'I already have an account',
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 90),

                // Features Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: features.length,
                      itemBuilder: (context, i) {
                        final f = features[i];
                        return GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (f['color'] as Color).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  f['icon'] as IconData,
                                  color: f['color'] as Color,
                                  size: 20,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                f['title'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                f['desc'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
