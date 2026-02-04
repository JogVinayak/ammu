import 'package:equatable/equatable.dart';

class LoginRequest {
  final String? tenantId; // Optional - backend auto-resolves from email if not provided
  final String identifier;
  final String password;
  final String otp;

  LoginRequest({
    this.tenantId,
    required this.identifier,
    required this.password,
    this.otp = '',
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'identifier': identifier,
      'password': password,
    };
    if (tenantId != null && tenantId!.isNotEmpty) {
      map['tenantId'] = tenantId;
    }
    if (otp.isNotEmpty) {
      map['otp'] = otp;
    }
    return map;
  }
}

class LoginResponse extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String tenantId;
  final String? displayName;
  final String? userType; // STUDENT, TEACHER, ADMIN, PRINCIPAL, etc.

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.tenantId,
    this.displayName,
    this.userType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['accessToken'] ?? '',
        refreshToken: json['refreshToken'] ?? '',
        userId: json['userId'] ?? '',
        tenantId: json['tenantId'] ?? '',
        displayName: json['displayName'],
        userType: json['userType'],
      );

  @override
  List<Object?> get props => [accessToken, refreshToken, userId, tenantId, displayName, userType];
}

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String tenantId;
  final String? avatar;
  final String? userType; // STUDENT, TEACHER, ADMIN, PRINCIPAL, etc.

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.tenantId,
    this.avatar,
    this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] ?? json['userId'] ?? '',
        name: json['name'] ?? json['displayName'] ?? '',
        email: json['email'] ?? '',
        tenantId: json['tenantId'] ?? '',
        avatar: json['avatar'],
        userType: json['userType'],
      );

  bool get isTeacher => userType == 'TEACHER' || userType == 'PRINCIPAL' || userType == 'ADMIN';
  bool get isStudent => userType == 'STUDENT';
  bool get isAdmin => userType == 'ADMIN' || userType == 'PRINCIPAL';

  @override
  List<Object?> get props => [id, name, email, tenantId, avatar, userType];
}
