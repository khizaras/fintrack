import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final String type; // 'income' or 'expense'
  final bool isDefault;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    required this.createdAt,
  });

  Category copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    String? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      color: map['color'] ?? '',
      type: map['type'] ?? 'expense',
      isDefault: map['is_default'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, icon, color, type, isDefault, createdAt];
}

// Default categories for the app
class DefaultCategories {
  static List<Category> get all => [
        Category(
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          type: 'expense',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Transport',
          icon: 'directions_car',
          color: '#3F51B5',
          type: 'expense',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Shopping',
          icon: 'shopping_bag',
          color: '#E91E63',
          type: 'expense',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Entertainment',
          icon: 'movie',
          color: '#9C27B0',
          type: 'expense',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Healthcare',
          icon: 'local_hospital',
          color: '#009688',
          type: 'expense',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Utilities',
          icon: 'home',
          color: '#795548',
          type: 'expense',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Education',
          icon: 'school',
          color: '#607D8B',
          type: 'expense',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Income',
          icon: 'account_balance',
          color: '#4CAF50',
          type: 'income',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        Category(
          name: 'Other',
          icon: 'category',
          color: '#616161',
          type: 'expense',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];
}
