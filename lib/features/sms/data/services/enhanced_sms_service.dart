import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/ai/llm_service.dart';
import '../../../transactions/domain/entities/transaction.dart';

/// Enterprise-level SMS service with LLM integration for intelligent transaction analysis
class EnhancedSmsService {
  final Telephony _telephony = Telephony.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final Logger _logger = Logger();

  late final LLMService _llmService;
  bool _llmServiceAvailable = false;

  // Initialize with OpenRouter API key and model
  EnhancedSmsService({
    required String openRouterApiKey,
    String? model,
  }) {
    _llmService = LLMService(
      apiKey: openRouterApiKey,
      model: model,
    );
    _initializeLLMService();
  }

  /// Initialize and test LLM service availability
  Future<void> _initializeLLMService() async {
    try {
      _logger.i('🔧 Initializing Enhanced SMS Service with LLM...');
      _llmServiceAvailable = await _llmService.testConnection();

      if (_llmServiceAvailable) {
        _logger.i('✅ LLM service is available and ready');
      } else {
        _logger.w('⚠️ LLM service unavailable - will use fallback parsing');
      }
    } catch (e) {
      _logger.w('⚠️ Failed to test LLM service: $e - using fallback parsing');
      _llmServiceAvailable = false;
    }
  }

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

  /// Read all SMS messages and extract transactions using LLM analysis
  Future<List<Transaction>> readAllSmsTransactionsWithLLM({
    bool clearExisting = false,
    Function(int current, int total, String currentSms)? onProgress,
  }) async {
    try {
      _logger.i('🤖 Starting LLM-enhanced SMS transaction analysis...');

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

      _logger.i('🔍 Reading SMS messages from inbox...');

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
            .like('%AXIS%')
            .or(SmsColumn.ADDRESS)
            .like('%PAYTM%')
            .or(SmsColumn.ADDRESS)
            .like('%GPAY%')
            .or(SmsColumn.ADDRESS)
            .like('%PHONEPE%'),
      );

      _logger.i('📱 Found ${messages.length} potential financial SMS messages');

      final transactions = <Transaction>[];
      int newTransactions = 0;
      int duplicatesSkipped = 0;
      int llmProcessed = 0;
      int llmFailed = 0;

      // Filter financial SMS messages first to get accurate count
      final financialMessages =
          messages.where((msg) => _isFinancialSms(msg.body ?? '')).toList();
      _logger.i(
          '📊 Found ${financialMessages.length} financial SMS messages to process with LLM');

      for (int i = 0; i < financialMessages.length; i++) {
        final message = financialMessages[i];
        final smsContent = message.body ?? '';
        final sender = message.address ?? '';
        final date = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

        // Report progress
        onProgress?.call(i + 1, financialMessages.length,
            smsContent.length > 50 ? smsContent.substring(0, 50) : smsContent);

        // Check if this looks like a financial SMS
        if (_isFinancialSms(smsContent)) {
          _logger.d(
              '🔍 Analyzing financial SMS from $sender: ${smsContent.length > 50 ? smsContent.substring(0, 50) : smsContent}...');

          try {
            // 🤖 Use LLM for intelligent analysis only if available
            if (_llmServiceAvailable) {
              _logger.d('🤖 Sending SMS to LLM for analysis...');
              final llmAnalysis =
                  await _llmService.analyzeSmsTransaction(smsContent);

              if (llmAnalysis != null) {
                _logger.i('✅ LLM analysis successful for SMS from $sender');
                final transaction = await _createTransactionFromLLMAnalysis(
                    llmAnalysis, smsContent, sender, date);

                if (transaction != null) {
                  // Check for duplicates
                  final isDuplicate =
                      await _isTransactionDuplicate(transaction);
                  if (!isDuplicate) {
                    // Save to database
                    await _databaseHelper.insert(
                        'transactions', transaction.toMap());
                    transactions.add(transaction);
                    newTransactions++;
                    llmProcessed++;
                  } else {
                    duplicatesSkipped++;
                  }
                }
                continue; // Successfully processed with LLM
              } else {
                _logger.w(
                    '❌ LLM analysis failed for SMS from $sender - falling back');
              }
            } else {
              _logger
                  .d('⚠️ LLM service not available - using fallback parsing');
            }

            // Fallback to traditional parsing if LLM fails or unavailable
            llmFailed++;
            final fallbackTransaction =
                await _fallbackTransactionParsing(smsContent, sender, date);
            if (fallbackTransaction != null) {
              final isDuplicate =
                  await _isTransactionDuplicate(fallbackTransaction);
              if (!isDuplicate) {
                await _databaseHelper.insert(
                    'transactions', fallbackTransaction.toMap());
                transactions.add(fallbackTransaction);
                newTransactions++;
                _logger.i('✅ Fallback parsing successful for SMS from $sender');
              }
            }
          } catch (e) {
            _logger.e('❌ Error processing SMS with LLM from $sender: $e');
            llmFailed++;
          }
        } else {
          _logger.d('⏭️ Skipping non-financial SMS from $sender');
        }
      }

      _logger.i('🤖 LLM SMS Analysis Complete:');
      _logger.i('  • Total messages processed: ${messages.length}');
      _logger.i('  • New transactions: $newTransactions');
      _logger.i('  • LLM processed: $llmProcessed');
      _logger.i('  • LLM failed: $llmFailed');
      _logger.i('  • Duplicates skipped: $duplicatesSkipped');

      return transactions;
    } catch (e) {
      _logger.e('Error reading SMS messages with LLM: $e');
      return [];
    }
  }

  /// Create transaction from LLM analysis result
  Future<Transaction?> _createTransactionFromLLMAnalysis(
    LLMTransactionAnalysis analysis,
    String smsContent,
    String sender,
    DateTime smsDate,
  ) async {
    try {
      // Determine transaction type
      final type = analysis.transactionType.toLowerCase() == 'credit'
          ? TransactionType.income
          : TransactionType.expense;

      // Get category ID based on LLM category
      final categoryId = await _getCategoryIdFromLLMCategory(analysis.category);

      // Parse transaction date if provided by LLM, otherwise use SMS date
      DateTime transactionDate = smsDate;
      if (analysis.date != null) {
        try {
          transactionDate = DateTime.parse(analysis.date!);
        } catch (e) {
          _logger.w('Failed to parse LLM date, using SMS date: $e');
        }
      }

      // Parse transaction time if provided
      DateTime? transactionTime;
      if (analysis.time != null) {
        try {
          final timeParts = analysis.time!.split(':');
          if (timeParts.length >= 2) {
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            transactionTime = DateTime(
              transactionDate.year,
              transactionDate.month,
              transactionDate.day,
              hour,
              minute,
            );
          }
        } catch (e) {
          _logger.w('Failed to parse LLM time: $e');
        }
      }

      return Transaction(
        userId: 1, // Default user ID
        categoryId: categoryId,
        amount: analysis.amount,
        description: analysis.description,
        type: type,
        date: transactionDate,
        smsContent: smsContent,
        bankName: analysis.bankName ?? _extractBankFromSender(sender),
        accountNumber: analysis.accountNumber,
        merchantName: analysis.merchantName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Enhanced LLM attributes
        recipientOrSender: analysis.recipientOrSender,
        availableBalance: analysis.availableBalance,
        subcategory: analysis.subcategory,
        transactionMethod: analysis.transactionMethod,
        location: analysis.location,
        referenceNumber: analysis.referenceNumber,
        confidenceScore: analysis.confidenceScore,
        anomalyFlags: analysis.anomalyFlags,
        llmInsights: analysis.insights,
        transactionTime: transactionTime,
      );
    } catch (e) {
      _logger.e('Error creating transaction from LLM analysis: $e');
      return null;
    }
  }

  /// Get category ID from LLM category name
  Future<int> _getCategoryIdFromLLMCategory(String categoryName) async {
    final categoryMap = {
      'Food & Dining': 1,
      'Transport': 2,
      'Shopping': 3,
      'Entertainment': 4,
      'Healthcare': 5,
      'Utilities': 6,
      'Education': 7,
      'Financial Services': 8,
      'Income': 8,
      'Others': 9,
    };

    return categoryMap[categoryName] ?? 9; // Default to 'Others'
  }

  /// Check if SMS content looks like a financial transaction
  bool _isFinancialSms(String content) {
    final financialKeywords = [
      'debited',
      'credited',
      'transaction',
      'payment',
      'transfer',
      'withdrawal',
      'deposit',
      'balance',
      'account',
      'amount',
      'rs.',
      'rs ',
      'inr',
      'upi',
      'atm',
      'pos',
      'neft',
      'rtgs'
    ];

    final lowerContent = content.toLowerCase();
    return financialKeywords.any((keyword) => lowerContent.contains(keyword));
  }

  /// Extract bank name from SMS sender
  String? _extractBankFromSender(String sender) {
    final bankPatterns = {
      'SBI': RegExp(r'SBI|SBIINB', caseSensitive: false),
      'HDFC': RegExp(r'HDFC|HDFCBANK', caseSensitive: false),
      'ICICI': RegExp(r'ICICI|ICICIB', caseSensitive: false),
      'AXIS': RegExp(r'AXIS|AXISBK', caseSensitive: false),
      'KOTAK': RegExp(r'KOTAK', caseSensitive: false),
      'PAYTM': RegExp(r'PAYTM', caseSensitive: false),
      'GPAY': RegExp(r'GPAY|GOOGLEPAY', caseSensitive: false),
      'PHONEPE': RegExp(r'PHONEPE', caseSensitive: false),
    };

    for (final entry in bankPatterns.entries) {
      if (entry.value.hasMatch(sender)) {
        return entry.key;
      }
    }

    return null;
  }

  /// Fallback transaction parsing for when LLM fails
  Future<Transaction?> _fallbackTransactionParsing(
    String smsContent,
    String sender,
    DateTime date,
  ) async {
    try {
      // Basic regex patterns for amount extraction
      final amountPattern =
          RegExp(r'rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false);
      final amountMatch = amountPattern.firstMatch(smsContent);

      if (amountMatch == null) return null;

      final amountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
      final amount = double.tryParse(amountStr) ?? 0.0;

      if (amount == 0.0) return null;

      // Determine transaction type (simple keyword matching)
      final type = _determineTransactionType(smsContent);

      return Transaction(
        userId: 1,
        categoryId: 9, // Default to 'Others'
        amount: amount,
        description: 'Transaction', // Basic description
        type: type,
        date: date,
        smsContent: smsContent,
        bankName: _extractBankFromSender(sender),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        confidenceScore: 0.5, // Low confidence for fallback
      );
    } catch (e) {
      _logger.e('Error in fallback parsing: $e');
      return null;
    }
  }

  /// Simple transaction type determination
  TransactionType _determineTransactionType(String content) {
    final lowerContent = content.toLowerCase();

    if (lowerContent.contains('credited') ||
        lowerContent.contains('received') ||
        lowerContent.contains('deposit')) {
      return TransactionType.income;
    }

    return TransactionType.expense; // Default to expense
  }

  /// Check if transaction is a duplicate
  Future<bool> _isTransactionDuplicate(Transaction transaction) async {
    try {
      final startTime = transaction.date.subtract(const Duration(minutes: 2));
      final endTime = transaction.date.add(const Duration(minutes: 2));

      final existingTransactions = await _databaseHelper.query(
        'transactions',
        where: 'amount = ? AND date >= ? AND date <= ? AND bank_name = ?',
        whereArgs: [
          transaction.amount,
          startTime.toIso8601String(),
          endTime.toIso8601String(),
          transaction.bankName,
        ],
      );

      return existingTransactions.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking for duplicate transaction: $e');
      return false;
    }
  }

  /// Clear all existing transactions
  Future<void> clearAllTransactions() async {
    try {
      await _databaseHelper.delete('transactions');
      _logger.i('All transactions cleared from database');
    } catch (e) {
      _logger.e('Error clearing transactions: $e');
    }
  }

  /// Generate financial insights using LLM
  Future<LLMInsights?> generateFinancialInsights() async {
    try {
      // Get recent transactions for analysis
      final transactions = await _databaseHelper.query(
        'transactions',
        orderBy: 'date DESC',
        limit: 100,
      );

      if (transactions.isEmpty) {
        _logger.w('No transactions available for insights generation');
        return null;
      }

      // Convert to format suitable for LLM analysis
      final transactionData = transactions
          .map((t) => {
                'amount': t['amount'],
                'type': t['type'],
                'category_id': t['category_id'],
                'description': t['description'],
                'bank_name': t['bank_name'],
                'merchant_name': t['merchant_name'],
                'date': t['date'],
                'subcategory': t['subcategory'],
                'transaction_method': t['transaction_method'],
                'anomaly_flags': t['anomaly_flags'],
              })
          .toList();

      return await _llmService.generateFinancialInsights(transactionData);
    } catch (e) {
      _logger.e('Error generating financial insights: $e');
      return null;
    }
  }

  /// Re-analyze existing transactions with LLM
  Future<int> reAnalyzeExistingTransactions({
    Function(int current, int total, String currentTransaction)? onProgress,
  }) async {
    try {
      _logger.i('Starting LLM re-analysis of existing transactions...');

      final transactions = await _databaseHelper.query(
        'transactions',
        where: 'sms_content IS NOT NULL AND confidence_score IS NULL',
      );

      int reAnalyzedCount = 0;

      for (int i = 0; i < transactions.length; i++) {
        final transactionMap = transactions[i];
        final smsContent = transactionMap['sms_content'] as String?;
        if (smsContent == null || smsContent.isEmpty) continue;

        // Report progress
        onProgress?.call(
            i + 1, transactions.length, 'Transaction ${transactionMap['id']}');

        try {
          final llmAnalysis =
              await _llmService.analyzeSmsTransaction(smsContent);

          if (llmAnalysis != null) {
            // Update transaction with LLM insights
            await _databaseHelper.update(
              'transactions',
              {
                'recipient_or_sender': llmAnalysis.recipientOrSender,
                'available_balance': llmAnalysis.availableBalance,
                'subcategory': llmAnalysis.subcategory,
                'transaction_method': llmAnalysis.transactionMethod,
                'location': llmAnalysis.location,
                'reference_number': llmAnalysis.referenceNumber,
                'confidence_score': llmAnalysis.confidenceScore,
                'anomaly_flags': llmAnalysis.anomalyFlags.join(','),
                'llm_insights': llmAnalysis.insights,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [transactionMap['id']],
            );

            reAnalyzedCount++;
          }
        } catch (e) {
          _logger
              .e('Error re-analyzing transaction ${transactionMap['id']}: $e');
        }
      }

      _logger.i(
          'LLM re-analysis complete. $reAnalyzedCount transactions updated.');
      return reAnalyzedCount;
    } catch (e) {
      _logger.e('Error during LLM re-analysis: $e');
      return 0;
    }
  }

  /// Re-classify existing transactions using improved logic
  /// (Compatibility method for regular SMS service interface)
  Future<int> reclassifyExistingTransactions() async {
    try {
      _logger.i(
          'Starting LLM-powered re-classification of existing transactions...');

      // For enhanced service, we use LLM analysis instead of basic reclassification
      return await _reAnalyzeWithLLM();
    } catch (e) {
      _logger.e('Error during enhanced re-classification: $e');
      return 0;
    }
  }

  /// Internal method for LLM-based re-analysis
  Future<int> _reAnalyzeWithLLM() async {
    try {
      // Get transactions that need LLM analysis
      final transactions = await _databaseHelper.query(
        'transactions',
        where: 'sms_content IS NOT NULL AND confidence_score IS NULL',
      );

      int reAnalyzedCount = 0;

      for (final transactionMap in transactions) {
        final smsContent = transactionMap['sms_content'] as String?;
        if (smsContent == null || smsContent.isEmpty) continue;

        try {
          final llmAnalysis =
              await _llmService.analyzeSmsTransaction(smsContent);

          if (llmAnalysis != null) {
            // Update transaction with LLM insights
            await _databaseHelper.update(
              'transactions',
              {
                'recipient_or_sender': llmAnalysis.recipientOrSender,
                'available_balance': llmAnalysis.availableBalance,
                'subcategory': llmAnalysis.subcategory,
                'transaction_method': llmAnalysis.transactionMethod,
                'location': llmAnalysis.location,
                'reference_number': llmAnalysis.referenceNumber,
                'confidence_score': llmAnalysis.confidenceScore,
                'anomaly_flags': llmAnalysis.anomalyFlags.join(','),
                'llm_insights': llmAnalysis.insights,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [transactionMap['id']],
            );

            reAnalyzedCount++;
          }
        } catch (e) {
          _logger
              .e('Error re-analyzing transaction ${transactionMap['id']}: $e');
        }
      }

      _logger.i(
          'LLM re-analysis complete. $reAnalyzedCount transactions updated.');
      return reAnalyzedCount;
    } catch (e) {
      _logger.e('Error during LLM re-analysis: $e');
      return 0;
    }
  }
}
