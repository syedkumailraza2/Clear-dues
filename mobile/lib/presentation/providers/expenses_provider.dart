import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/exceptions.dart';
import '../../data/models/models.dart';
import 'core_providers.dart';

// Expenses state for a group
class ExpensesState {
  final List<Expense> expenses;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const ExpensesState({
    this.expenses = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  ExpensesState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

// Expenses notifier (per group)
class ExpensesNotifier extends StateNotifier<ExpensesState> {
  final Ref _ref;
  final String groupId;

  ExpensesNotifier(this._ref, this.groupId) : super(const ExpensesState());

  Future<void> fetchExpenses({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final datasource = _ref.read(expenseDatasourceProvider);
      final expenses = await datasource.getGroupExpenses(groupId, page: page);

      if (refresh) {
        state = ExpensesState(
          expenses: expenses,
          isLoading: false,
          hasMore: expenses.length >= 20,
          currentPage: 2,
        );
      } else {
        state = state.copyWith(
          expenses: [...state.expenses, ...expenses],
          isLoading: false,
          hasMore: expenses.length >= 20,
          currentPage: page + 1,
        );
      }
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load expenses',
      );
    }
  }

  Future<Expense?> createExpense(CreateExpenseRequest request) async {
    try {
      final datasource = _ref.read(expenseDatasourceProvider);
      final expense = await datasource.createExpense(request);

      state = state.copyWith(
        expenses: [expense, ...state.expenses],
      );
      return expense;
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create expense');
      return null;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      final datasource = _ref.read(expenseDatasourceProvider);
      await datasource.deleteExpense(id);

      state = state.copyWith(
        expenses: state.expenses.where((e) => e.id != id).toList(),
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete expense');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Family provider for expenses per group
final expensesProvider = StateNotifierProvider.family<ExpensesNotifier, ExpensesState, String>(
  (ref, groupId) => ExpensesNotifier(ref, groupId),
);

// Single expense provider
final expenseDetailProvider = FutureProvider.family<Expense, String>((ref, id) async {
  final datasource = ref.read(expenseDatasourceProvider);
  return datasource.getExpense(id);
});
