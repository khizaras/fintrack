import 'package:logger/logger.dart';

import '../../../transactions/domain/entities/transaction.dart';

/// Advanced SMS classification service using intelligent pattern matching
class IntelligentSmsClassifier {
  final Logger _logger = Logger();

  // Comprehensive merchant patterns with detailed categorization
  static const Map<String, int> _merchantPatterns = {
    // Food & Dining (Category 1)
    'swiggy': 1, 'zomato': 1, 'dominos': 1, 'pizza': 1, 'restaurant': 1,
    'cafe': 1, 'food': 1, 'dining': 1, 'kitchen': 1, 'eatery': 1,
    'bigbasket': 1, 'grofers': 1, 'grocery': 1, 'blinkit': 1, 'instamart': 1,
    'mcdonalds': 1, 'kfc': 1, 'subway': 1, 'starbucks': 1, 'dunkin': 1,
    'zepto': 1, 'fresh': 1, 'market': 1, 'dairy': 1, 'bakery': 1,
    'fresco': 1, 'haldirams': 1, 'punjab': 1, 'biryani': 1,

    // Transport (Category 2)
    'uber': 2, 'ola': 2, 'rapido': 2, 'metro': 2, 'dmrc': 2,
    'petrol': 2, 'fuel': 2, 'gas': 2, 'cab': 2, 'taxi': 2,
    'parking': 2, 'toll': 2, 'bus': 2, 'train': 2, 'auto': 2,
    'bike': 2, 'scooter': 2, 'transport': 2, 'travel': 2,
    'irctc': 2, 'makemytrip': 2, 'redbus': 2, 'goibibo': 2,

    // Shopping (Category 3)
    'amazon': 3, 'flipkart': 3, 'myntra': 3, 'ajio': 3, 'nykaa': 3,
    'shopping': 3, 'store': 3, 'mall': 3, 'bazaar': 3,
    'meesho': 3, 'shopsy': 3, 'reliance': 3, 'lifestyle': 3,
    'max': 3, 'westside': 3, 'pantaloons': 3, 'brand': 3,
    'fashion': 3, 'clothing': 3, 'shoes': 3, 'electronics': 3,

    // Entertainment & Subscriptions (Category 4)
    'netflix': 4, 'spotify': 4, 'prime': 4, 'hotstar': 4, 'youtube': 4,
    'movie': 4, 'cinema': 4, 'theater': 4, 'game': 4, 'music': 4,
    'book': 4, 'kindle': 4, 'disney': 4, 'zee5': 4, 'voot': 4,
    'subscription': 4, 'premium': 4, 'entertainment': 4,

    // Healthcare (Category 5)
    'hospital': 5, 'clinic': 5, 'pharmacy': 5, 'medical': 5, 'doctor': 5,
    'health': 5, 'medicine': 5, 'pharmeasy': 5, 'netmeds': 5, 'apollo': 5,
    'medplus': 5, 'wellness': 5, 'dental': 5, 'lab': 5, 'diagnostic': 5,

    // Utilities & Bills (Category 6)
    'electricity': 6, 'water': 6, 'internet': 6, 'mobile': 6, 'recharge': 6,
    'bill': 6, 'utility': 6, 'broadband': 6, 'wifi': 6, 'phone': 6,
    'airtel': 6, 'jio': 6, 'vodafone': 6, 'bsnl': 6, 'tata': 6,
    'payment': 6, 'service': 6, 'connection': 6,

    // Education (Category 7)
    'school': 7, 'college': 7, 'university': 7, 'course': 7, 'textbook': 7,
    'tuition': 7, 'exam': 7, 'education': 7, 'learning': 7, 'fees': 7,
    'byju': 7, 'unacademy': 7, 'vedantu': 7, 'coursera': 7,

    // Financial Services (Category 8)
    'insurance': 8, 'mutual': 8, 'fund': 8, 'loan': 8, 'emi': 8,
    'bank': 8, 'sip': 8, 'investment': 8, 'fd': 8, 'rd': 8,
    'policy': 8, 'insurance_premium': 8, 'interest_payment': 8,

    // Income Sources (Category 9)
    'salary': 9, 'wage': 9, 'bonus': 9, 'incentive': 9, 'refund': 9,
    'cashback': 9, 'reward': 9, 'dividend': 9, 'interest_earned': 9,
  };

  // Enhanced contextual keywords for better classification
  static const Map<int, List<String>> _contextualKeywords = {
    1: [
      'ordered',
      'delivered',
      'meal',
      'lunch',
      'dinner',
      'breakfast',
      'snack',
      'grocery',
      'food'
    ],
    2: [
      'trip',
      'ride',
      'journey',
      'commute',
      'station',
      'airport',
      'booking',
      'ticket'
    ],
    3: [
      'order',
      'cart',
      'delivery',
      'shipped',
      'product',
      'item',
      'purchase',
      'buy'
    ],
    4: [
      'subscription',
      'premium',
      'streaming',
      'watch',
      'listen',
      'entertainment'
    ],
    5: [
      'treatment',
      'consultation',
      'prescription',
      'test',
      'checkup',
      'medicine'
    ],
    6: [
      'payment',
      'due',
      'monthly',
      'connection',
      'service',
      'bill',
      'recharge'
    ],
    7: [
      'admission',
      'semester',
      'class',
      'training',
      'certification',
      'course'
    ],
    8: ['insurance', 'premium', 'loan', 'emi', 'investment', 'policy'],
    9: [
      'credited',
      'received',
      'bonus',
      'increment',
      'salary',
      'refund',
      'cashback'
    ],
  };

