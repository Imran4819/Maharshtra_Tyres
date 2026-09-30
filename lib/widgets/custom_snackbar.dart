import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';

enum SnackBarType { success, error, warning, info }

void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.info,
  bool isError = false,
  bool isSuccess = false,
  Duration duration = const Duration(seconds: 3),
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final bool effectiveError = isError || type == SnackBarType.error;
  final bool effectiveSuccess = isSuccess || type == SnackBarType.success;
  final bool effectiveWarning = type == SnackBarType.warning;

  final Color bgColor = effectiveError
      ? AppColors.error
      : effectiveSuccess
          ? AppColors.primary
          : effectiveWarning
              ? AppColors.warning
              : (isDark ? AppColors.surfaceDark : AppColors.primaryDark);

  final IconData iconData = effectiveError
      ? Icons.error_outline_rounded
      : effectiveSuccess
          ? Icons.check_circle_rounded
          : effectiveWarning
              ? Icons.warning_amber_rounded
              : Icons.info_outline_rounded;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: effectiveSuccess
              ? AppColors.primaryAccent
              : effectiveError
                  ? Colors.redAccent.withValues(alpha: 0.5)
                  : AppColors.primaryAccent.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

