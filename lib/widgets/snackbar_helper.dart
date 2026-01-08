import 'package:flutter/material.dart';
import 'package:playcado/widgets/widgets.dart';

class SnackbarHelper {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: PlaycadoIcons.check,
      backgroundColor: Colors.green.shade700,
      foregroundColor: Colors.white,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      icon: PlaycadoIcons.error,
      backgroundColor: Theme.of(context).colorScheme.error,
      foregroundColor: Theme.of(context).colorScheme.onError,
    );
  }

  static void showInfo(BuildContext context, String message) {
    final theme = Theme.of(context);
    _show(
      context,
      message,
      icon: PlaycadoIcons.info,
      backgroundColor: theme.colorScheme.inverseSurface,
      foregroundColor: theme.colorScheme.onInverseSurface,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required PlaycadoIcons icon,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              PlaycadoIcon(icon, color: foregroundColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          elevation: 4,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
