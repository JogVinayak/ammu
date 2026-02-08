import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/toast_service.dart';
import 'notification_models.dart';

class NotificationRepository {
  final DioClient _dioClient;

  NotificationRepository(this._dioClient);

  /// Get paginated notifications
  Future<List<AppNotification>> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.notifications,
        queryParameters: {'page': page, 'size': size},
      );

      final data = response.data;
      if (data is Map && data['content'] != null) {
        return (data['content'] as List)
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw _handleError(e);
    }
  }

  /// Get all unread notifications
  Future<List<AppNotification>> getUnreadNotifications() async {
    try {
      final response = await _dioClient.get(ApiConstants.notificationsUnread);

      final data = response.data;
      if (data is Map && data['items'] != null) {
        return (data['items'] as List)
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw _handleError(e);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.get(ApiConstants.notificationsUnreadCount);

      final data = response.data;
      if (data is Map && data['count'] != null) {
        return (data['count'] as num).toInt();
      }
      return 0;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return 0;
      }
      throw _handleError(e);
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.notifications}/$notificationId/read',
      );

      final data = response.data;
      return data is Map && data['success'] == true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.notifications}/read-all',
      );

      final data = response.data;
      if (data is Map && data['updated'] != null) {
        return (data['updated'] as num).toInt();
      }
      return 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'];
      }
      switch (e.response!.statusCode) {
        case 400:
          return 'Invalid request';
        case 401:
          return 'Unauthorized';
        case 403:
          return 'Access denied';
        case 404:
          return 'Not found';
        case 500:
          return 'Server error';
        default:
          return 'Something went wrong';
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server';
    }
    return 'Network error';
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dioClient = ref.watch(notesDioClientProvider);
  return NotificationRepository(dioClient);
});

/// Notifier that polls for unread notification count every 30 seconds
class UnreadCountNotifier extends AutoDisposeAsyncNotifier<int> {
  Timer? _timer;
  static const _pollInterval = Duration(seconds: 30);

  @override
  Future<int> build() async {
    // Start polling when first built
    _startPolling();

    // Clean up timer when disposed
    ref.onDispose(() {
      _timer?.cancel();
    });

    return _fetchCount();
  }

  Future<int> _fetchCount() async {
    final repository = ref.read(notificationRepositoryProvider);
    return repository.getUnreadCount();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) {
      refresh();
    });
  }

  /// Manually refresh the count
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCount());
  }
}

final unreadNotificationCountProvider =
    AsyncNotifierProvider.autoDispose<UnreadCountNotifier, int>(
  UnreadCountNotifier.new,
);

/// Notifier that polls for notifications every 30 seconds
class NotificationsNotifier extends AutoDisposeAsyncNotifier<List<AppNotification>> {
  Timer? _timer;
  static const _pollInterval = Duration(seconds: 30);

  // Track previously seen notification IDs to detect new ones
  final Set<String> _seenNotificationIds = {};
  bool _isFirstLoad = true;

  @override
  Future<List<AppNotification>> build() async {
    // Start polling when first built
    _startPolling();

    // Clean up timer when disposed
    ref.onDispose(() {
      _timer?.cancel();
    });

    return _fetchNotifications();
  }

  Future<List<AppNotification>> _fetchNotifications() async {
    final repository = ref.read(notificationRepositoryProvider);
    final notifications = await repository.getUnreadNotifications();

    // Check for new notifications (skip on first load)
    if (!_isFirstLoad) {
      for (final notification in notifications) {
        if (!_seenNotificationIds.contains(notification.id)) {
          // This is a new notification - show toast
          _showNotificationToast(notification);
        }
      }
    }

    // Update seen IDs
    _seenNotificationIds.clear();
    for (final notification in notifications) {
      _seenNotificationIds.add(notification.id);
    }

    _isFirstLoad = false;
    return notifications;
  }

  void _showNotificationToast(AppNotification notification) {
    ToastService.showNotification(
      title: notification.title,
      message: notification.message,
      icon: notification.icon,
      iconBackgroundColor: notification.iconColor,
    );
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) {
      refresh();
    });
  }

  /// Manually refresh the notifications
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNotifications());
  }
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);
