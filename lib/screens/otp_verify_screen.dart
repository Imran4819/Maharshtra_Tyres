import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';
import 'package:maharashtra_tyres/services/web_storage_helper.dart';
import 'package:maharashtra_tyres/services/auth_service.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _verified = false;
  bool _isLoading = false;
  String _targetIdentifier = '';
  String _code = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_targetIdentifier.isEmpty) {
      final value = ModalRoute.of(context)?.settings.arguments as String?;
      _targetIdentifier = value?.trim() ?? '';
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isPhone => !_targetIdentifier.contains('@');

  String get _displayIdentifier {
    if (_isPhone && _targetIdentifier.startsWith('+91') && _targetIdentifier.length == 13) {
      return '+91 ${_targetIdentifier.substring(3, 8)} ${_targetIdentifier.substring(8)}';
    }
    return _targetIdentifier.isEmpty ? 'your account' : _targetIdentifier;
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isLoading) return;
    _clearCode();

    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> body = _isPhone
        ? {'phone': _targetIdentifier}
        : {'email': _targetIdentifier.toLowerCase()};

    try {
      final response = await http.post(
        Uri.parse('https://business-management-ji66.onrender.com/auth/generate-otp'),
        headers: {
          'accept': '*/*',
          'content-type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent again.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        String errorMsg = 'Failed to resend OTP. Please try again.';
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

  void _clearCode() {
    for (final controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _code = '';
      _verified = false;
    });
    _focusNodes.first.requestFocus();
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      _fillPastedCode(value);
      return;
    }

    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    _syncCode();
  }

  void _fillPastedCode(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }

    _syncCode();

    final nextIndex = digits.length.clamp(0, _focusNodes.length - 1).toInt();
    _focusNodes[nextIndex].requestFocus();
  }

  void _syncCode() {
    final otp = _controllers.map((controller) => controller.text).join();
    setState(() {
      _code = otp;
      if (otp.length != 4) {
        _verified = false;
      }
    });

    if (otp.length == 4) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the full 4-digit code.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> body = _isPhone
        ? {'phone': _targetIdentifier, 'otp': _code}
        : {'email': _targetIdentifier.toLowerCase(), 'otp': _code};

    try {
      final response = await http.post(
        Uri.parse('https://business-management-ji66.onrender.com/auth/verify-otp'),
        headers: {
          'accept': '*/*',
          'content-type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        final String? token = resData is Map
            ? (resData['token'] ??
                resData['accessToken'] ??
                resData['access_token'] ??
                (resData['data'] is Map ? resData['data']['token'] : null) ??
                (resData['data'] is Map ? resData['data']['accessToken'] : null))
            : null;

        setState(() {
          _verified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully.'),
            backgroundColor: AppColors.success,
          ),
        );

        Future.delayed(const Duration(milliseconds: 350), () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('logged_user_identifier', _targetIdentifier);
          if (token != null) {
            await prefs.setString('auth_token', token);
            saveTokenToWebStorage(token);
            try {
              final payload = AuthService.decodeJwt(token);
              final clientId = payload['client_id']?.toString();
              if (clientId != null) {
                await prefs.setString('client_id', clientId);
              }
            } catch (_) {}
          }
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/dashboard');
        });
      } else {
        String errorMsg = 'Invalid OTP. Please check and try again.';
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
        _clearCode();
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
                                Icons.phonelink_lock_rounded,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Verify OTP',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the 4-digit code sent to $_displayIdentifier',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (index) {
                              return SizedBox(
                                width: 56,
                                height: 64,
                                child: TextFormField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 4,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: '0',
                                    hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                                    ),
                                  ),
                                  onChanged: (value) => _onChanged(value, index),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          if (_verified)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified_rounded, color: AppColors.success),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'OTP verified successfully.',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_verified) const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_canResend) ...[
                                const Icon(Icons.timer_outlined, size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Resend in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ] else ...[
                                Text(
                                  'Didn\'t get the code?',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                TextButton(
                                  onPressed: _isLoading ? null : _resendOtp,
                                  child: const Text('Resend OTP'),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyOtp,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Verify OTP'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.maybePop(context);
                                  },
                            child: const Text('Change mobile number'),
                          ),
                        ],
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
