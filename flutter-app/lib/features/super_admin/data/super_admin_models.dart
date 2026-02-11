import 'package:equatable/equatable.dart';

/// School (Tenant) model
class School extends Equatable {
  final String id;
  final String tenantKey;
  final String name;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const School({
    required this.id,
    required this.tenantKey,
    required this.name,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory School.fromJson(Map<String, dynamic> json) => School(
        id: json['id'] ?? '',
        tenantKey: json['tenantKey'] ?? '',
        name: json['name'] ?? '',
        status: json['status'] ?? 'ACTIVE',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantKey': tenantKey,
        'name': name,
        'status': status,
      };

  @override
  List<Object?> get props => [id, tenantKey, name, status];
}

/// Create school request
class CreateSchoolRequest {
  final String tenantKey;
  final String name;

  const CreateSchoolRequest({
    required this.tenantKey,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'tenantKey': tenantKey,
        'name': name,
      };
}

/// User profile model for super admin
class UserProfile extends Equatable {
  final String id;
  final String tenantId;
  final String userId;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String userType;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? schoolName; // Added for display purposes

  const UserProfile({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.displayName,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.userType,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.schoolName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] ?? '',
        tenantId: json['tenantId'] ?? '',
        userId: json['userId'] ?? '',
        displayName: json['displayName'] ?? '',
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        phone: json['phone'],
        avatarUrl: json['avatarUrl'],
        userType: json['userType'] ?? 'STUDENT',
        status: json['status'] ?? 'ACTIVE',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
        schoolName: json['schoolName'],
      );

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return displayName;
  }

  bool get isTeacher => userType == 'TEACHER' || userType == 'ADMIN' || userType == 'PRINCIPAL';
  bool get isStudent => userType == 'STUDENT';

  @override
  List<Object?> get props => [id, tenantId, userId, displayName, userType, status];
}

/// Create user profile request
class CreateUserProfileRequest {
  final String userId;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String userType;
  final String status;

  const CreateUserProfileRequest({
    required this.userId,
    required this.displayName,
    this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    required this.userType,
    this.status = 'ACTIVE',
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        'email': email,
        if (phone != null) 'phone': phone,
        'userType': userType,
        'status': status,
      };
}

/// Role model (tenant-scoped)
class Role extends Equatable {
  final int id;
  final String name;
  final String? description;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Role({
    required this.id,
    required this.name,
    this.description,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: (json['id'] as num).toInt(),
        name: json['name'] ?? '',
        description: json['description'],
        active: json['active'] ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'])
            : null,
      );

  @override
  List<Object?> get props => [id, name, active];
}

/// Permission model (global)
class Permission extends Equatable {
  final int id;
  final String code;
  final String? resource;
  final String? action;
  final String? description;
  final bool active;
  final DateTime? createdAt;

  const Permission({
    required this.id,
    required this.code,
    this.resource,
    this.action,
    this.description,
    this.active = true,
    this.createdAt,
  });

  factory Permission.fromJson(Map<String, dynamic> json) => Permission(
        id: (json['id'] as num).toInt(),
        code: json['code'] ?? json['name'] ?? '',
        resource: json['resource'],
        action: json['action'],
        description: json['description'],
        active: json['active'] ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
      );

  String get displayLabel =>
      resource != null && action != null ? '$resource:$action' : code;

  @override
  List<Object?> get props => [id, code, active];
}

/// Role-permission grant (links a permission to a role)
class RolePermissionGrant extends Equatable {
  final int id;
  final int roleId;
  final String permissionCode;
  final String? scopeCode;
  final DateTime? createdAt;

  const RolePermissionGrant({
    required this.id,
    required this.roleId,
    required this.permissionCode,
    this.scopeCode,
    this.createdAt,
  });

  factory RolePermissionGrant.fromJson(Map<String, dynamic> json) =>
      RolePermissionGrant(
        id: (json['id'] as num).toInt(),
        roleId: (json['roleId'] as num).toInt(),
        permissionCode: json['permissionCode'] ?? '',
        scopeCode: json['scopeCode'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
      );

  @override
  List<Object?> get props => [id, roleId, permissionCode];
}

/// Create user identity request (for auth service)
class CreateUserIdentityRequest {
  final String email;
  final String password;
  final String tenantId;

  const CreateUserIdentityRequest({
    required this.email,
    required this.password,
    required this.tenantId,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'tenantId': tenantId,
      };
}

/// User identity response from auth service
class UserIdentity {
  final String id;
  final String email;
  final String status;

  const UserIdentity({
    required this.id,
    required this.email,
    required this.status,
  });

  factory UserIdentity.fromJson(Map<String, dynamic> json) => UserIdentity(
        id: json['id'] ?? json['userId'] ?? '',
        email: json['email'] ?? json['primaryEmail'] ?? '',
        status: json['status'] ?? 'ACTIVE',
      );
}
