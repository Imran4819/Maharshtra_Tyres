import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maharashtra_tyres/theme/app_theme.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
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

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final input = _identifierController.text.trim();
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    final isPhone = RegExp(r'^\+?[0-9]{10,12}$').hasMatch(input.replaceAll(' ', '')) &&
        (digitsOnly.length == 10 || (digitsOnly.length == 12 && digitsOnly.startsWith('91')));

    String formattedTarget = '';
    Map<String, dynamic> requestBody = {};

    if (isPhone) {
      if (digitsOnly.length == 10) {
        formattedTarget = '+91$digitsOnly';
      } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
        formattedTarget = '+$digitsOnly';
      } else {
        formattedTarget = input;
      }
      requestBody = {'phone': formattedTarget};
    } else {
      formattedTarget = input.toLowerCase();
      requestBody = {'email': formattedTarget};
    }

    try {
      final response = await http.post(
        Uri.parse('https://business-management-ji66.onrender.com/auth/generate-otp'),
        headers: {
          'accept': '*/*',
          'content-type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushNamed(
          context,
          '/otp-verify',
          arguments: formattedTarget,
        );
      } else {
        String errorMsg = 'Failed to send OTP. Please try again.';
        try {
          final resData = jsonDecode(response.body);
          if (resData is Map && resData.containsKey('message')) {
            errorMsg = resData['message'];
          }
        } catch (_) {}
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              AppColors.primarySoft.withValues(alpha: 0.7),
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
                bottom: -60,
                left: -50,
                child: _GlowBlob(color: AppColors.primary.withValues(alpha: 0.06), size: 230),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: size.width < 560 ? 460 : 520,
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
                                  Icons.sms_rounded,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Login with OTP',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your email or mobile number to receive a verification code.',
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
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                hintText: 'Enter email or 10-digit mobile number',
                                prefixIcon: Icon(Icons.mark_email_read_outlined),
                              ),
                              validator: _validateIdentifier,
                              onFieldSubmitted: (_) => _sendOtp(),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'We will send a one-time code to your registered email or mobile number for secure access.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                             SizedBox(
                               height: 54,
                               child: ElevatedButton(
                                 onPressed: _isLoading ? null : _sendOtp,
                                 child: _isLoading
                                     ? const SizedBox(
                                         width: 20,
                                         height: 20,
                                         child: CircularProgressIndicator(
                                           strokeWidth: 2,
                                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                         ),
                                       )
                                     : const Text('Send OTP'),
                               ),
                             ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.maybePop(context);
                              },
                              child: const Text('Use password login'),
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
