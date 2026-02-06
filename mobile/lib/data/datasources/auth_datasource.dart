import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

class AuthDatasource {
  final ApiClient _apiClient;

  AuthDatasource(this._apiClient);

  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? upiId,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.signup,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        if (upiId != null) 'upiId': upiId,
      },
    );
    return AuthResponse.fromJson(response);
  }

  Future<AuthResponse> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response);
  }

  Future<User> getCurrentUser() async {
    final response = await _apiClient.get(ApiConstants.me);
    return User.fromJson(response['data']['user']);
  }

  Future<String> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.updatePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return response['data']['token'];
  }
}
