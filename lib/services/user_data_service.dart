import 'auth_service.dart';
import 'package:dio/dio.dart';

class UserDataService {
  static final UserDataService instance = UserDataService._internal();
  factory UserDataService() => instance;
  UserDataService._internal();

  static const String _baseUrl = 'https://elimupepe.loholearning.co.ke/api';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// Fetches the logged-in user's profile and settings data
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null || token.isEmpty) return null;

      final response = await _dio.post(
        '/student/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
    } catch (e) {
      // Log error or handle token expiration
    }
    return null;
  }

  /// Fetches the dynamically generated leaderboard data
  Future<List<dynamic>?> fetchLeaderboard() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null || token.isEmpty) return null;

      final response = await _dio.get(
        '/student/leaderboard',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Depending on your API structure, data might be nested inside a 'data' object
        if (response.data is Map && response.data.containsKey('data')) {
          return response.data['data'] as List<dynamic>;
        } else if (response.data is List) {
          return response.data as List<dynamic>;
        }
        return [response.data];
      }
    } catch (e) {
      // Log error
    }
    return null;
  }

  /// Example implementation for updating user settings/profile
  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null || token.isEmpty) return false;

      final response = await _dio.post(
        '/student/profile/update',
        data: updateData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Fetches the user's notifications
  Future<List<dynamic>?> fetchNotifications() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null || token.isEmpty) return null;

      final response = await _dio.post(
        '/student/notifications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map && response.data.containsKey('data')) {
          return response.data['data'] as List<dynamic>;
        } else if (response.data is List) {
          return response.data as List<dynamic>;
        }
        return [response.data];
      }
    } catch (e) {
      // Log error
      return null;
    }
    return null;
  }

  /// Marks all unread notifications as read
  Future<bool> markNotificationsAsRead() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null || token.isEmpty) return false;

      final response = await _dio.post(
        '/student/notifications/mark-read',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Verifies if the student currently has an active subscription
  Future<bool> checkSubscriptionStatus() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null || token.isEmpty) return false;

      final response = await _dio.post(
        '/student/subscription/check',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['subscribed'] == true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Retrieves the student's quiz results and academic grades
  Future<List<dynamic>?> fetchGrades() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null || token.isEmpty) return null;

      final response = await _dio.post(
        '/student/grades',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map && response.data.containsKey('data')) {
          return response.data['data'] as List<dynamic>;
        } else if (response.data is List) {
          return response.data as List<dynamic>;
        }
        return [response.data];
      }
    } catch (e) {
      // Log error
      return null;
    }
    return null;
  }
}
