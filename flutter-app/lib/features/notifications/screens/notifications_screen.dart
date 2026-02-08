import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/notification_models.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(notificationRepositoryProvider);
      final notifications = await repository.getUnreadNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.markAsRead(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
      // Refresh the unread count
      ref.read(unreadNotificationCountProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as read: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.markAllAsRead();
      setState(() {
        _notifications.clear();
      });
      // Refresh the unread count
      ref.read(unreadNotificationCountProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark all as read: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading notifications...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadNotifications,
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "You're all caught up!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withAlpha(150),
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _NotificationCard(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _markAsRead(notification),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    _markAsRead(notification);

    // Navigate based on notification type
    if (notification.referenceType == 'note' && notification.referenceId != null) {
      Navigator.pushNamed(
        context,
        '/student/note/${notification.referenceId}',
      );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Icon(
          Icons.check_circle_outline,
          color: AppColors.primary,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: notification.read
                  ? AppColors.surface
                  : AppColors.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: notification.read
                    ? AppColors.border
                    : AppColors.primary.withAlpha(30),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: notification.iconColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: notification.read
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                            ),
                          ),
                          Text(
                            notification.timeAgo,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
