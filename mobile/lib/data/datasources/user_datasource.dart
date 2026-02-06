import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

class UserDatasource {
  final ApiClient _apiClient;

  UserDatasource(this._apiClient);

  Future<User> updateProfile({
    String? name,
    String? upiId,
    String? avatar,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.userProfile,
      data: {
        if (name != null) 'name': name,
        if (upiId != null) 'upiId': upiId,
        if (avatar != null) 'avatar': avatar,
      },
    );
    return User.fromJson(response['data']['user']);
  }

  Future<List<User>> searchUsers(String query) async {
    final response = await _apiClient.get(
      ApiConstants.searchUsers,
      queryParameters: {'query': query},
    );
    return (response['data']['users'] as List<dynamic>)
        .map((u) => User.fromJson(u))
        .toList();
  }
}
