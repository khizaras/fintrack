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

  // 🤖 Enhanced LLM-extracted attributes
  final String? recipientOrSender;
  final double? availableBalance;
  final String? subcategory;
  final String? transactionMethod; // UPI, ATM, POS, Online, Transfer
  final String? location;
  final String? referenceNumber;
  final double? confidenceScore;
  final List<String>? anomalyFlags;
  final String? llmInsights;
  final DateTime? transactionTime; // Separate time component

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
    // Enhanced LLM attributes
    this.recipientOrSender,
    this.availableBalance,
    this.subcategory,
    this.transactionMethod,
    this.location,
    this.referenceNumber,
    this.confidenceScore,
    this.anomalyFlags,
    this.llmInsights,
    this.transactionTime,
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
    // Enhanced LLM attributes
    String? recipientOrSender,
    double? availableBalance,
    String? subcategory,
    String? transactionMethod,
    String? location,
    String? referenceNumber,
    double? confidenceScore,
    List<String>? anomalyFlags,
    String? llmInsights,
    DateTime? transactionTime,
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
      // Enhanced LLM attributes
      recipientOrSender: recipientOrSender ?? this.recipientOrSender,
      availableBalance: availableBalance ?? this.availableBalance,
      subcategory: subcategory ?? this.subcategory,
      transactionMethod: transactionMethod ?? this.transactionMethod,
      location: location ?? this.location,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      anomalyFlags: anomalyFlags ?? this.anomalyFlags,
      llmInsights: llmInsights ?? this.llmInsights,
      transactionTime: transactionTime ?? this.transactionTime,
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
      // Enhanced LLM attributes
      'recipient_or_sender': recipientOrSender,
      'available_balance': availableBalance,
      'subcategory': subcategory,
      'transaction_method': transactionMethod,
      'location': location,
      'reference_number': referenceNumber,
      'confidence_score': confidenceScore,
      'anomaly_flags': anomalyFlags?.join(','),
      'llm_insights': llmInsights,
      'transaction_time': transactionTime?.toIso8601String(),
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
      // Enhanced LLM attributes
      recipientOrSender: map['recipient_or_sender'],
      availableBalance: map['available_balance']?.toDouble(),
      subcategory: map['subcategory'],
      transactionMethod: map['transaction_method'],
      location: map['location'],
      referenceNumber: map['reference_number'],
      confidenceScore: map['confidence_score']?.toDouble(),
      anomalyFlags: map['anomaly_flags']?.split(','),
      llmInsights: map['llm_insights'],
      transactionTime: map['transaction_time'] != null
          ? DateTime.parse(map['transaction_time'])
          : null,
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
        // Enhanced LLM attributes
        recipientOrSender,
        availableBalance,
        subcategory,
        transactionMethod,
        location,
        referenceNumber,
        confidenceScore,
        anomalyFlags,
        llmInsights,
        transactionTime,
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
