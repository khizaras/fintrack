import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Configuration service for enterprise features and API keys
class EnterpriseConfigService {
  static const String _openRouterApiKeyKey = 'openrouter_api_key';
  static const String _llmEnabledKey = 'llm_enabled';
  static const String _autoAnalysisEnabledKey = 'auto_analysis_enabled';
  static const String _llmModelKey = 'llm_model';

  final Logger _logger = Logger();
  static EnterpriseConfigService? _instance;

  EnterpriseConfigService._();

  static EnterpriseConfigService get instance {
    _instance ??= EnterpriseConfigService._();
    return _instance!;
  }

  /// Get OpenRouter API key
  Future<String?> getOpenRouterApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_openRouterApiKeyKey);
    } catch (e) {
      _logger.e('Error getting OpenRouter API key: $e');
      return null;
    }
  }

  /// Set OpenRouter API key
  Future<bool> setOpenRouterApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_openRouterApiKeyKey, apiKey);
      _logger.i('OpenRouter API key ${success ? 'saved' : 'failed to save'}');
      return success;
    } catch (e) {
      _logger.e('Error setting OpenRouter API key: $e');
      return false;
    }
  }

  /// Check if LLM features are enabled
  Future<bool> isLLMEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_llmEnabledKey) ?? false;
    } catch (e) {
      _logger.e('Error checking LLM enabled status: $e');
      return false;
    }
  }

  /// Enable/disable LLM features
  Future<bool> setLLMEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_llmEnabledKey, enabled);
      _logger.i('LLM features ${enabled ? 'enabled' : 'disabled'}');
      return success;
    } catch (e) {
      _logger.e('Error setting LLM enabled status: $e');
      return false;
    }
  }

  /// Check if auto-analysis is enabled
  Future<bool> isAutoAnalysisEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoAnalysisEnabledKey) ?? true;
    } catch (e) {
      _logger.e('Error checking auto-analysis enabled status: $e');
      return true;
    }
  }

  /// Enable/disable auto-analysis
  Future<bool> setAutoAnalysisEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_autoAnalysisEnabledKey, enabled);
      _logger.i('Auto-analysis ${enabled ? 'enabled' : 'disabled'}');
      return success;
    } catch (e) {
      _logger.e('Error setting auto-analysis enabled status: $e');
      return false;
    }
  }

  /// Get selected LLM model
  Future<String> getLLMModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_llmModelKey) ?? 'deepseek/deepseek-r1';
    } catch (e) {
      _logger.e('Error getting LLM model: $e');
      return 'deepseek/deepseek-r1';
    }
  }

  /// Set LLM model
  Future<bool> setLLMModel(String model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_llmModelKey, model);
      _logger.i('LLM model set to: $model');
      return success;
    } catch (e) {
      _logger.e('Error setting LLM model: $e');
      return false;
    }
  }

  /// Get available OpenRouter models for financial analysis
  List<Map<String, String>> getAvailableModels() {
    return [
      {
        'id': 'deepseek/deepseek-r1',
        'name': 'DeepSeek R1',
        'description': 'Best for financial analysis (Free tier available)',
        'cost': 'Free tier: \$5 credit',
      },
      {
        'id': 'google/gemini-2.0-flash-exp:free',
        'name': 'Google Gemini 2.0 Flash',
        'description': 'Fast and accurate (Free)',
        'cost': 'Free',
      },
      {
        'id': 'meta-llama/llama-3.2-3b-instruct:free',
        'name': 'Llama 3.2 3B',
        'description': 'Lightweight and efficient (Free)',
        'cost': 'Free',
      },
      {
        'id': 'qwen/qwen-2.5-7b-instruct:free',
        'name': 'Qwen 2.5 7B',
        'description': 'Good for general analysis (Free)',
        'cost': 'Free',
      },
      {
        'id': 'mistralai/mistral-7b-instruct:free',
        'name': 'Mistral 7B',
        'description': 'Balanced performance (Free)',
        'cost': 'Free',
      },
      {
        'id': 'anthropic/claude-3.5-sonnet',
        'name': 'Claude 3.5 Sonnet',
        'description': 'Premium model with excellent reasoning (Paid)',
        'cost': '\$3 per 1M tokens',
      },
      {
        'id': 'openai/gpt-4o',
        'name': 'GPT-4o',
        'description': 'OpenAI\'s flagship model (Paid)',
        'cost': '\$5 per 1M tokens',
      },
    ];
  }

  /// Clear all configuration
  Future<bool> clearAllConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_openRouterApiKeyKey);
      await prefs.remove(_llmEnabledKey);
      await prefs.remove(_autoAnalysisEnabledKey);
      await prefs.remove(_llmModelKey);
      _logger.i('All enterprise configuration cleared');
      return true;
    } catch (e) {
      _logger.e('Error clearing configuration: $e');
      return false;
    }
  }

  /// Validate API key format
  bool isValidApiKey(String apiKey) {
    return apiKey.isNotEmpty && apiKey.length >= 10 && apiKey.contains('sk-');
  }

  /// Get default free LLM setup instructions
  String getFreeLLMSetupInstructions() {
    return '''
🚀 Get Your FREE Enterprise LLM API Key

1. Visit openrouter.ai
2. Sign up for a free account
3. Go to API Keys section
4. Create a new API key
5. Paste it below to enable enterprise-level SMS analysis

✨ Features you'll unlock:
• Intelligent transaction categorization
• Anomaly detection and alerts
• Smart merchant recognition
• Financial insights and recommendations
• Predictive analytics

The free tier includes 200+ requests which is perfect for personal use!
''';
  }

  /// Get enterprise features list
  List<String> getEnterpriseFeatures() {
    return [
      'AI-Powered Transaction Analysis',
      'Smart Category Detection',
      'Merchant Name Recognition',
      'Anomaly Detection',
      'Financial Health Scoring',
      'Personalized Recommendations',
      'Predictive Insights',
      'Advanced Analytics',
      'Spending Pattern Analysis',
      'Budget Optimization Suggestions',
    ];
  }
}
