import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

class ExpenseDatasource {
  final ApiClient _apiClient;

  ExpenseDatasource(this._apiClient);

  Future<Expense> createExpense(CreateExpenseRequest request) async {
    final response = await _apiClient.post(
      ApiConstants.expenses,
      data: request.toJson(),
    );
    return Expense.fromJson(response['data']['expense']);
  }

  Future<List<Expense>> getGroupExpenses(
    String groupId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.groupExpenses(groupId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    final expenses = (response['data']['expenses'] as List<dynamic>)
        .map((e) => Expense.fromJson(e))
        .toList();
    return expenses;
  }

  Future<Expense> getExpense(String id) async {
    final response = await _apiClient.get(ApiConstants.expenseById(id));
    return Expense.fromJson(response['data']['expense']);
  }

  Future<Expense> updateExpense(
    String id, {
    String? description,
    String? notes,
    String? category,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.expenseById(id),
      data: {
        if (description != null) 'description': description,
        if (notes != null) 'notes': notes,
        if (category != null) 'category': category,
      },
    );
    return Expense.fromJson(response['data']['expense']);
  }

  Future<void> deleteExpense(String id) async {
    await _apiClient.delete(ApiConstants.expenseById(id));
  }
}
