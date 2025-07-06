import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import '../../../../core/database/database_helper.dart';
import '../../../transactions/domain/entities/transaction.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();

  /// Check if SMS permissions are granted
  Future<bool> checkSmsPermissions() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  /// Request SMS permissions
  Future<bool> requestSmsPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Read all SMS messages and extract transactions
  Future<List<Transaction>> readAllSmsTransactions(
      {bool clearExisting = false}) async {
    try {
      final hasPermission = await checkSmsPermissions();
      if (!hasPermission) {
        _logger.w('SMS permission not granted');
        return [];
      }

      // Optionally clear existing transactions
      if (clearExisting) {
        await clearAllTransactions();
        _logger.i('Cleared existing transactions');
      }

      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS)
            .like('%bank%')
            .or(SmsColumn.ADDRESS)
            .like('%SBI%')
            .or(SmsColumn.ADDRESS)
            .like('%HDFC%')
            .or(SmsColumn.ADDRESS)
            .like('%ICICI%')
            .or(SmsColumn.ADDRESS)
            .like('%AXIS%'),
      );

      final transactions = <Transaction>[];
      int newTransactions = 0;
      int duplicatesSkipped = 0;

      for (final message in messages) {
        final transaction = await _parseMessageToTransaction(message);
        if (transaction != null) {
          // Check if this transaction already exists in the database
          final isDuplicate = await _isTransactionDuplicate(transaction);
          if (!isDuplicate) {
            // Save to database immediately
            await _databaseHelper.insert('transactions', transaction.toMap());
            transactions.add(transaction);
            newTransactions++;
          } else {
            duplicatesSkipped++;
          }
        }
      }

      _logger.i(
          'Extracted ${transactions.length} new transactions from SMS (${duplicatesSkipped} duplicates skipped)');
      return transactions;
    } catch (e) {
      _logger.e('Error reading SMS messages: $e');
      return [];
    }
  }

  /// Parse SMS message to transaction
  Future<Transaction?> _parseMessageToTransaction(SmsMessage message) async {
    try {
      final smsContent = message.body ?? '';
      final sender = message.address ?? '';
      final date = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

      // Get SMS patterns from database
      final patterns = await _databaseHelper.query('sms_patterns');

      for (final patternMap in patterns) {
        final pattern = SmsPattern.fromMap(patternMap);

        if (_matchesSender(sender, pattern.senderPattern)) {
          final parsedTransaction = _extractTransactionFromSms(
            smsContent,
            pattern,
            date,
            sender,
          );

          if (parsedTransaction != null) {
            return parsedTransaction;
          }
        }
      }

      return null;
    } catch (e) {
      _logger.e('Error parsing SMS message: $e');
      return null;
    }
  }

  /// Check if sender matches pattern
  bool _matchesSender(String sender, String pattern) {
    final regex = RegExp(pattern, caseSensitive: false);
    return regex.hasMatch(sender);
  }

  /// Extract transaction details from SMS content
  Transaction? _extractTransactionFromSms(
    String smsContent,
    SmsPattern pattern,
    DateTime date,
    String sender,
  ) {
    try {
      // Extract amount
      final amountRegex = RegExp(pattern.amountPattern);
      final amountMatch = amountRegex.firstMatch(smsContent);
      if (amountMatch == null) return null;

      final amountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
      final amount = double.tryParse(amountStr) ?? 0.0;

      // Extract account number
      String? accountNumber;
      if (pattern.accountPattern != null) {
        final accountRegex = RegExp(pattern.accountPattern!);
        final accountMatch = accountRegex.firstMatch(smsContent);
        accountNumber = accountMatch?.group(1);
      }

      // Determine transaction type first
      final type = _determineTransactionType(smsContent, pattern);

      // Extract description/merchant
      String? description;
      if (pattern.descriptionPattern != null) {
        final descRegex = RegExp(pattern.descriptionPattern!);
        final descMatch = descRegex.firstMatch(smsContent);
        description = descMatch?.group(1)?.trim();
      }

      // If no description found from pattern, try to extract a meaningful description
      if (description == null || description.isEmpty) {
        description =
            _extractFallbackDescription(smsContent, pattern.bankName, type);
      }

      // Auto-categorize
      final categoryId = _getCategoryForTransaction(description, type);

      return Transaction(
        userId: 1, // Default user ID for now
        categoryId: categoryId,
        amount: amount,
        description: description,
        type: type,
        date: date,
        smsContent: smsContent,
        bankName: pattern.bankName,
        accountNumber: accountNumber,
        merchantName: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Error extracting transaction from SMS: $e');
      return null;
    }
  }

  /// Extract a fallback description when pattern matching fails
  String _extractFallbackDescription(
      String smsContent, String bankName, TransactionType type) {
    final content = smsContent.toLowerCase();

    // Common merchant patterns
    final merchantPatterns = [
      RegExp(r'at\s+([a-zA-Z0-9\s]+)', caseSensitive: false),
      RegExp(r'from\s+([a-zA-Z0-9\s]+)', caseSensitive: false),
      RegExp(r'to\s+([a-zA-Z0-9\s]+)', caseSensitive: false),
      RegExp(r'via\s+([a-zA-Z0-9\s]+)', caseSensitive: false),
    ];

    // Try to extract merchant/description from common patterns
    for (final pattern in merchantPatterns) {
      final match = pattern.firstMatch(smsContent);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null &&
            extracted.length > 2 &&
            extracted.length < 50) {
          return _cleanDescription(extracted);
        }
      }
    }

    // Fallback based on transaction type and bank
    if (type == TransactionType.income) {
      if (content.contains('salary')) return 'Salary Credit';
      if (content.contains('refund')) return 'Refund Credit';
      if (content.contains('interest')) return 'Interest Credit';
      return 'Credit Transaction';
    } else {
      if (content.contains('atm')) return 'ATM Withdrawal';
      if (content.contains('pos')) return 'POS Transaction';
      if (content.contains('online')) return 'Online Payment';
      if (content.contains('transfer')) return 'Transfer';
      if (content.contains('upi')) return 'UPI Payment';
      return 'Debit Transaction';
    }
  }

  /// Clean up extracted description
  String _cleanDescription(String description) {
    return description
        .replaceAll(
            RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(
            RegExp(r'[^\w\s-]'), '') // Remove special characters except hyphens
        .trim()
        .split(' ')
        .take(3) // Take only first 3 words to keep it concise
        .join(' ');
  }

  /// Determine if transaction is income or expense
  TransactionType _determineTransactionType(
      String smsContent, SmsPattern pattern) {
    final keywords = pattern.transactionTypeKeywords.toLowerCase();
    final content = smsContent.toLowerCase();

    // Check for credit/income keywords
    if (content.contains('credited') ||
        content.contains('deposited') ||
        content.contains('received') ||
        content.contains('salary') ||
        content.contains('refund')) {
      return TransactionType.income;
    }

    // Default to expense for debit/spending
    return TransactionType.expense;
  }

  /// Auto-categorize transaction based on description
  int _getCategoryForTransaction(String description, TransactionType type) {
    final desc = description.toLowerCase();

    if (type == TransactionType.income) {
      return 8; // Income category ID
    }

    // Food & Dining
    if (desc.contains('swiggy') ||
        desc.contains('zomato') ||
        desc.contains('restaurant') ||
        desc.contains('food') ||
        desc.contains('cafe') ||
        desc.contains('bigbasket') ||
        desc.contains('grocery')) {
      return 1; // Food category
    }

    // Transport
    if (desc.contains('uber') ||
        desc.contains('ola') ||
        desc.contains('metro') ||
        desc.contains('petrol') ||
        desc.contains('fuel') ||
        desc.contains('dmrc')) {
      return 2; // Transport category
    }

    // Shopping
    if (desc.contains('amazon') ||
        desc.contains('flipkart') ||
        desc.contains('myntra') ||
        desc.contains('shopping') ||
        desc.contains('mall')) {
      return 3; // Shopping category
    }

    // Entertainment
    if (desc.contains('netflix') ||
        desc.contains('spotify') ||
        desc.contains('movie') ||
        desc.contains('theater') ||
        desc.contains('cinema')) {
      return 4; // Entertainment category
    }

    // Healthcare
    if (desc.contains('hospital') ||
        desc.contains('clinic') ||
        desc.contains('pharmacy') ||
        desc.contains('medical')) {
      return 5; // Healthcare category
    }

    // Utilities
    if (desc.contains('electricity') ||
        desc.contains('water') ||
        desc.contains('gas') ||
        desc.contains('internet') ||
        desc.contains('mobile')) {
      return 6; // Utilities category
    }

    // Default to Other category
    return 9;
  }

  /// Clear all existing transactions from the database
  Future<void> clearAllTransactions() async {
    try {
      await _databaseHelper.delete('transactions');
      _logger.i('All transactions cleared from database');
    } catch (e) {
      _logger.e('Error clearing transactions: $e');
    }
  }

  /// Get the total number of transactions in the database
  Future<int> getTransactionCount() async {
    try {
      final result = await _databaseHelper
          .rawQuery('SELECT COUNT(*) as count FROM transactions');
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      _logger.e('Error getting transaction count: $e');
      return 0;
    }
  }

  /// Check if a transaction already exists in the database
  Future<bool> _isTransactionDuplicate(Transaction transaction) async {
    try {
      // Check for duplicate based on amount, date, and bank
      // Using a time window of ±2 minutes to account for minor timestamp differences
      final startTime = transaction.date.subtract(const Duration(minutes: 2));
      final endTime = transaction.date.add(const Duration(minutes: 2));

      List<Map<String, dynamic>> existingTransactions;

      if (transaction.accountNumber != null &&
          transaction.accountNumber!.isNotEmpty) {
        // If we have account number, include it in the search for better accuracy
        existingTransactions = await _databaseHelper.query(
          'transactions',
          where:
              'amount = ? AND date >= ? AND date <= ? AND bank_name = ? AND account_number = ?',
          whereArgs: [
            transaction.amount,
            startTime.toIso8601String(),
            endTime.toIso8601String(),
            transaction.bankName,
            transaction.accountNumber,
          ],
        );
      } else {
        // If no account number, check by amount, date, bank and description
        existingTransactions = await _databaseHelper.query(
          'transactions',
          where:
              'amount = ? AND date >= ? AND date <= ? AND bank_name = ? AND description = ?',
          whereArgs: [
            transaction.amount,
            startTime.toIso8601String(),
            endTime.toIso8601String(),
            transaction.bankName,
            transaction.description,
          ],
        );
      }

      return existingTransactions.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking for duplicate transaction: $e');
      // If we can't check, assume it's not a duplicate to be safe
      return false;
    }
  }

  /// Listen for new SMS messages
  void startListeningForSms() {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final transaction = await _parseMessageToTransaction(message);
        if (transaction != null) {
          // Check if this transaction already exists to avoid duplicates
          final isDuplicate = await _isTransactionDuplicate(transaction);
          if (!isDuplicate) {
            // Save to database
            await _databaseHelper.insert('transactions', transaction.toMap());
            _logger.i(
                'New transaction saved from SMS: ${transaction.description}');
          } else {
            _logger
                .i('Duplicate transaction ignored: ${transaction.description}');
          }
        }
      },
      listenInBackground: false,
    );
  }
}

/// SMS Pattern model for parsing different bank formats
class SmsPattern {
  final int? id;
  final String bankName;
  final String senderPattern;
  final String amountPattern;
  final String? accountPattern;
  final String? descriptionPattern;
  final String? balancePattern;
  final String transactionTypeKeywords;
  final DateTime createdAt;

  SmsPattern({
    this.id,
    required this.bankName,
    required this.senderPattern,
    required this.amountPattern,
    this.accountPattern,
    this.descriptionPattern,
    this.balancePattern,
    required this.transactionTypeKeywords,
    required this.createdAt,
  });

  factory SmsPattern.fromMap(Map<String, dynamic> map) {
    return SmsPattern(
      id: map['id']?.toInt(),
      bankName: map['bank_name'] ?? '',
      senderPattern: map['sender_pattern'] ?? '',
      amountPattern: map['amount_pattern'] ?? '',
      accountPattern: map['account_pattern'],
      descriptionPattern: map['description_pattern'],
      balancePattern: map['balance_pattern'],
      transactionTypeKeywords: map['transaction_type_keywords'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
