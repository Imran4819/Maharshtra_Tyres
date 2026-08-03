import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';

class OtpInputRow extends StatefulWidget {
  const OtpInputRow({
    super.key,
    this.length = 6,
    required this.onCompleted,
  });

  final int length;
  final ValueChanged<String> onCompleted;

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged(String value, int index) {
    // Handle paste: distribute digits across boxes
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final lastFilled = digits.length < widget.length ? digits.length : widget.length - 1;
      _focusNodes[lastFilled].requestFocus();
    } else if (value.length == 1) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    // Check if completed
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            autofocus: index == 0,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              LengthLimitingTextInputFormatter(6),
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
            onChanged: (value) => _onFieldChanged(value, index),
          ),
        );
      }),
    );
  }
}
