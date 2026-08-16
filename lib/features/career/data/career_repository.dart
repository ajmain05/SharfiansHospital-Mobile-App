import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class CareerRepository {
  final _api = ApiClient();

  Future<void> submitApplication(Map<String, dynamic> payload) async {
    final res = await _api.post('/career', payload);
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Application failed',
        statusCode: res.statusCode,
      );
    }
  }
}
