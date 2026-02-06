import 'package:equatable/equatable.dart';
import 'user_model.dart';

class ExpenseSplit extends Equatable {
  final User user;
  final double amount;
  final double? percentage;

  const ExpenseSplit({
    required this.user,
    required this.amount,
    this.percentage,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      user: json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'])
          : User(
              id: json['user'].toString(),
              name: '',
              email: '',
              phone: '',
              createdAt: DateTime.now(),
            ),
      amount: (json['amount'] as num).toDouble(),
      percentage: json['percentage']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.id,
      'amount': amount,
      if (percentage != null) 'percentage': percentage,
    };
  }

  @override
  List<Object?> get props => [user, amount, percentage];
}

class Expense extends Equatable {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final User paidBy;
  final String splitType;
  final List<ExpenseSplit> splits;
  final String? notes;
  final String category;
  final User? createdBy;
  final bool isDeleted;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitType,
    required this.splits,
    this.notes,
    required this.category,
    this.createdBy,
    this.isDeleted = false,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['_id'] ?? json['id'],
      groupId: json['group'] is Map<String, dynamic>
          ? json['group']['_id']
          : json['group'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paidBy'] is Map<String, dynamic>
          ? User.fromJson(json['paidBy'])
          : User(
              id: json['paidBy'].toString(),
              name: '',
              email: '',
              phone: '',
              createdAt: DateTime.now(),
            ),
      splitType: json['splitType'] ?? 'equal',
      splits: (json['splits'] as List<dynamic>?)
              ?.map((s) => ExpenseSplit.fromJson(s))
              .toList() ??
          [],
      notes: json['notes'],
      category: json['category'] ?? 'other',
      createdBy: json['createdBy'] is Map<String, dynamic>
          ? User.fromJson(json['createdBy'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'group': groupId,
      'description': description,
      'amount': amount,
      'paidBy': paidBy.id,
      'splitType': splitType,
      'splits': splits.map((s) => s.toJson()).toList(),
      'notes': notes,
      'category': category,
      'createdBy': createdBy?.id,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        description,
        amount,
        paidBy,
        splitType,
        splits,
        notes,
        category,
        createdBy,
        isDeleted,
        createdAt,
      ];
}

class CreateExpenseRequest {
  final String groupId;
  final String description;
  final double amount;
  final String paidBy;
  final String splitType;
  final List<Map<String, dynamic>>? splits;
  final String? notes;
  final String category;

  CreateExpenseRequest({
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    this.splitType = 'equal',
    this.splits,
    this.notes,
    this.category = 'other',
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'splitType': splitType,
      if (splits != null) 'splits': splits,
      if (notes != null) 'notes': notes,
      'category': category,
    };
  }
}
