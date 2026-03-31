import 'package:adminmrz/auth/service.dart';
import 'package:adminmrz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@ms.com');
  final _passwordController = TextEditingController(text: 'Admin@123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Row(
        children: [
          // ── Left panel (branding) ───────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -80,
                    left: -80,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    right: -60,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 200,
                    right: -40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(56),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: AppTheme.radiusLg,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Marriage Station',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Admin Management Portal',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.80),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Feature list
                        ...[
                          ('Manage Members & Profiles', Icons.people_outline),
                          ('Document Verification', Icons.verified_outlined),
                          ('Matchmaking Analytics', Icons.analytics_outlined),
                          ('Payment & Subscription', Icons.payment_outlined),
                        ].map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: AppTheme.radiusSm,
                                  ),
                                  child: Icon(item.$2,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  item.$1,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.90),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right panel (form) ──────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              color: AppTheme.scaffoldBg,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.10),
                            borderRadius: AppTheme.radiusMd,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to your admin account',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 36),

                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email
                              const Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'admin@marriagestation.com',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              // Error
                              if (authProvider.error != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorLight,
                                    borderRadius: AppTheme.radiusSm,
                                    border: Border.all(
                                        color: AppTheme.error.withOpacity(0.30)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppTheme.error, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          authProvider.error!,
                                          style: const TextStyle(
                                            color: AppTheme.error,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Sign In Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: AppTheme.radiusSm,
                                    boxShadow: AppTheme.primaryShadow,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              final success =
                                                  await authProvider.login(
                                                _emailController.text.trim(),
                                                _passwordController.text.trim(),
                                              );
                                              if (!success && context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        authProvider.error ??
                                                            'Login failed'),
                                                    backgroundColor:
                                                        AppTheme.error,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppTheme.radiusSm,
                                      ),
                                    ),
                                    child: authProvider.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward,
                                                  size: 18,
                                                  color: Colors.white),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Divider(color: AppTheme.border),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            '© 2025 Marriage Station Pvt. Ltd.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}