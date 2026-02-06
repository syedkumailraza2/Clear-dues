import 'package:equatable/equatable.dart';
import 'user_model.dart';
import 'group_model.dart';

class Settlement extends Equatable {
  final String id;
  final Group? group;
  final User from;
  final User to;
  final double amount;
  final String status;
  final String? upiTransactionId;
  final DateTime? paidAt;
  final DateTime? confirmedAt;
  final String? notes;
  final DateTime createdAt;

  const Settlement({
    required this.id,
    this.group,
    required this.from,
    required this.to,
    required this.amount,
    required this.status,
    this.upiTransactionId,
    this.paidAt,
    this.confirmedAt,
    this.notes,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['_id'] ?? json['id'],
      group: json['group'] is Map<String, dynamic>
          ? Group.fromJson(json['group'])
          : null,
      from: json['from'] is Map<String, dynamic>
          ? User.fromJson(json['from'])
          : User(
              id: json['from'].toString(),
              name: '',
              email: '',
              phone: '',
              createdAt: DateTime.now(),
            ),
      to: json['to'] is Map<String, dynamic>
          ? User.fromJson(json['to'])
          : User(
              id: json['to'].toString(),
              name: '',
              email: '',
              phone: '',
              createdAt: DateTime.now(),
            ),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] ?? 'pending',
      upiTransactionId: json['upiTransactionId'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      confirmedAt:
          json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'group': group?.toJson(),
      'from': from.toJson(),
      'to': to.toJson(),
      'amount': amount,
      'status': status,
      'upiTransactionId': upiTransactionId,
      'paidAt': paidAt?.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        group,
        from,
        to,
        amount,
        status,
        upiTransactionId,
        paidAt,
        confirmedAt,
        notes,
        createdAt,
      ];
}

class SuggestedSettlement extends Equatable {
  final User from;
  final User to;
  final double amount;
  final bool hasUpi;

  const SuggestedSettlement({
    required this.from,
    required this.to,
    required this.amount,
    required this.hasUpi,
  });

  factory SuggestedSettlement.fromJson(Map<String, dynamic> json) {
    return SuggestedSettlement(
      from: User.fromJson(json['from']),
      to: User.fromJson(json['to']),
      amount: (json['amount'] as num).toDouble(),
      hasUpi: json['hasUpi'] ?? false,
    );
  }

  @override
  List<Object?> get props => [from, to, amount, hasUpi];
}

class UpiLinkResponse {
  final String deepLink;
  final User payee;
  final double amount;

  UpiLinkResponse({
    required this.deepLink,
    required this.payee,
    required this.amount,
  });

  factory UpiLinkResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return UpiLinkResponse(
      deepLink: data['deepLink'],
      payee: User.fromJson(data['payee']),
      amount: (data['amount'] as num).toDouble(),
    );
  }
}
