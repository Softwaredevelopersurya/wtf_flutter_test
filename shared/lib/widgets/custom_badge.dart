import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

class CustomBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const CustomBadge({
    super.key,
    required this.text,
    this.backgroundColor = AppColors.guruPrimary,
    this.textColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: backgroundColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: backgroundColor),
            AppSpacing.gapH4,
          ],
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: backgroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RoleAppBarTitle extends StatelessWidget {
  final String title;
  final String roleBadge;
  final Color roleColor;

  const RoleAppBarTitle({
    super.key,
    required this.title,
    required this.roleBadge,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTypography.h2),
        AppSpacing.gapH8,
        CustomBadge(
          text: roleBadge,
          backgroundColor: roleColor,
        ),
      ],
    );
  }
}

