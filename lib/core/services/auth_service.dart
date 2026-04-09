import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:elimupepe/core/services/webview_session_service.dart';

class LoginResult {
  final bool success;
  final String message;
  final int? roleId;
  final String? roleName;

  const LoginResult({
    required this.success,
    required this.message,
    this.roleId,
    this.roleName,
  });
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  static const String _baseUrl = 'https://elimupepe.loholearning.co.ke/api';
  static const String _tokenKey = 'auth_token';
  static const String _passportTokenKey = 'passport_token';
  static const String _emailKey = 'auth_email';
  static const String _userIdKey = 'auth_user_id';
  static const String _roleIdKey = 'auth_role_id';
  static const String _roleNameKey = 'auth_role_name';
  static const Set<int> _allowedRoleIds = {2, 3, 7};
  static const Set<String> _allowedRoleNames = {
    'student',
    'parent',
    'teacher',
    'guardian',
    'educator',
  };

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim();
      Response<dynamic> response = await _dio.post(
        '/v1/auth/login',
        data: {'email': normalizedEmail, 'password': password},
        options: Options(validateStatus: (_) => true),
      );

      // Some accounts require confirmation to logout other active devices.
      // Retry with force=true to complete the login handshake automatically.
      if (_hasMultipleLoginConflict(response.data)) {
        response = await _dio.post(
          '/v1/auth/login',
          data: {'email': normalizedEmail, 'password': password, 'force': true},
          options: Options(validateStatus: (_) => true),
        );
      }

      if (response.statusCode != 200) {
        final message =
            _extractErrorMessage(response.data) ??
            'Login failed. Please check your credentials.';
        return LoginResult(success: false, message: message);
      }

      final data = response.data;
      final token = _extractToken(data);

      if (token == null || token.isEmpty) {
        return const LoginResult(
          success: false,
          message: 'Login response missing token.',
        );
      }

      var user = _extractUser(data);
      if (_extractRoleId(user) == null) {
        final fetchedUser = await _fetchCurrentUser(token);
        if (fetchedUser.isNotEmpty) {
          user = fetchedUser;
        }
      }

      final roleId = _extractRoleId(user);
      final roleName = _extractRoleName(user);

