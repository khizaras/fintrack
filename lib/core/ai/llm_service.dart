import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// Enterprise-level LLM service using OpenRouter for financial SMS analysis
class LLMService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  final Logger _logger = Logger();
  final String _apiKey;
  final String _model;

  LLMService({required String apiKey, String? model})
      : _apiKey = apiKey,
        _model = model ?? 'deepseek/deepseek-r1';

  /// Analyze SMS content and extract detailed transaction information
  Future<LLMTransactionAnalysis?> analyzeSmsTransaction(
      String smsContent) async {
    try {
      final prompt = _buildAnalysisPrompt(smsContent);

      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://fintrack.app',
          'X-Title': 'FinTrack SMS Analysis',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(),
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature':
              0.1, // Low temperature for consistent financial analysis
          'max_tokens': 500,
          'response_format': {'type': 'json_object'},
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('LLM API request timed out after 30 seconds');
          throw http.ClientException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        try {
          final cleanedContent = _extractJsonFromResponse(content);
          final analysisJson = jsonDecode(cleanedContent);
          return LLMTransactionAnalysis.fromJson(analysisJson);
        } catch (e) {
          _logger.e('Failed to parse LLM response as JSON: $e');
          _logger.d('Raw response content: $content');
          return null;
        }
      } else if (response.statusCode == 429) {
        _logger.w('LLM API rate limit exceeded - quota may be full');
        return null;
      } else if (response.statusCode == 401) {
        _logger.w('LLM API authentication failed - check API key');
        return null;
      } else {
        _logger.e(
            'LLM API request failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        _logger.w('LLM service unavailable (network/timeout): $e');
      } else {
        _logger.e('Error calling LLM service: $e');
      }
      return null;
    }
  }

  /// Generate enterprise-level insights from transaction data
  Future<LLMInsights?> generateFinancialInsights(
      List<Map<String, dynamic>> transactions) async {
    try {
      final prompt = _buildInsightsPrompt(transactions);

      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://fintrack.app',
          'X-Title': 'FinTrack Financial Insights',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': _getInsightsSystemPrompt(),
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.3,
          'max_tokens': 1000,
          'response_format': {'type': 'json_object'},
        }),
      )
          .timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          _logger.w('LLM insights request timed out after 45 seconds');
          throw http.ClientException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        try {
          final cleanedContent = _extractJsonFromResponse(content);
          final insightsJson = jsonDecode(cleanedContent);
          return LLMInsights.fromJson(insightsJson);
        } catch (e) {
          _logger.e('Failed to parse insights response as JSON: $e');
          _logger.d('Raw response content: $content');
          return null;
        }
      } else if (response.statusCode == 429) {
        _logger
            .w('LLM API rate limit exceeded for insights - quota may be full');
        return null;
      } else if (response.statusCode == 401) {
        _logger.w('LLM API authentication failed for insights - check API key');
        return null;
      } else {
        _logger.e(
            'Insights API request failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        _logger.w('LLM service unavailable for insights (network/timeout): $e');
      } else {
        _logger.e('Error generating insights: $e');
      }
      return null;
    }
  }

  String _getSystemPrompt() {
    return '''You are an expert financial analyst AI specializing in SMS transaction analysis for Indian banking systems. 

Your task is to analyze SMS messages from banks and extract detailed transaction information with high accuracy.

Key Requirements:
1. Extract ALL relevant financial data from the SMS
2. Categorize transactions into specific categories
3. Identify transaction patterns and anomalies
4. Provide confidence scores for your analysis
5. Handle multiple Indian bank formats (SBI, HDFC, ICICI, AXIS, etc.)

Always respond in valid JSON format with the exact structure requested.''';
  }

  String _getInsightsSystemPrompt() {
    return '''You are an enterprise-level financial insights AI that provides actionable financial intelligence.

Analyze transaction patterns and provide:
1. Spending behavior insights
2. Anomaly detection and alerts
3. Budgeting recommendations
4. Financial health assessment
5. Predictive insights

Focus on providing practical, actionable advice that helps users make better financial decisions.

Always respond in valid JSON format.''';
  }

  String _buildAnalysisPrompt(String smsContent) {
    return '''Analyze this Indian bank SMS transaction and extract ALL relevant information:

SMS: "$smsContent"

Extract and return a JSON object with the following structure:
{
  "transaction_type": "credit" or "debit",
  "amount": 0.00,
  "date": "YYYY-MM-DD",
  "time": "HH:MM" (if available),
  "bank_name": "bank name from SMS",
  "recipient_or_sender": "merchant/recipient/sender name",
  "account_number": "last 4 digits or masked number",
  "available_balance": 0.00 (if mentioned),
  "category": "one of: Food & Dining, Transport, Shopping, Entertainment, Healthcare, Utilities, Education, Financial Services, Income, Others",
  "subcategory": "specific subcategory like 'Food Delivery', 'ATM Withdrawal', etc.",
  "merchant_name": "cleaned merchant name",
  "transaction_method": "UPI, ATM, POS, Online, Transfer, etc.",
  "location": "location if mentioned",
  "reference_number": "transaction reference if available",
  "description": "human-readable transaction description",
  "confidence_score": 0.95,
  "anomaly_flags": ["unusual_amount", "new_merchant", "late_night", etc.],
  "insights": "brief analysis of this transaction"
}

Be precise and extract every detail available in the SMS. If a field is not available, use null.''';
  }

  String _buildInsightsPrompt(List<Map<String, dynamic>> transactions) {
    return '''Analyze this user's transaction data and provide enterprise-level financial insights:

Transaction Data: ${jsonEncode(transactions.take(50).toList())}

Generate a comprehensive analysis and return a JSON object with:
{
  "financial_health_score": 0.85,
  "spending_patterns": {
    "primary_categories": ["Food & Dining", "Transport"],
    "peak_spending_times": ["Weekend evenings", "Month-end"],
    "preferred_merchants": ["Swiggy", "Ola", "Amazon"],
    "payment_methods": {"UPI": 60, "Card": 30, "Cash": 10}
  },
  "anomalies_detected": [
    {
      "type": "unusual_amount",
      "description": "Large transaction at new merchant",
      "severity": "medium",
      "transaction_id": "123",
      "recommendation": "Verify this transaction"
    }
  ],
  "budget_insights": {
    "top_overspend_categories": ["Food & Dining"],
    "potential_savings": 2500.00,
    "recommended_budget_allocation": {
      "Food": 8000,
      "Transport": 3000,
      "Entertainment": 2000
    }
  },
  "recommendations": [
    {
      "type": "budgeting",
      "title": "Optimize Food Spending",
      "description": "You spend 40% more on food delivery than average. Consider cooking more meals at home.",
      "potential_savings": 1500.00,
      "priority": "high"
    }
  ],
  "trends": {
    "monthly_growth": -5.2,
    "category_trends": {"Food": 10, "Transport": -15},
    "prediction_next_month": 25000.00
  },
  "merchant_insights": {
    "most_frequent": "Swiggy",
    "highest_spend": "Amazon",
    "new_merchants_this_month": 5,
    "merchant_loyalty_score": 0.7
  }
}

Provide actionable insights based on real spending patterns and financial best practices.''';
  }

  /// Extract JSON content from markdown code blocks if present
  String _extractJsonFromResponse(String content) {
    // Remove markdown code block formatting if present
    if (content.trim().startsWith('```json')) {
      final lines = content.split('\n');
      final startIndex =
          lines.indexWhere((line) => line.trim() == '```json') + 1;
      final endIndex = lines.lastIndexWhere((line) => line.trim() == '```');

      if (startIndex > 0 && endIndex > startIndex) {
        return lines.sublist(startIndex, endIndex).join('\n').trim();
      }
    }

    // Also handle single backtick formatting
    if (content.trim().startsWith('```') && content.trim().endsWith('```')) {
      final trimmed = content.trim();
      final firstNewline = trimmed.indexOf('\n');
      final lastNewline = trimmed.lastIndexOf('\n');

      if (firstNewline > -1 && lastNewline > firstNewline) {
        return trimmed.substring(firstNewline + 1, lastNewline).trim();
      }
    }

    // Return original content if no markdown formatting found
    return content.trim();
  }

  /// Test if the LLM service is available and working
  Future<bool> testConnection() async {
    try {
      _logger.i('Testing LLM service connection...');

      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://fintrack.app',
          'X-Title': 'FinTrack Connection Test',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': 'Test message - respond with {"status": "ok"}',
            }
          ],
          'temperature': 0.1,
          'max_tokens': 50,
          'response_format': {'type': 'json_object'},
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.w('LLM connection test timed out');
          throw http.ClientException('Connection test timeout');
        },
      );

      if (response.statusCode == 200) {
        _logger.i('✅ LLM service connection test successful');
        return true;
      } else if (response.statusCode == 429) {
        _logger.w('⚠️ LLM API rate limit reached - service will use fallback');
        return false;
      } else if (response.statusCode == 401) {
        _logger.w('⚠️ LLM API authentication failed - check API key');
        return false;
      } else {
        _logger.w('⚠️ LLM connection test failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        _logger.w('⚠️ LLM service unreachable (network issue): $e');
      } else {
        _logger.w('⚠️ LLM connection test error: $e');
      }
      return false;
    }
  }
}

