import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/services/auth_service.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedIdentifier();
  }

  Future<void> _loadSavedIdentifier() async {
    final saved = await AuthService.getSavedIdentifier();
    if (saved != null && saved.isNotEmpty && mounted) {
      _identifierController.text = saved;
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Email or mobile number is required';
    }

    final emailPattern = RegExp(
      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
      caseSensitive: false,
    );
    final phonePattern = RegExp(r'^\+?[0-9]{10,12}$');
    final cleanedPhone = input.replaceAll(RegExp(r'[\s-]'), '');

    if (!emailPattern.hasMatch(input) && !phonePattern.hasMatch(cleanedPhone)) {
      return 'Enter a valid email address or 10-digit mobile number';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final error = await AuthService.login(
      identifier: _identifierController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              Colors.white,
              AppColors.primarySoft.withValues(alpha: 0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: _GlowBlob(color: AppColors.primary.withValues(alpha: 0.08), size: 180),
              ),
              Positioned(
                bottom: -50,
                left: -40,
                child: _GlowBlob(color: AppColors.primary.withValues(alpha: 0.06), size: 220),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: size.width < 560 ? 480 : 520,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.directions_car_rounded,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Welcome back',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to manage billing, customers, and inventory.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 28),
                            _FieldLabel(
                              label: 'Email or mobile number',
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _identifierController,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                              decoration: const InputDecoration(
                                hintText: 'Enter your email or 10-digit mobile number',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: _validateIdentifier,
                            ),
                            const SizedBox(height: 20),
                            _FieldLabel(
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.password_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: _validatePassword,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password recovery is not connected yet.'),
                                      ),
                                    );
                                  },
                                  child: const Text('Forgot password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Log in'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/otp-login');
                              },
                              icon: const Icon(Icons.sms_outlined),
                              label: const Text('Login with OTP'),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'Secure access',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Use your registered credentials to continue to the management dashboard.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FieldLabel({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
