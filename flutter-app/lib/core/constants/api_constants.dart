class ApiConstants {
  // All requests go through the API gateway
  static const int gatewayPort = 8084;

  // Default ngrok URL (used when no server address is provided)
  static const String defaultNgrokUrl = 'https://deiform-nonruminatingly-aleah.ngrok-free.dev';

  // Single base URL through gateway
  // Supports both IP addresses (e.g., "192.168.1.100") and full URLs (e.g., "https://xyz.ngrok-free.dev")
  static String baseUrl(String? serverAddress) {
    // If no address provided or empty, use default ngrok URL
    if (serverAddress == null || serverAddress.trim().isEmpty) {
      return defaultNgrokUrl;
    }

    // If it's already a full URL (starts with http:// or https://), use it directly
    if (serverAddress.startsWith('http://') || serverAddress.startsWith('https://')) {
      // Remove trailing slash if present
      return serverAddress.endsWith('/')
          ? serverAddress.substring(0, serverAddress.length - 1)
          : serverAddress;
    }
    // Otherwise, treat it as an IP address and add the port
    return 'http://$serverAddress:$gatewayPort';
  }

  // Legacy methods for backward compatibility - all point to gateway now
  static String authBaseUrl(String? serverAddress) => baseUrl(serverAddress);
  static String notesBaseUrl(String? serverAddress) => baseUrl(serverAddress);
  static String mindmapBaseUrl(String? serverAddress) => baseUrl(serverAddress);
  static String workflowBaseUrl(String? serverAddress) => baseUrl(serverAddress);

  // Auth endpoints (gateway routes /v1/auth/** -> auth-service /auth/**)
  static const String login = '/v1/auth/login';
  static const String signup = '/v1/auth/signup';
  static const String refreshToken = '/v1/auth/refresh';
  static const String forgotPassword = '/v1/auth/forgot-password';
  static const String resolve = '/v1/auth/resolve';

  // Notes endpoints (gateway routes /v1/notes/** -> notes-service /notes/**)
  static const String notes = '/v1/notes';

  // Mindmap endpoints (gateway routes /v1/mindmaps/** -> mindmap-service /mindmaps/**)
  static const String mindmaps = '/v1/mindmaps';

  // Workflow endpoints (gateway routes /v1/workflow/** -> workflow-service /workflow/**)
  static const String workflow = '/v1/workflow';
  static const String release = '/v1/workflow/release';

  // Classes endpoints (gateway routes /v1/classes/** -> workflow-service /classes/**)
  static const String classes = '/v1/classes';

  // Notification endpoints (gateway routes /v1/notifications/** -> recall-service /v1/notifications/**)
  static const String notifications = '/v1/notifications';
  static const String notificationsUnread = '/v1/notifications/unread';
  static const String notificationsUnreadCount = '/v1/notifications/unread/count';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String tenantId = 'tenant_id';
  static const String serverIp = 'server_ip';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String userType = 'user_type';
}
