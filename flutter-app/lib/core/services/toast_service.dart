import 'package:flutter/material.dart';

/// Global key for showing snackbars from anywhere in the app
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Service for showing toast messages globally
class ToastService {
  static void show({
    required String message,
    String? title,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    // Dismiss any existing snackbar
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: title != null ? 13 : 14,
                      color: title != null ? Colors.white70 : Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: action,
      ),
    );
  }

  static void showNotification({
    required String title,
    required String message,
    IconData icon = Icons.notifications,
    Color? iconBackgroundColor,
    VoidCallback? onTap,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBackgroundColor?.withOpacity(0.2) ??
                    Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconBackgroundColor ?? Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        action: onTap != null
            ? SnackBarAction(
                label: 'View',
                textColor: const Color(0xFF14B8A6),
                onPressed: onTap,
              )
            : null,
      ),
    );
  }

  static void showSuccess(String message) {
    show(
      message: message,
      icon: Icons.check_circle,
      backgroundColor: const Color(0xFF10B981),
    );
  }

  static void showError(String message) {
    show(
      message: message,
      icon: Icons.error,
      backgroundColor: const Color(0xFFEF4444),
    );
  }

  static void showInfo(String message) {
    show(
      message: message,
      icon: Icons.info,
      backgroundColor: const Color(0xFF3B82F6),
    );
  }
}
