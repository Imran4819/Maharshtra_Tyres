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
    final isDesktop = size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Single cohesive slate background
      body: Stack(
        children: [
          // Soft ambient blobs
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 480 : 440,
                ),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo icon
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.sms_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Login with OTP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your email or mobile number to receive a verification code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Email/Phone Input
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Email or mobile number',
                            hintText: 'Enter email or 10-digit number',
                            prefixIcon: Icon(Icons.mark_email_read_outlined, size: 20),
                          ),
                          validator: _validateIdentifier,
                          onFieldSubmitted: (_) => _sendOtp(),
                        ),
                        const SizedBox(height: 18),
                        // Secure alert box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'We will send a one-time code to your registered email or mobile number for secure access.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Send OTP button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
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
                        const SizedBox(height: 14),
                        // Password login option
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.maybePop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text(
                              'Use password login',
                              style: TextStyle(fontWeight: FontWeight.w700),
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
