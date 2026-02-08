import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/notification_repository.dart';
import '../screens/notifications_screen.dart';

/// A notification bell icon with badge showing unread count
class NotificationBadge extends ConsumerWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationBadge({
    super.key,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: iconColor ?? AppColors.textPrimary,
            size: iconSize,
          ),
          unreadCountAsync.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444), // Red
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
        // Refresh count when returning from notifications screen
        ref.read(unreadNotificationCountProvider.notifier).refresh();
      },
      tooltip: 'Notifications',
    );
  }
}

/// A simple dot indicator for unread notifications
class NotificationDot extends ConsumerWidget {
  const NotificationDot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return unreadCountAsync.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
