import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/exceptions.dart';
import '../../data/models/models.dart';
import 'core_providers.dart';

// Groups state
class GroupsState {
  final List<Group> groups;
  final bool isLoading;
  final String? error;

  const GroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  GroupsState copyWith({
    List<Group>? groups,
    bool? isLoading,
    String? error,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Groups notifier
class GroupsNotifier extends StateNotifier<GroupsState> {
  final Ref _ref;

  GroupsNotifier(this._ref) : super(const GroupsState());

  Future<void> fetchGroups() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final datasource = _ref.read(groupDatasourceProvider);
      final groups = await datasource.getMyGroups();
      state = GroupsState(groups: groups, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load groups',
      );
    }
  }

  Future<Group?> createGroup({
    required String name,
    String? description,
    String? icon,
    List<String>? memberIds,
  }) async {
    try {
      final datasource = _ref.read(groupDatasourceProvider);
      final group = await datasource.createGroup(
        name: name,
        description: description,
        icon: icon,
        memberIds: memberIds,
      );

      state = state.copyWith(groups: [group, ...state.groups]);
      return group;
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create group');
      return null;
    }
  }

  Future<Group?> joinGroup(String inviteCode) async {
    try {
      final datasource = _ref.read(groupDatasourceProvider);
      final group = await datasource.joinGroup(inviteCode);

      state = state.copyWith(groups: [group, ...state.groups]);
      return group;
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Failed to join group');
      return null;
    }
  }

  Future<bool> updateGroup(
    String id, {
    String? name,
    String? description,
    String? icon,
  }) async {
    try {
      final datasource = _ref.read(groupDatasourceProvider);
      final updatedGroup = await datasource.updateGroup(
        id,
        name: name,
        description: description,
        icon: icon,
      );

      state = state.copyWith(
        groups: state.groups.map((g) {
          return g.id == id ? updatedGroup : g;
        }).toList(),
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update group');
      return false;
    }
  }

  Future<bool> deleteGroup(String id) async {
    try {
      final datasource = _ref.read(groupDatasourceProvider);
      await datasource.deleteGroup(id);

      state = state.copyWith(
        groups: state.groups.where((g) => g.id != id).toList(),
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete group');
      return false;
    }
  }

  Future<bool> leaveGroup(String groupId, String userId) async {
    try {
      final datasource = _ref.read(groupDatasourceProvider);
      await datasource.removeMember(groupId, userId);

      state = state.copyWith(
        groups: state.groups.where((g) => g.id != groupId).toList(),
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to leave group');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Groups provider
final groupsProvider = StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  return GroupsNotifier(ref);
});

// Single group provider (for detail view)
final groupDetailProvider = FutureProvider.family<Group, String>((ref, id) async {
  final datasource = ref.read(groupDatasourceProvider);
  return datasource.getGroup(id);
});

// Group invite code provider
final groupInviteCodeProvider = FutureProvider.family<String, String>((ref, groupId) async {
  final datasource = ref.read(groupDatasourceProvider);
  return datasource.getInviteCode(groupId);
});