/// Detailed transaction analysis result from LLM
class LLMTransactionAnalysis {
  final String transactionType;
  final double amount;
  final String? date;
  final String? time;
  final String? bankName;
  final String? recipientOrSender;
  final String? accountNumber;
  final double? availableBalance;
  final String category;
  final String? subcategory;
  final String? merchantName;
  final String? transactionMethod;
  final String? location;
  final String? referenceNumber;
  final String description;
  final double confidenceScore;
  final List<String> anomalyFlags;
  final String? insights;

  LLMTransactionAnalysis({
    required this.transactionType,
    required this.amount,
    this.date,
    this.time,
    this.bankName,
    this.recipientOrSender,
    this.accountNumber,
    this.availableBalance,
    required this.category,
    this.subcategory,
    this.merchantName,
    this.transactionMethod,
    this.location,
    this.referenceNumber,
    required this.description,
    required this.confidenceScore,
    required this.anomalyFlags,
    this.insights,
  });

  factory LLMTransactionAnalysis.fromJson(Map<String, dynamic> json) {
    return LLMTransactionAnalysis(
      transactionType: json['transaction_type'] ?? 'debit',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'],
      time: json['time'],
      bankName: json['bank_name'],
      recipientOrSender: json['recipient_or_sender'],
      accountNumber: json['account_number'],
      availableBalance: json['available_balance']?.toDouble(),
      category: json['category'] ?? 'Others',
      subcategory: json['subcategory'],
      merchantName: json['merchant_name'],
      transactionMethod: json['transaction_method'],
      location: json['location'],
      referenceNumber: json['reference_number'],
      description: json['description'] ?? 'Transaction',
      confidenceScore: (json['confidence_score'] ?? 0.8).toDouble(),
      anomalyFlags: List<String>.from(json['anomaly_flags'] ?? []),
      insights: json['insights'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_type': transactionType,
      'amount': amount,
      'date': date,
      'time': time,
      'bank_name': bankName,
      'recipient_or_sender': recipientOrSender,
      'account_number': accountNumber,
      'available_balance': availableBalance,
      'category': category,
      'subcategory': subcategory,
      'merchant_name': merchantName,
      'transaction_method': transactionMethod,
      'location': location,
      'reference_number': referenceNumber,
      'description': description,
      'confidence_score': confidenceScore,
      'anomaly_flags': anomalyFlags,
      'insights': insights,
    };
  }
}

/// Financial insights generated by LLM
class LLMInsights {
  final double financialHealthScore;
  final Map<String, dynamic> spendingPatterns;
  final List<Map<String, dynamic>> anomaliesDetected;
  final Map<String, dynamic> budgetInsights;
  final List<Map<String, dynamic>> recommendations;
  final Map<String, dynamic> trends;
  final Map<String, dynamic> merchantInsights;

  LLMInsights({
    required this.financialHealthScore,
    required this.spendingPatterns,
    required this.anomaliesDetected,
    required this.budgetInsights,
    required this.recommendations,
    required this.trends,
    required this.merchantInsights,
  });

  factory LLMInsights.fromJson(Map<String, dynamic> json) {
    return LLMInsights(
      financialHealthScore: (json['financial_health_score'] ?? 0.7).toDouble(),
      spendingPatterns: json['spending_patterns'] ?? {},
      anomaliesDetected:
          List<Map<String, dynamic>>.from(json['anomalies_detected'] ?? []),
      budgetInsights: json['budget_insights'] ?? {},
      recommendations:
          List<Map<String, dynamic>>.from(json['recommendations'] ?? []),
      trends: json['trends'] ?? {},
      merchantInsights: json['merchant_insights'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financial_health_score': financialHealthScore,
      'spending_patterns': spendingPatterns,
      'anomalies_detected': anomaliesDetected,
      'budget_insights': budgetInsights,
      'recommendations': recommendations,
      'trends': trends,
      'merchant_insights': merchantInsights,
    };
  }
}
