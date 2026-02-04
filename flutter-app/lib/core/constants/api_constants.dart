class ApiConstants {
  // All requests go through the API gateway
  static const int gatewayPort = 8084;

  // Single base URL through gateway
  static String baseUrl(String serverIp) => 'http://$serverIp:$gatewayPort';

  // Legacy methods for backward compatibility - all point to gateway now
  static String authBaseUrl(String serverIp) => baseUrl(serverIp);
  static String notesBaseUrl(String serverIp) => baseUrl(serverIp);
  static String mindmapBaseUrl(String serverIp) => baseUrl(serverIp);
  static String workflowBaseUrl(String serverIp) => baseUrl(serverIp);

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
