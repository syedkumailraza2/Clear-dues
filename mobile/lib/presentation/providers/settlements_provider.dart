import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/exceptions.dart';
import '../../data/models/models.dart';
import 'core_providers.dart';
import 'dashboard_provider.dart';

// Settlement actions notifier
class SettlementActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SettlementActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<Settlement?> createSettlement({
    required String groupId,
    required String toUserId,
    required double amount,
  }) async {
    state = const AsyncValue.loading();

    try {
      final datasource = _ref.read(settlementDatasourceProvider);
      final settlement = await datasource.createSettlement(
        groupId: groupId,
        toUserId: toUserId,
        amount: amount,
      );

      state = const AsyncValue.data(null);
      _ref.invalidate(pendingSettlementsProvider);
      _ref.invalidate(dashboardProvider);
      return settlement;
    } on AppException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return null;
    } catch (e) {
      state = AsyncValue.error('Failed to create settlement', StackTrace.current);
      return null;
    }
  }

  Future<UpiLinkResponse?> getUpiLink(String settlementId) async {
    try {
      final datasource = _ref.read(settlementDatasourceProvider);
      return datasource.getUpiLink(settlementId);
    } on AppException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return null;
    } catch (e) {
      state = AsyncValue.error('Failed to get UPI link', StackTrace.current);
      return null;
    }
  }

  Future<bool> markAsPaid(String settlementId, {String? transactionId}) async {
    state = const AsyncValue.loading();

    try {
      final datasource = _ref.read(settlementDatasourceProvider);
      await datasource.markAsPaid(settlementId, transactionId: transactionId);

      state = const AsyncValue.data(null);
      _ref.invalidate(pendingSettlementsProvider);
      _ref.invalidate(settlementsToConfirmProvider);
      return true;
    } on AppException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error('Failed to mark as paid', StackTrace.current);
      return false;
    }
  }

  Future<bool> confirmSettlement(String settlementId) async {
    state = const AsyncValue.loading();

    try {
      final datasource = _ref.read(settlementDatasourceProvider);
      await datasource.confirmSettlement(settlementId);

      state = const AsyncValue.data(null);
      _ref.invalidate(settlementsToConfirmProvider);
      _ref.invalidate(dashboardProvider);
      return true;
    } on AppException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error('Failed to confirm settlement', StackTrace.current);
      return false;
    }
  }

  Future<bool> rejectSettlement(String settlementId) async {
    state = const AsyncValue.loading();

    try {
      final datasource = _ref.read(settlementDatasourceProvider);
      await datasource.rejectSettlement(settlementId);

      state = const AsyncValue.data(null);
      _ref.invalidate(settlementsToConfirmProvider);
      _ref.invalidate(pendingSettlementsProvider);
      return true;
    } on AppException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error('Failed to reject settlement', StackTrace.current);
      return false;
    }
  }
}

// Settlement actions provider
final settlementActionsProvider =
    StateNotifierProvider<SettlementActionsNotifier, AsyncValue<void>>((ref) {
  return SettlementActionsNotifier(ref);
});

// Group settlements provider
final groupSettlementsProvider = FutureProvider.family<List<Settlement>, String>(
  (ref, groupId) async {
    final datasource = ref.read(settlementDatasourceProvider);
    return datasource.getGroupSettlements(groupId);
  },
);
