import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final error = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim().toLowerCase(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      ToastOverlay.show(
        context,
        'Account created! Welcome to CampusX.',
        type: ToastType.success,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final error = await auth.signInWithGoogle();

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
    // On success the browser opens. Supabase's auth-state listener updates
    // the provider when the OAuth callback returns to campusx://auth-callback.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'X',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Create an account',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join your classmates on CampusX.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Inputs
                    GlassTextField(
                      controller: _usernameController,
                      labelText: 'Username',
                      hintText: 'alex_campus',
                      validator: AppValidators.validateUsername,
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        side: BorderSide(
                          color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      label: const Text(
                        'Sign up using Google',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: _isLoading ? null : _handleGoogleSignUp,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    GlassTextField(
                      controller: _emailController,
                      labelText: 'University Email',
                      hintText: 'you@university.edu',
                      keyboardType: TextInputType.emailAddress,
                      validator: AppValidators.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    GlassTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: '••••••••',
                      obscureText: true,
                      validator: AppValidators.validatePassword,
                      onSubmitted: (_) => _handleRegister(),
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.coral500.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.coral500.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.coral400, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.coral400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    GlassButton(
                      width: double.infinity,
                      height: 46,
                      text: 'Join CampusX',
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.violet400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