      if (!_isAllowedRole(roleId: roleId, roleName: roleName)) {
        return const LoginResult(
          success: false,
          message:
              'Access denied. This app is available to student, parent, and teacher accounts.',
        );
      }

      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _passportTokenKey, value: token);
      await _secureStorage.write(
        key: _emailKey,
        value: user['email'] ?? normalizedEmail,
      );
      await _secureStorage.write(
        key: _userIdKey,
        value: user['id']?.toString() ?? '',
      );
      if (roleId != null) {
        await _secureStorage.write(key: _roleIdKey, value: roleId.toString());
      }
      if (roleName != null && roleName.isNotEmpty) {
        await _secureStorage.write(key: _roleNameKey, value: roleName);
      }

      return LoginResult(
        success: true,
        message: 'Login successful',
        roleId: roleId,
        roleName: roleName,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return const LoginResult(
          success: false,
          message: 'Invalid credentials or account not allowed.',
        );
      }

      final serverMessage = _extractErrorMessage(e.response?.data);
      return LoginResult(
        success: false,
        message: serverMessage ?? 'Could not connect to login server.',
      );
    } catch (_) {
      return const LoginResult(
        success: false,
        message: 'Unexpected login error. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      try {
        await _dio.get(
          '/v1/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {
        // Ignore remote logout errors and proceed with local token cleanup.
      }
    }

    await _clearSavedSession();
    await WebViewSessionService.clear();
  }

  Future<bool> deleteAccount() async {
    final token = await getToken();

    if (token != null && token.isNotEmpty) {
      try {
        final response = await _dio.delete(
          '/v1/auth/delete-account',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          await _clearSavedSession();
          await WebViewSessionService.clear();
          return true;
        }
      } catch (_) {
        // If the API call fails, we still want to clear local data and return false
        // to indicate the remote deletion might not have completed.
      }
    }

    await _clearSavedSession();
    await WebViewSessionService.clear();
    return false;
  }

  Future<String?> getToken() async {
    return _readSecureValue(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<int?> getSavedRoleId() async {
    final raw = await _readSecureValue(_roleIdKey);
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<int?> getSavedUserId() async {
    final raw = await _readSecureValue(_userIdKey);
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<String?> getSavedRoleName() async {
    final raw = await _readSecureValue(_roleNameKey);
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<bool> validateSession() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final response = await _dio.get(
        '/v1/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await logout();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      final fetchedUser = await _fetchCurrentUser(token);
      if (fetchedUser.isNotEmpty) {
        return fetchedUser;
      }
    }

    final email = await _readSecureValue(_emailKey);
    final userId = await _readSecureValue(_userIdKey);

    if ((email != null && email.isNotEmpty) ||
        (userId != null && userId.isNotEmpty)) {
      final parsedId = userId != null && userId.isNotEmpty
          ? int.tryParse(userId) ?? userId
          : null;
      return {
        if (email != null && email.isNotEmpty) 'email': email,
        if (parsedId != null) 'id': parsedId,
      };
    }

    return {};
  }

  String? _extractToken(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final directToken = payload['token'] ?? payload['access_token'];
    if (directToken is String && directToken.isNotEmpty) {
      return directToken;
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final nestedToken = data['token'] ?? data['access_token'];
      if (nestedToken is String && nestedToken.isNotEmpty) {
        return nestedToken;
      }
    }

    return null;
  }

  Map<String, dynamic> _extractUser(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return {};
    }

    final user = payload['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      if (data.containsKey('role_id')) {
        return data;
      }

      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) {
        return nestedUser;
      }
    }

    return {};
  }

  String? _extractErrorMessage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final message = payload['message'] ?? payload['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return null;
  }

  bool _hasMultipleLoginConflict(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return false;
    }

    final multipleLogin =
        payload['multipleLogin'] ??
        payload['multiple_login'] ??
        payload['multiple_login_error'];
    if (multipleLogin is bool) {
      return multipleLogin;
    }

    if (multipleLogin is String) {
      return multipleLogin.toLowerCase() == 'true' || multipleLogin == '1';
    }

    if (multipleLogin is int) {
      return multipleLogin == 1;
    }

    final message = payload['message'];
    if (message is String) {
      final normalized = message.toLowerCase();
      return normalized.contains('already logged in') &&
          normalized.contains('other device');
    }

    return false;
  }

  int? _extractRoleId(Map<String, dynamic> user) {
    final roleRaw = user['role_id'] ?? user['roleId'];
    if (roleRaw is int) {
      return roleRaw;
    }
    if (roleRaw is String) {
      return int.tryParse(roleRaw);
    }
    return null;
  }

  String? _extractRoleName(Map<String, dynamic> user) {
    final direct = user['role_name'] ?? user['roleName'] ?? user['role'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim().toLowerCase();
    }

    if (direct is Map<String, dynamic>) {
      final nested =
          direct['name'] ??
          direct['slug'] ??
          direct['title'] ??
          direct['label'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim().toLowerCase();
      }
    }

    final type = user['role_type'] ?? user['roleType'];
    if (type is String && type.trim().isNotEmpty) {
      return type.trim().toLowerCase();
    }

    return null;
  }

  bool _isAllowedRole({int? roleId, String? roleName}) {
    if (roleId == null && (roleName == null || roleName.isEmpty)) {
      return true;
    }

    if (roleId != null && _allowedRoleIds.contains(roleId)) {
      return true;
    }

    if (roleName != null && _allowedRoleNames.contains(roleName)) {
      return true;
    }

    return false;
  }

  Future<Map<String, dynamic>> _fetchCurrentUser(String token) async {
    try {
      final response = await _dio.get(
        '/v1/auth/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        final data = payload['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (_) {
      // If profile fetch fails, return empty map and let role validation fail safely.
    }

    return {};
  }

  Future<String?> _readSecureValue(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      await _clearSavedSession();
      return null;
    }
  }

  Future<void> _clearSavedSession() async {
    for (final key in const [
      _tokenKey,
      _passportTokenKey,
      _emailKey,
      _userIdKey,
      _roleIdKey,
      _roleNameKey,
    ]) {
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {
        // Ignore cleanup failures so corrupted secure storage never crashes auth.
      }
    }
  }
}
