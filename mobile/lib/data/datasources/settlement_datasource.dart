import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

class SettlementDatasource {
  final ApiClient _apiClient;

  SettlementDatasource(this._apiClient);

  Future<DashboardData> getDashboard() async {
    final response = await _apiClient.get(ApiConstants.dashboard);
    return DashboardData.fromJson(response);
  }

  Future<Map<String, dynamic>> getGroupBalances(String groupId) async {
    final response = await _apiClient.get(ApiConstants.groupBalances(groupId));
    return {
      'userBalance': UserBalance.fromJson(response['data']['userBalance']),
      'memberBalances': (response['data']['memberBalances'] as List<dynamic>)
          .map((m) => MemberBalance.fromJson(m))
          .toList(),
    };
  }

  Future<List<SuggestedSettlement>> getSuggestedSettlements(String groupId) async {
    final response = await _apiClient.get(ApiConstants.suggestSettlements(groupId));
    return (response['data']['settlements'] as List<dynamic>)
        .map((s) => SuggestedSettlement.fromJson(s))
        .toList();
  }

  Future<List<Settlement>> getGroupSettlements(
    String groupId, {
    String? status,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.groupSettlements(groupId),
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    return (response['data']['settlements'] as List<dynamic>)
        .map((s) => Settlement.fromJson(s))
        .toList();
  }

  Future<Settlement> createSettlement({
    required String groupId,
    required String toUserId,
    required double amount,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.settlements,
      data: {
        'groupId': groupId,
        'toUserId': toUserId,
        'amount': amount,
      },
    );
    return Settlement.fromJson(response['data']['settlement']);
  }

  Future<UpiLinkResponse> getUpiLink(String settlementId) async {
    final response = await _apiClient.get(ApiConstants.upiLink(settlementId));
    return UpiLinkResponse.fromJson(response);
  }

  Future<Settlement> markAsPaid(
    String settlementId, {
    String? transactionId,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.markPaid(settlementId),
      data: {
        if (transactionId != null) 'transactionId': transactionId,
      },
    );
    return Settlement.fromJson(response['data']['settlement']);
  }

  Future<Settlement> confirmSettlement(String settlementId) async {
    final response = await _apiClient.put(
      ApiConstants.confirmSettlement(settlementId),
    );
    return Settlement.fromJson(response['data']['settlement']);
  }

  Future<void> rejectSettlement(String settlementId) async {
    await _apiClient.put(ApiConstants.rejectSettlement(settlementId));
  }

  Future<List<Settlement>> getMyPendingSettlements() async {
    final response = await _apiClient.get(ApiConstants.myPendingSettlements);
    return (response['data']['settlements'] as List<dynamic>)
        .map((s) => Settlement.fromJson(s))
        .toList();
  }

  Future<List<Settlement>> getSettlementsToConfirm() async {
    final response = await _apiClient.get(ApiConstants.settlementsToConfirm);
    return (response['data']['settlements'] as List<dynamic>)
        .map((s) => Settlement.fromJson(s))
        .toList();
  }
}
