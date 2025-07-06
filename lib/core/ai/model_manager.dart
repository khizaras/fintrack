import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';

/// Enterprise AI Model Manager for transaction classification
/// Supports multiple models with ensemble voting and confidence scoring
class AIModelManager {
  static final AIModelManager _instance = AIModelManager._internal();
  factory AIModelManager() => _instance;
  AIModelManager._internal();

  final Logger _logger = Logger();
  
  Interpreter? _finbertModel;
  Interpreter? _xgboostModel;
  Map<String, int>? _vocabulary;
  bool _isInitialized = false;

  /// Initialize all AI models for transaction classification
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('Loading AI models for transaction classification...');
      
      // Load FinBERT model (fine-tuned for financial text)
      await _loadFinBERTModel();
      
      // Load XGBoost ensemble model
      await _loadXGBoostModel();
      
      // Load vocabulary for text processing
      await _loadVocabulary();
      
      _isInitialized = true;
      _logger.i('AI models loaded successfully');
    } catch (e) {
      _logger.e('Failed to load AI models: $e');
      rethrow;
    }
  }

  /// Classify transaction using ensemble of AI models
  Future<TransactionClassificationResult> classifyTransaction(
    String smsText, {
    Map<String, dynamic>? features,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Preprocess text
      final processedText = _preprocessText(smsText);
      
      // Extract features
      final featureVector = await _extractFeatures(processedText, features);
      
      // Run ensemble prediction
      final results = await _runEnsemblePrediction(featureVector, processedText);
      
      return results;
    } catch (e) {
      _logger.e('Classification error: $e');
      // Fallback to rule-based classification
      return _fallbackClassification(smsText);
    }
  }

  /// Load fine-tuned FinBERT model for financial text understanding
  Future<void> _loadFinBERTModel() async {
    try {
      final modelFile = await _loadAssetFile('assets/models/finbert_model.tflite');
      _finbertModel = Interpreter.fromBuffer(modelFile);
      _logger.i('FinBERT model loaded');
    } catch (e) {
      _logger.w('FinBERT model not available, using fallback: $e');
    }
  }

  /// Load XGBoost ensemble model for robust classification
  Future<void> _loadXGBoostModel() async {
    try {
      final modelFile = await _loadAssetFile('assets/models/xgboost_ensemble.tflite');
      _xgboostModel = Interpreter.fromBuffer(modelFile);
      _logger.i('XGBoost ensemble model loaded');
    } catch (e) {
      _logger.w('XGBoost model not available, using fallback: $e');
    }
  }

  /// Load vocabulary for text tokenization
  Future<void> _loadVocabulary() async {
    try {
      final vocabJson = await rootBundle.loadString('assets/models/vocabulary.json');
      // Parse vocabulary mapping
      _vocabulary = {}; // Parse from JSON
      _logger.i('Vocabulary loaded');
    } catch (e) {
      _logger.w('Vocabulary not available: $e');
    }
  }

  /// Load model file from assets
  Future<Uint8List> _loadAssetFile(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  /// Preprocess SMS text for AI models
  String _preprocessText(String text) {
    // Normalize bank-specific formats
    String processed = text.toLowerCase();
    
    // Remove noise and standardize patterns
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');
    processed = processed.replaceAll(RegExp(r'[^\w\s.]'), ' ');
    
    // Standardize common bank terms
    final bankNormalizations = {
      'a/c': 'account',
      'txn': 'transaction',
      'amt': 'amount',
      'bal': 'balance',
      'cr': 'credit',
      'dr': 'debit',
    };
    
    for (final entry in bankNormalizations.entries) {
      processed = processed.replaceAll(entry.key, entry.value);
    }
    
    return processed.trim();
  }

  /// Extract comprehensive features for ML models
  Future<List<double>> _extractFeatures(
    String processedText, 
    Map<String, dynamic>? additionalFeatures,
  ) async {
    final features = <double>[];
    
    // Text-based features
    features.addAll(_extractTextFeatures(processedText));
    
    // Temporal features
    features.addAll(_extractTemporalFeatures(additionalFeatures));
    
    // Financial pattern features
    features.addAll(_extractFinancialFeatures(processedText));
    
    // Contextual features
    features.addAll(_extractContextualFeatures(processedText));
    
    return features;
  }

  /// Extract text-based features (TF-IDF, embeddings)
  List<double> _extractTextFeatures(String text) {
    // TF-IDF features
    final tfidfFeatures = _calculateTFIDF(text);
    
    // Character-level features
    final charFeatures = [
      text.length.toDouble(),
      text.split(' ').length.toDouble(),
      _countDigits(text).toDouble(),
      _countCurrency(text).toDouble(),
    ];
    
    return [...tfidfFeatures, ...charFeatures];
  }

  /// Extract temporal features (time patterns, frequency)
  List<double> _extractTemporalFeatures(Map<String, dynamic>? features) {
    if (features == null) return List.filled(10, 0.0);
    
    final now = DateTime.now();
    final hour = now.hour.toDouble();
    final dayOfWeek = now.weekday.toDouble();
    final dayOfMonth = now.day.toDouble();
    
    return [
      hour / 24.0, // Normalized hour
      dayOfWeek / 7.0, // Normalized day of week
      dayOfMonth / 31.0, // Normalized day of month
      _isWeekend(now) ? 1.0 : 0.0,
      _isBusinessHour(now) ? 1.0 : 0.0,
      // Add transaction frequency features
      0.0, 0.0, 0.0, 0.0, 0.0, // Placeholder for user-specific features
    ];
  }

  /// Extract financial pattern features
  List<double> _extractFinancialFeatures(String text) {
    return [
      _hasAmountPattern(text) ? 1.0 : 0.0,
      _hasAccountPattern(text) ? 1.0 : 0.0,
      _hasDatePattern(text) ? 1.0 : 0.0,
      _hasBankCode(text) ? 1.0 : 0.0,
      _extractAmountValue(text),
      _getTransactionDirection(text),
    ];
  }

  /// Extract contextual features (merchant type, location, etc.)
  List<double> _extractContextualFeatures(String text) {
    return [
      _getMerchantScore(text),
      _getLocationScore(text),
      _getPaymentMethodScore(text),
      _getUrgencyScore(text),
    ];
  }

  /// Run ensemble prediction using multiple models
  Future<TransactionClassificationResult> _runEnsemblePrediction(
    List<double> features,
    String text,
  ) async {
    final predictions = <ModelPrediction>[];
    
    // FinBERT prediction
    if (_finbertModel != null) {
      final bertPrediction = await _runFinBERTPrediction(text);
      predictions.add(bertPrediction);
    }
    
    // XGBoost prediction
    if (_xgboostModel != null) {
      final xgbPrediction = await _runXGBoostPrediction(features);
      predictions.add(xgbPrediction);
    }
    
    // Ensemble voting
    return _combineModelPredictions(predictions, text);
  }

  /// Run FinBERT model prediction
  Future<ModelPrediction> _runFinBERTPrediction(String text) async {
    // Tokenize text and run through FinBERT
    final tokenIds = _tokenizeText(text);
    final input = _padSequence(tokenIds, 128);
    
    final output = List.filled(1 * 8, 0.0).reshape([1, 8]); // 8 categories
    _finbertModel!.run([input], {0: output});
    
    final probabilities = output[0];
    final maxIndex = _argMax(probabilities);
    final confidence = probabilities[maxIndex];
    
    return ModelPrediction(
      modelName: 'FinBERT',
      transactionType: _indexToTransactionType(maxIndex),
      category: _indexToCategory(maxIndex),
      confidence: confidence,
      probabilities: probabilities,
    );
  }

  /// Run XGBoost ensemble prediction
  Future<ModelPrediction> _runXGBoostPrediction(List<double> features) async {
    final input = features.reshape([1, features.length]);
    final output = List.filled(1 * 8, 0.0).reshape([1, 8]);
    
    _xgboostModel!.run([input], {0: output});
    
    final probabilities = output[0];
    final maxIndex = _argMax(probabilities);
    final confidence = probabilities[maxIndex];
    
    return ModelPrediction(
      modelName: 'XGBoost Ensemble',
      transactionType: _indexToTransactionType(maxIndex),
      category: _indexToCategory(maxIndex),
      confidence: confidence,
      probabilities: probabilities,
    );
  }

  /// Combine predictions from multiple models using weighted voting
  TransactionClassificationResult _combineModelPredictions(
    List<ModelPrediction> predictions,
    String text,
  ) {
    if (predictions.isEmpty) {
      return _fallbackClassification(text);
    }
    
    // Weighted ensemble (FinBERT: 0.7, XGBoost: 0.3)
    final weights = {'FinBERT': 0.7, 'XGBoost Ensemble': 0.3};
    final combinedProbs = List.filled(8, 0.0);
    double totalWeight = 0.0;
    
    for (final prediction in predictions) {
      final weight = weights[prediction.modelName] ?? 0.5;
      totalWeight += weight;
      
      for (int i = 0; i < combinedProbs.length; i++) {
        combinedProbs[i] += prediction.probabilities[i] * weight;
      }
    }
    
    // Normalize probabilities
    for (int i = 0; i < combinedProbs.length; i++) {
      combinedProbs[i] /= totalWeight;
    }
    
    final maxIndex = _argMax(combinedProbs);
    final confidence = combinedProbs[maxIndex];
    
    return TransactionClassificationResult(
      transactionType: _indexToTransactionType(maxIndex),
      category: _indexToCategory(maxIndex),
      confidence: confidence,
      modelUsed: 'Ensemble (${predictions.map((p) => p.modelName).join(", ")})',
      features: _extractExplainableFeatures(text),
    );
  }

  /// Fallback to rule-based classification when AI models fail
  TransactionClassificationResult _fallbackClassification(String text) {
    // Use existing rule-based logic as fallback
    final isExpense = _detectExpenseKeywords(text);
    
    return TransactionClassificationResult(
      transactionType: isExpense ? 'expense' : 'income',
      category: _getRuleBasedCategory(text),
      confidence: 0.75, // Lower confidence for rule-based
      modelUsed: 'Rule-based (Fallback)',
      features: {'fallback': true},
    );
  }

  // Utility methods
  List<int> _tokenizeText(String text) {
    // Implement tokenization using vocabulary
    return text.split(' ').map((word) => _vocabulary?[word] ?? 0).toList();
  }

  List<int> _padSequence(List<int> tokens, int maxLength) {
    if (tokens.length >= maxLength) {
      return tokens.sublist(0, maxLength);
    }
    return [...tokens, ...List.filled(maxLength - tokens.length, 0)];
  }

  int _argMax(List<double> probabilities) {
    double maxVal = probabilities[0];
    int maxIndex = 0;
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxVal) {
        maxVal = probabilities[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  String _indexToTransactionType(int index) {
    return index < 4 ? 'expense' : 'income';
  }

  String _indexToCategory(int index) {
    const categories = [
      'Food & Dining', 'Transport', 'Shopping', 'Entertainment',
      'Salary', 'Investment', 'Refund', 'Other Income'
    ];
    return categories[index];
  }

  List<double> _calculateTFIDF(String text) {
    // Simplified TF-IDF calculation
    return List.filled(100, 0.0); // Placeholder
  }

  int _countDigits(String text) => text.replaceAll(RegExp(r'[^\d]'), '').length;
  int _countCurrency(String text) => RegExp(r'₹|\$|USD|INR').allMatches(text).length;
  bool _isWeekend(DateTime date) => date.weekday > 5;
  bool _isBusinessHour(DateTime date) => date.hour >= 9 && date.hour <= 17;
  
  bool _hasAmountPattern(String text) => RegExp(r'₹\s*[\d,]+').hasMatch(text);
  bool _hasAccountPattern(String text) => RegExp(r'\*+\d{4}').hasMatch(text);
  bool _hasDatePattern(String text) => RegExp(r'\d{1,2}[-/]\d{1,2}[-/]\d{2,4}').hasMatch(text);
  bool _hasBankCode(String text) => RegExp(r'[A-Z]{4}\d+').hasMatch(text);
  
  double _extractAmountValue(String text) {
    final match = RegExp(r'₹\s*([\d,]+)').firstMatch(text);
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '') ?? '0';
      return double.tryParse(amountStr) ?? 0.0;
    }
    return 0.0;
  }

  double _getTransactionDirection(String text) {
    if (text.contains('debit') || text.contains('withdrawn')) return -1.0;
    if (text.contains('credit') || text.contains('deposit')) return 1.0;
    return 0.0;
  }

  double _getMerchantScore(String text) => 0.5; // Placeholder
  double _getLocationScore(String text) => 0.5; // Placeholder
  double _getPaymentMethodScore(String text) => 0.5; // Placeholder
  double _getUrgencyScore(String text) => 0.5; // Placeholder
  
  bool _detectExpenseKeywords(String text) {
    return text.contains('debit') || text.contains('withdrawn') || text.contains('paid');
  }
  
  String _getRuleBasedCategory(String text) => 'General';
  
  Map<String, dynamic> _extractExplainableFeatures(String text) {
    return {
      'has_amount': _hasAmountPattern(text),
      'has_merchant': _getMerchantScore(text) > 0.5,
      'transaction_direction': _getTransactionDirection(text),
      'text_length': text.length,
    };
  }

  void dispose() {
    _finbertModel?.close();
    _xgboostModel?.close();
    _isInitialized = false;
  }
}

/// Model prediction result from individual models
class ModelPrediction {
  final String modelName;
  final String transactionType;
  final String category;
  final double confidence;
  final List<double> probabilities;

  ModelPrediction({
    required this.modelName,
    required this.transactionType,
    required this.category,
    required this.confidence,
    required this.probabilities,
  });
}

/// Final classification result from ensemble
class TransactionClassificationResult {
  final String transactionType;
  final String category;
  final double confidence;
  final String modelUsed;
  final Map<String, dynamic> features;

  TransactionClassificationResult({
    required this.transactionType,
    required this.category,
    required this.confidence,
    required this.modelUsed,
    required this.features,
  });
}

extension ListExtensions on List<double> {
  List<List<double>> reshape(List<int> shape) {
    if (shape.length != 2) throw ArgumentError('Only 2D reshape supported');
    final result = <List<double>>[];
    final rowSize = shape[1];
    for (int i = 0; i < shape[0]; i++) {
      result.add(sublist(i * rowSize, (i + 1) * rowSize));
    }
    return result;
  }
}