  // Critical transaction type keywords with priority
  static const Map<String, TransactionType> _transactionTypeKeywords = {
    // Expense indicators (higher priority)
    'debited': TransactionType.expense,
    'debit': TransactionType.expense,
    'paid': TransactionType.expense,
    'spent': TransactionType.expense,
    'withdrawn': TransactionType.expense,
    'purchase': TransactionType.expense,
    'charged': TransactionType.expense,
    'billed': TransactionType.expense,
    'transferred to': TransactionType.expense,
    'payment made': TransactionType.expense,

    // Income indicators
    'credited': TransactionType.income,
    'credit': TransactionType.income,
    'deposited': TransactionType.income,
    'received': TransactionType.income,
    'refund': TransactionType.income,
    'cashback': TransactionType.income,
    'bonus': TransactionType.income,
    'salary': TransactionType.income,
    'transferred from': TransactionType.income,
  };

  /// Determine transaction type with improved logic
  TransactionType determineTransactionType(String smsContent) {
    final content = smsContent.toLowerCase();

    // Score-based approach for better accuracy
    int expenseScore = 0;
    int incomeScore = 0;

    for (final entry in _transactionTypeKeywords.entries) {
      if (content.contains(entry.key)) {
        if (entry.value == TransactionType.expense) {
          expenseScore += _getKeywordWeight(entry.key);
        } else {
          incomeScore += _getKeywordWeight(entry.key);
        }
      }
    }

    // Handle complex cases like "debited from your account and credited to recipient"
    if (content.contains('debited') && content.contains('your account')) {
      expenseScore += 10; // High weight for money leaving your account
    }

    if (content.contains('credited') && content.contains('to recipient')) {
      expenseScore += 5; // This is still an expense for you
    }

    // Check for specific patterns
    if (content.contains('payment successful') ||
        content.contains('transaction successful')) {
      expenseScore += 3;
    }

    if (content.contains('amount received') ||
        content.contains('money credited')) {
      incomeScore += 5;
    }

    _logger.d(
        'Transaction type analysis - Expense: $expenseScore, Income: $incomeScore');

    return expenseScore > incomeScore
        ? TransactionType.expense
        : TransactionType.income;
  }

  /// Get weight for keywords based on their reliability
  int _getKeywordWeight(String keyword) {
    switch (keyword) {
      case 'debited':
      case 'credited':
        return 5;
      case 'paid':
      case 'received':
        return 4;
      case 'spent':
      case 'withdrawn':
        return 3;
      default:
        return 2;
    }
  }

  /// Classify SMS content into appropriate category
  Future<ClassificationResult> classifyTransaction({
    required String smsContent,
    required double amount,
    required TransactionType type,
    String? merchantName,
  }) async {
    try {
      _logger.i('Classifying transaction: ${smsContent.substring(0, 50)}...');

      final categoryId = _intelligentCategoryClassification(
        smsContent,
        merchantName,
        amount,
        type,
      );

      final enhancedMerchant = _extractMerchantName(smsContent, merchantName);
      final smartDescription = _generateSmartDescription(smsContent, type);

      return ClassificationResult(
        categoryId: categoryId,
        extractedMerchant: enhancedMerchant,
        suggestedDescription: smartDescription,
        classificationMethod: 'intelligent_pattern_matching',
      );
    } catch (e) {
      _logger.e('Classification failed: $e');
      return ClassificationResult(
        categoryId: 9, // Other
        extractedMerchant: merchantName,
        suggestedDescription: 'Transaction',
        classificationMethod: 'fallback',
      );
    }
  }

