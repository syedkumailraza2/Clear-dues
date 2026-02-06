import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

class GroupDatasource {
  final ApiClient _apiClient;

  GroupDatasource(this._apiClient);

  Future<List<Group>> getMyGroups() async {
    final response = await _apiClient.get(ApiConstants.groups);
    final groups = (response['data']['groups'] as List<dynamic>)
        .map((g) => Group.fromJson(g))
        .toList();
    return groups;
  }

  Future<Group> getGroup(String id) async {
    final response = await _apiClient.get(ApiConstants.groupById(id));
    return Group.fromJson(response['data']['group']);
  }

  Future<Group> createGroup({
    required String name,
    String? description,
    String? icon,
    List<String>? memberIds,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.groups,
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        if (memberIds != null) 'memberIds': memberIds,
      },
    );
    return Group.fromJson(response['data']['group']);
  }

  Future<Group> updateGroup(
    String id, {
    String? name,
    String? description,
    String? icon,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.groupById(id),
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
      },
    );
    return Group.fromJson(response['data']['group']);
  }

  Future<void> deleteGroup(String id) async {
    await _apiClient.delete(ApiConstants.groupById(id));
  }

  Future<Group> joinGroup(String inviteCode) async {
    final response = await _apiClient.post(ApiConstants.joinGroup(inviteCode));
    return Group.fromJson(response['data']['group']);
  }

  Future<Group> addMember(String groupId, String userId) async {
    final response = await _apiClient.post(
      ApiConstants.groupMembers(groupId),
      data: {'userId': userId},
    );
    return Group.fromJson(response['data']['group']);
  }

  Future<Group> removeMember(String groupId, String userId) async {
    final response = await _apiClient.delete(
      ApiConstants.removeMember(groupId, userId),
    );
    return Group.fromJson(response['data']['group']);
  }

  Future<String> getInviteCode(String groupId) async {
    final response = await _apiClient.get(ApiConstants.groupInvite(groupId));
    return response['data']['inviteCode'];
  }
}
