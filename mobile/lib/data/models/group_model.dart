import 'package:equatable/equatable.dart';
import 'user_model.dart';

class Group extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final List<User> members;
  final User? createdBy;
  final String? inviteCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.members,
    this.createdBy,
    this.inviteCode,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  int get memberCount => members.length;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'] ?? 'group',
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => m is Map<String, dynamic>
                  ? User.fromJson(m)
                  : User(
                      id: m.toString(),
                      name: '',
                      email: '',
                      phone: '',
                      createdAt: DateTime.now(),
                    ))
              .toList() ??
          [],
      createdBy: json['createdBy'] is Map<String, dynamic>
          ? User.fromJson(json['createdBy'])
          : null,
      inviteCode: json['inviteCode'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'members': members.map((m) => m.toJson()).toList(),
      'createdBy': createdBy?.toJson(),
      'inviteCode': inviteCode,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    List<User>? members,
    User? createdBy,
    String? inviteCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      members: members ?? this.members,
      createdBy: createdBy ?? this.createdBy,
      inviteCode: inviteCode ?? this.inviteCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        members,
        createdBy,
        inviteCode,
        isActive,
        createdAt,
        updatedAt,
      ];
}
