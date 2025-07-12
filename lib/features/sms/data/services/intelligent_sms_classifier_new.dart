import 'package:string_similarity/string_similarity.dart';
import 'package:logger/logger.dart';

import '../../../transactions/domain/entities/transaction.dart';

/// Advanced SMS classification service using intelligent pattern matching
class IntelligentSmsClassifier {
  final Logger _logger = Logger();

  // Enhanced merchant patterns with better categorization
  static const Map<String, int> _merchantPatterns = {
    // Food & Dining (Category 1)
    'swiggy': 1, 'zomato': 1, 'dominos': 1, 'pizza': 1, 'restaurant': 1,
    'cafe': 1, 'food': 1, 'dining': 1, 'kitchen': 1, 'eat': 1,
    'bigbasket': 1, 'grofers': 1, 'grocery': 1, 'blinkit': 1, 'instamart': 1,
    'mcdonalds': 1, 'kfc': 1, 'subway': 1, 'starbucks': 1, 'dunkin': 1,
    'zepto': 1, 'fresh': 1, 'market': 1, 'dairy': 1, 'bread': 1,

    // Transport (Category 2)
    'uber': 2, 'ola': 2, 'rapido': 2, 'metro': 2, 'dmrc': 2,
    'petrol': 2, 'fuel': 2, 'gas': 2, 'cab': 2, 'taxi': 2,
    'parking': 2, 'toll': 2, 'bus': 2, 'train': 2, 'auto': 2,
    'bike': 2, 'scooter': 2, 'transport': 2, 'travel': 2,

    // Shopping (Category 3)
    'amazon': 3, 'flipkart': 3, 'myntra': 3, 'ajio': 3, 'nykaa': 3,
    'shopping': 3, 'store': 3, 'buy': 3, 'purchase': 3,
    'meesho': 3, 'shopsy': 3, 'reliance': 3, 'paytm': 3,
    'fashion': 3, 'clothing': 3, 'shoes': 3, 'electronics': 3,

    // Entertainment (Category 4)
    'netflix': 4, 'spotify': 4, 'prime': 4, 'hotstar': 4, 'youtube': 4,
    'movie': 4, 'cinema': 4, 'theater': 4, 'game': 4, 'music': 4,
    'book': 4, 'kindle': 4, 'disney': 4, 'zee5': 4, 'voot': 4,

    // Healthcare (Category 5)
    'hospital': 5, 'clinic': 5, 'pharmacy': 5, 'medical': 5, 'doctor': 5,
    'health': 5, 'medicine': 5, 'pharmeasy': 5, 'netmeds': 5, 'apollo': 5,
    'medplus': 5, 'wellness': 5, 'dental': 5, 'lab': 5,

    // Utilities (Category 6)
    'electricity': 6, 'water': 6, 'internet': 6, 'mobile': 6, 'recharge': 6,
    'bill': 6, 'utility': 6, 'broadband': 6, 'wifi': 6, 'phone': 6,
    'airtel': 6, 'jio': 6, 'vodafone': 6, 'bsnl': 6, 'tata': 6,

    // Education (Category 7)
    'school': 7, 'college': 7, 'university': 7, 'course': 7, 'textbook': 7,
    'tuition': 7, 'exam': 7, 'education': 7, 'learning': 7, 'fees': 7,

    // Income (Category 8)
    'salary': 8, 'wage': 8, 'bonus': 8, 'incentive': 8, 'refund': 8,
    'cashback': 8, 'reward': 8, 'credit': 8, 'deposit': 8, 'transfer': 8,
  };

  /// Advanced contextual keywords for better classification
  static const Map<int, List<String>> _contextualKeywords = {
    1: [
      'ordered',
      'delivered',
      'meal',
      'lunch',
      'dinner',
      'breakfast',
      'snack'
    ],
    2: ['trip', 'ride', 'journey', 'commute', 'station', 'airport'],
    3: ['order', 'cart', 'delivery', 'shipped', 'product', 'item'],
    4: ['subscription', 'premium', 'streaming', 'watch', 'listen'],
    5: ['treatment', 'consultation', 'prescription', 'test', 'checkup'],
    6: ['payment', 'due', 'monthly', 'connection', 'service'],
    7: ['admission', 'semester', 'class', 'training', 'certification'],
    8: ['credited', 'received', 'bonus', 'increment', 'salary'],
  };

  /// Classify SMS content into appropriate category
  Future<ClassificationResult> classifyTransaction({
    required String smsContent,
    required double amount,
    required TransactionType type,
    String? merchantName,
  }) async {
    try {
      _logger.i(
          'Classifying transaction: ${smsContent.length > 50 ? smsContent.substring(0, 50) : smsContent}...');

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

    // Priority 4: Amount-based heuristics
    if (type == TransactionType.income) {
      return 8; // Income
    }

    if (amount > 10000) {
      return 3; // Likely shopping for high amounts
    } else if (amount < 100) {
      return 1; // Likely food/small purchases
    }

    return 9; // Other category
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

  /// Generate smart description based on SMS content
  String _generateSmartDescription(String smsContent, TransactionType type) {
    final content = smsContent.toLowerCase();

    if (type == TransactionType.income) {
      if (content.contains('salary')) return 'Salary Credit';
      if (content.contains('refund')) return 'Refund Received';
      if (content.contains('cashback')) return 'Cashback';
      return 'Money Received';
    }

    // Extract meaningful description from SMS
    if (content.contains('food') || content.contains('restaurant')) {
      return 'Food & Dining';
    }
    if (content.contains('fuel') || content.contains('petrol')) {
      return 'Fuel Payment';
    }
    if (content.contains('movie') || content.contains('entertainment')) {
      return 'Entertainment';
    }
    if (content.contains('bill') || content.contains('utility')) {
      return 'Bill Payment';
    }
    if (content.contains('shopping') || content.contains('purchase')) {
      return 'Shopping';
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