  /// Intelligent category classification using multiple signals
  int _intelligentCategoryClassification(
    String smsContent,
    String? merchantName,
    double amount,
    TransactionType type,
  ) {
    final content = smsContent.toLowerCase();
    final merchant = merchantName?.toLowerCase() ?? '';

    // Priority 1: Direct merchant name matching
    for (final entry in _merchantPatterns.entries) {
      if (merchant.contains(entry.key)) {
        return entry.value;
      }
    }

    // Priority 2: SMS content merchant matching
    for (final entry in _merchantPatterns.entries) {
      if (content.contains(entry.key)) {
        return entry.value;
      }
    }

    // Priority 3: Contextual keyword analysis
    int bestCategory = 9;
    int maxMatches = 0;

    for (final entry in _contextualKeywords.entries) {
      int matches = 0;
      for (final keyword in entry.value) {
        if (content.contains(keyword)) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestCategory = entry.key;
      }
    }

    if (maxMatches > 0) {
      return bestCategory;
    }

    // Priority 4: Amount-based heuristics with better logic
    if (type == TransactionType.income) {
      return 9; // Income Sources
    }

    // Enhanced amount-based categorization
    if (amount > 50000) {
      return 8; // Likely financial services (EMI, insurance, etc.)
    } else if (amount > 10000) {
      return 3; // Likely shopping for high amounts
    } else if (amount > 5000) {
      // Check for utility bills
      if (content.contains('bill') ||
          content.contains('utility') ||
          content.contains('electricity') ||
          content.contains('water')) {
        return 6;
      }
      return 3; // Shopping
    } else if (amount > 1000) {
      // Medical or education
      if (content.contains('medical') ||
          content.contains('health') ||
          content.contains('doctor') ||
          content.contains('hospital')) {
        return 5;
      }
      if (content.contains('education') ||
          content.contains('course') ||
          content.contains('fees') ||
          content.contains('school')) {
        return 7;
      }
      return 2; // Transport for medium amounts
    } else if (amount < 500) {
      return 1; // Likely food/small purchases
    }

    // Priority 5: Time-based patterns
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 11 && amount < 200) {
      return 1; // Morning food purchases
    }
    if (hour >= 12 && hour <= 14 && amount < 300) {
      return 1; // Lunch time
    }
    if (hour >= 19 && hour <= 22 && amount < 500) {
      return 1; // Dinner time
    }

    return 10; // Other category
  }

  /// Extract and enhance merchant name
  String? _extractMerchantName(String smsContent, String? existingMerchant) {
    if (existingMerchant != null && existingMerchant.isNotEmpty) {
      return existingMerchant;
    }

    final content = smsContent.toLowerCase();

    // Look for known merchants in SMS content
    for (final merchant in _merchantPatterns.keys) {
      if (content.contains(merchant)) {
        return merchant.toUpperCase();
      }
    }

    // Extract text between common patterns
    final patterns = [
      RegExp(r'at\s+([A-Z\s]+)\s+on', caseSensitive: false),
      RegExp(r'to\s+([A-Z\s]+)\s+for', caseSensitive: false),
      RegExp(r'paid\s+to\s+([A-Z\s]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(smsContent);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    return null;
  }

  /// Generate smart description based on SMS content and category
  String _generateSmartDescription(String smsContent, TransactionType type) {
    final content = smsContent.toLowerCase();

    if (type == TransactionType.income) {
      if (content.contains('salary')) return 'Salary Credit';
      if (content.contains('refund')) return 'Refund Received';
      if (content.contains('cashback')) return 'Cashback';
      if (content.contains('bonus')) return 'Bonus Payment';
      if (content.contains('interest')) return 'Interest Earned';
      if (content.contains('dividend')) return 'Dividend';
      return 'Money Received';
    }

    // Enhanced expense descriptions
    if (content.contains('swiggy') || content.contains('zomato')) {
      return 'Food Delivery';
    }
    if (content.contains('uber') || content.contains('ola')) {
      return 'Cab Ride';
    }
    if (content.contains('amazon') || content.contains('flipkart')) {
      return 'Online Shopping';
    }
    if (content.contains('netflix') || content.contains('spotify')) {
      return 'Subscription';
    }
    if (content.contains('petrol') || content.contains('fuel')) {
      return 'Fuel Payment';
    }
    if (content.contains('electricity') || content.contains('water')) {
      return 'Utility Bill';
    }
    if (content.contains('insurance') || content.contains('premium')) {
      return 'Insurance Premium';
    }
    if (content.contains('emi') || content.contains('loan')) {
      return 'EMI Payment';
    }
    if (content.contains('medical') || content.contains('pharmacy')) {
      return 'Healthcare';
    }
    if (content.contains('school') || content.contains('education')) {
      return 'Education Fee';
    }

    // Generic patterns
    if (content.contains('food') ||
        content.contains('restaurant') ||
        content.contains('dining')) {
      return 'Food & Dining';
    }
    if (content.contains('movie') ||
        content.contains('cinema') ||
        content.contains('entertainment')) {
      return 'Entertainment';
    }
    if (content.contains('bill') || content.contains('payment')) {
      return 'Bill Payment';
    }
    if (content.contains('shopping') ||
        content.contains('purchase') ||
        content.contains('buy')) {
      return 'Shopping';
    }
    if (content.contains('transfer') || content.contains('sent')) {
      return 'Money Transfer';
    }
    if (content.contains('withdrawal') || content.contains('atm')) {
      return 'Cash Withdrawal';
    }

    return 'Payment';
  }
}

/// Result of SMS classification
class ClassificationResult {
  final int categoryId;
  final String? extractedMerchant;
  final String suggestedDescription;
  final String classificationMethod;

  const ClassificationResult({
    required this.categoryId,
    this.extractedMerchant,
    required this.suggestedDescription,
    required this.classificationMethod,
  });
}
