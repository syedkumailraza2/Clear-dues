import 'package:equatable/equatable.dart';
import 'user_model.dart';

class BalanceEntry extends Equatable {
  final String oderId;
  final String name;
  final double amount;

  const BalanceEntry({
    required this.oderId,
    required this.name,
    required this.amount,
  });

  factory BalanceEntry.fromJson(Map<String, dynamic> json) {
    return BalanceEntry(
      oderId: json['userId'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [oderId, name, amount];
}

class UserBalance extends Equatable {
  final List<BalanceEntry> owes;
  final List<BalanceEntry> owedBy;
  final double totalOwed;
  final double totalOwedBy;
  final double netBalance;

  const UserBalance({
    required this.owes,
    required this.owedBy,
    required this.totalOwed,
    required this.totalOwedBy,
    required this.netBalance,
  });

  factory UserBalance.fromJson(Map<String, dynamic> json) {
    return UserBalance(
      owes: (json['owes'] as List<dynamic>?)
              ?.map((e) => BalanceEntry.fromJson(e))
              .toList() ??
          [],
      owedBy: (json['owedBy'] as List<dynamic>?)
              ?.map((e) => BalanceEntry.fromJson(e))
              .toList() ??
          [],
      totalOwed: (json['totalOwed'] as num?)?.toDouble() ?? 0,
      totalOwedBy: (json['totalOwedBy'] as num?)?.toDouble() ?? 0,
      netBalance: (json['netBalance'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [owes, owedBy, totalOwed, totalOwedBy, netBalance];
}

class MemberBalance extends Equatable {
  final User user;
  final double balance;

  const MemberBalance({
    required this.user,
    required this.balance,
  });

  factory MemberBalance.fromJson(Map<String, dynamic> json) {
    return MemberBalance(
      user: User.fromJson(json['user']),
      balance: (json['balance'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [user, balance];
}

class GroupBalanceInfo extends Equatable {
  final String groupId;
  final String groupName;
  final int memberCount;
  final List<BalanceEntry> owes;
  final List<BalanceEntry> owedBy;
  final double totalOwed;
  final double totalOwedBy;
  final double netBalance;

  const GroupBalanceInfo({
    required this.groupId,
    required this.groupName,
    required this.memberCount,
    required this.owes,
    required this.owedBy,
    required this.totalOwed,
    required this.totalOwedBy,
    required this.netBalance,
  });

  factory GroupBalanceInfo.fromJson(Map<String, dynamic> json) {
    final group = json['group'] ?? {};
    return GroupBalanceInfo(
      groupId: group['_id'] ?? '',
      groupName: group['name'] ?? '',
      memberCount: group['memberCount'] ?? 0,
      owes: (json['owes'] as List<dynamic>?)
              ?.map((e) => BalanceEntry.fromJson(e))
              .toList() ??
          [],
      owedBy: (json['owedBy'] as List<dynamic>?)
              ?.map((e) => BalanceEntry.fromJson(e))
              .toList() ??
          [],
      totalOwed: (json['totalOwed'] as num?)?.toDouble() ?? 0,
      totalOwedBy: (json['totalOwedBy'] as num?)?.toDouble() ?? 0,
      netBalance: (json['netBalance'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        groupId,
        groupName,
        memberCount,
        owes,
        owedBy,
        totalOwed,
        totalOwedBy,
        netBalance,
      ];
}

class DashboardData extends Equatable {
  final double youOwe;
  final double youAreOwed;
  final double netBalance;
  final int pendingSettlements;
  final int settlementsToConfirm;
  final List<GroupBalanceInfo> groupBalances;

  const DashboardData({
    required this.youOwe,
    required this.youAreOwed,
    required this.netBalance,
    required this.pendingSettlements,
    required this.settlementsToConfirm,
    required this.groupBalances,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final overview = data['overview'] ?? {};
    return DashboardData(
      youOwe: (overview['youOwe'] as num?)?.toDouble() ?? 0,
      youAreOwed: (overview['youAreOwed'] as num?)?.toDouble() ?? 0,
      netBalance: (overview['netBalance'] as num?)?.toDouble() ?? 0,
      pendingSettlements: data['pendingSettlements'] ?? 0,
      settlementsToConfirm: data['settlementsToConfirm'] ?? 0,
      groupBalances: (data['groupBalances'] as List<dynamic>?)
              ?.map((e) => GroupBalanceInfo.fromJson(e))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        youOwe,
        youAreOwed,
        netBalance,
        pendingSettlements,
        settlementsToConfirm,
        groupBalances,
      ];
}
