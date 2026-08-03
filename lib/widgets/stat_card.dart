import 'package:flutter/material.dart';
import 'package:maharashtra_tyres/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.trendText,
    this.trendIcon,
    this.gradient,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String? trendText;
  final IconData? trendIcon;
  final LinearGradient? gradient;
  final VoidCallback? onTap;

  bool get _hasGradient => gradient != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          color: _hasGradient ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _hasGradient
                  ? gradient!.colors.first.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon on the right, title on the left
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _hasGradient
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _hasGradient
                        ? Colors.white.withValues(alpha: 0.2)
                        : iconBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: _hasGradient ? Colors.white : iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Value
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _hasGradient ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            // Trend row
            if (trendText != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    trendIcon ?? Icons.trending_up,
                    size: 14,
                    color: _hasGradient
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trendText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _hasGradient
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
