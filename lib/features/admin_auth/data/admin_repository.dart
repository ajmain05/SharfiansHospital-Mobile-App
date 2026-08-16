import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class AdminRepository {
  final _api = ApiClient();

  /// `POST /auth/login`
  /// Returns { token, user }
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Login failed',
        statusCode: res.statusCode,
      );
    }
    return res.data as Map<String, dynamic>;
  }

  /// `GET /auth/me`
  Future<Map<String, dynamic>> getMe() async {
    final res = await _api.get('/auth/me');
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Failed to fetch admin profile',
        statusCode: res.statusCode,
      );
    }
    final data = res.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      return data['user'] as Map<String, dynamic>;
    }
    throw ApiException('Invalid response format');
  }
}
