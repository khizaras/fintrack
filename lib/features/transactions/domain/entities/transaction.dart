import 'package:equatable/equatable.dart';
import 'category.dart';

class Transaction extends Equatable {
  final int? id;
  final int userId;
  final int categoryId;
  final double amount;
  final String? description;
  final TransactionType type;
  final DateTime date;
  final String? smsContent;
  final String? bankName;
  final String? accountNumber;
  final String? merchantName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category? categoryEntity; // Optional category object

  const Transaction({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    this.description,
    required this.type,
    required this.date,
    this.smsContent,
    this.bankName,
    this.accountNumber,
    this.merchantName,
    required this.createdAt,
    required this.updatedAt,
    this.categoryEntity,
  });

  /// Get category name - either from categoryEntity or fallback to 'Other'
  String? get category => categoryEntity?.name;

  Transaction copyWith({
    int? id,
    int? userId,
    int? categoryId,
    double? amount,
    String? description,
    TransactionType? type,
    DateTime? date,
    String? smsContent,
    String? bankName,
    String? accountNumber,
    String? merchantName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? categoryEntity,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      smsContent: smsContent ?? this.smsContent,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      merchantName: merchantName ?? this.merchantName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryEntity: categoryEntity ?? this.categoryEntity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'type': type.name,
      'date': date.toIso8601String(),
      'sms_content': smsContent,
      'bank_name': bankName,
      'account_number': accountNumber,
      'merchant_name': merchantName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      categoryId: map['category_id']?.toInt() ?? 0,
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'],
      type: TransactionType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      date: DateTime.parse(map['date']),
      smsContent: map['sms_content'],
      bankName: map['bank_name'],
      accountNumber: map['account_number'],
      merchantName: map['merchant_name'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        amount,
        description,
        type,
        date,
        smsContent,
        bankName,
        accountNumber,
        merchantName,
        createdAt,
        updatedAt,
        categoryEntity,
      ];
}

enum TransactionType {
  income,
  expense,
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }

  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;
}
