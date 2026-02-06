import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/exceptions.dart';
import '../../data/models/models.dart';
import 'core_providers.dart';

// Dashboard state
class DashboardState {
  final DashboardData? data;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Dashboard notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(const DashboardState());

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final datasource = _ref.read(settlementDatasourceProvider);
      final data = await datasource.getDashboard();
      state = DashboardState(data: data, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Dashboard provider
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});

// Group balances provider
final groupBalancesProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, groupId) async {
    final datasource = ref.read(settlementDatasourceProvider);
    return datasource.getGroupBalances(groupId);
  },
);

// Suggested settlements provider
final suggestedSettlementsProvider = FutureProvider.family<List<SuggestedSettlement>, String>(
  (ref, groupId) async {
    final datasource = ref.read(settlementDatasourceProvider);
    return datasource.getSuggestedSettlements(groupId);
  },
);

// Pending settlements provider
final pendingSettlementsProvider = FutureProvider<List<Settlement>>((ref) async {
  final datasource = ref.read(settlementDatasourceProvider);
  return datasource.getMyPendingSettlements();
});

// Settlements to confirm provider
final settlementsToConfirmProvider = FutureProvider<List<Settlement>>((ref) async {
  final datasource = ref.read(settlementDatasourceProvider);
  return datasource.getSettlementsToConfirm();
});
