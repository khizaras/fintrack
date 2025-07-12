import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/enterprise_config_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/ai/llm_service.dart';

/// Enterprise Settings Page for configuring LLM and advanced features
class EnterpriseSettingsPage extends StatefulWidget {
  const EnterpriseSettingsPage({super.key});

  @override
  State<EnterpriseSettingsPage> createState() => _EnterpriseSettingsPageState();
}

class _EnterpriseSettingsPageState extends State<EnterpriseSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();

  bool _isLLMEnabled = false;
  bool _isLoading = true;
  bool _obscureApiKey = true;
  String _selectedModel = 'deepseek/deepseek-r1';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final config = EnterpriseConfigService.instance;

      // Load settings asynchronously
      final isEnabled = await config.isLLMEnabled();
      final apiKey = await config.getOpenRouterApiKey() ?? '';
      final model = await config.getLLMModel();

      if (mounted) {
        setState(() {
          _isLLMEnabled = isEnabled;
          _apiKeyController.text = apiKey;
          _selectedModel = model;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final config = EnterpriseConfigService.instance;

      if (_isLLMEnabled && _apiKeyController.text.isNotEmpty) {
        await config.setOpenRouterApiKey(_apiKeyController.text);
        await config.setLLMModel(_selectedModel);
        await config.setLLMEnabled(true);
      } else {
        await config.setLLMEnabled(false);
        if (!_isLLMEnabled) {
          // Clear API key and model when LLM is disabled
          await config.setOpenRouterApiKey('');
          await config.setLLMModel('deepseek/deepseek-r1'); // Reset to default
        }
      }

      // Wait a bit to ensure SharedPreferences are saved
      await Future.delayed(const Duration(milliseconds: 100));

      // Re-initialize services to apply the new LLM settings
      await _reinitializeServices();

      if (mounted) {
        // Force UI refresh to show updated service status
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLLMEnabled && _apiKeyController.text.isNotEmpty
                ? '✅ LLM features enabled successfully! Ready to analyze transactions.'
                : '✅ Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Re-initialize services to apply new LLM configuration
  Future<void> _reinitializeServices() async {
    try {
      print('🔄 Starting service re-initialization...');
      print('  LLM Enabled: $_isLLMEnabled');
      print('  API Key Present: ${_apiKeyController.text.isNotEmpty}');
      print('  Selected Model: $_selectedModel');

      // Reset the service locator to clear existing services
      await serviceLocator.reset();
      print('🗑️ Service locator reset complete');

      // Re-initialize all services with new configuration
      await initializeServices();
      print('� Services re-initialization complete');

      print(
          '🤖 Enhanced SMS Service Available: $isEnhancedSmsServiceAvailable');
    } catch (e) {
      print('❌ Error re-initializing services: $e');
    }
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _testLLMConnection,
        icon: const Icon(Icons.science),
        label: const Text('Test LLM Connection'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          side: BorderSide(color: AppColors.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _testLLMConnection() async {
    if (!_isLLMEnabled || _apiKeyController.text.isEmpty) {
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Testing LLM connection...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Test SMS for LLM analysis
      const testSms =
          'SBI Account XXX1234 debited for Rs 500.00 on 01-Jan-2025 at SWIGGY payment. Available balance Rs 10000.00';

      // Create LLM service instance for testing
      final llmService = LLMService(
        apiKey: _apiKeyController.text,
        model: _selectedModel,
      );

      final result = await llmService.analyzeSmsTransaction(testSms);

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ LLM test successful!\n'
                'Amount: ₹${result.amount}\n'
                'Category: ${result.category}\n'
                'Confidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ LLM test failed - no response received'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ LLM test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Settings'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildLLMToggleSection(),
                    if (_isLLMEnabled) ...[
                      const SizedBox(height: 24),
                      _buildApiKeySection(),
                      const SizedBox(height: 24),
                      _buildModelSelectionSection(),
                      const SizedBox(height: 24),
                      _buildInstructionsSection(),
                    ],
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    if (_isLLMEnabled && _apiKeyController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildTestButton(),
                    ],
                    const SizedBox(height: 32), // Extra bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primaryColor, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Enterprise AI Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Status indicator with detailed information
              _buildStatusIndicator(),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatusDescription(),
          if (isEnhancedSmsServiceAvailable) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '🤖 AI-powered SMS analysis is currently active and ready to process transactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLLMToggleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'AI-Powered Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isLLMEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isLLMEnabled = value;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Enable LLM-powered SMS analysis for enhanced transaction categorization, merchant identification, and anomaly detection.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'OpenRouter API Key',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                hintText: 'Enter your OpenRouter API key (e.g., sk-or-v1-...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureApiKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (_isLLMEnabled && (value == null || value.isEmpty)) {
                  return 'API key is required when LLM is enabled';
                }
                if (_isLLMEnabled &&
                    value != null &&
                    !value.startsWith('sk-')) {
                  return 'API key should start with "sk-"';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // You can add functionality to open openrouter.ai here if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Visit openrouter.ai to get your API key'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Get your free API key from openrouter.ai. Free tier includes \$5 credit.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_new, color: Colors.blue, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelectionSection() {
    final availableModels =
        EnterpriseConfigService.instance.getAvailableModels();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'AI Model Selection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose the AI model for analyzing your financial SMS messages:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedModel,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              isExpanded: true,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedModel = newValue;
                  });
                }
              },
              items: availableModels.map<DropdownMenuItem<String>>((model) {
                final isRecommended = model['id'] == 'deepseek/deepseek-r1';
                final isFree = model['cost']?.contains('Free') ?? false;

                return DropdownMenuItem<String>(
                  value: model['id'],
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          model['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'REC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates,
                      color: AppColors.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'DeepSeek R1 is recommended for best financial analysis accuracy',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Setup Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
                '1', 'Visit openrouter.ai and create a free account'),
            _buildInstructionStep(
                '2', 'Go to the API Keys section and generate a new key'),
            _buildInstructionStep('3', 'Copy the key and paste it above'),
            _buildInstructionStep('4', 'Save settings and restart the app'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Free tier includes \$5 credit (enough for thousands of SMS analyses)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _saveSettings,
        icon: const Icon(Icons.save),
        label: const Text('Save Settings'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (!_isLLMEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'DISABLED',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (_apiKeyController.text.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'NO API KEY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isEnhancedSmsServiceAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'ACTIVE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'UNAVAILABLE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildStatusDescription() {
    String description;
    Color textColor;

    if (!_isLLMEnabled) {
      description =
          'Enable advanced AI-powered transaction analysis using Large Language Models (LLM) for more accurate categorization, anomaly detection, and financial insights.';
      textColor = Colors.grey;
    } else if (_apiKeyController.text.isEmpty) {
      description =
          '⚠️ Please enter your OpenRouter API key to enable AI features. The app will work normally with basic SMS parsing until configured.';
      textColor = Colors.orange[700]!;
    } else if (isEnhancedSmsServiceAvailable) {
      description =
          '🤖 AI-powered SMS analysis is currently active and ready to process transactions with enhanced accuracy and insights.';
      textColor = Colors.green[700]!;
    } else {
      description =
          '⚠️ AI service is temporarily unavailable (network issue or API quota exceeded). The app continues to work with fallback SMS parsing.';
      textColor = Colors.red[700]!;
    }

    return Text(
      description,
      style: TextStyle(
        fontSize: 14,
        color: textColor,
      ),
    );
  }
}
