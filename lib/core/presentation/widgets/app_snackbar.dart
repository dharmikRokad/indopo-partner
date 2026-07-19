import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFF052914),
      borderColor: AppColors.success,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFF1C0505),
      borderColor: AppColors.error,
      icon: Icons.error_rounded,
      iconColor: AppColors.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFF1C1205),
      borderColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFF03122C),
      borderColor: AppColors.info,
      icon: Icons.info_rounded,
      iconColor: AppColors.info,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
