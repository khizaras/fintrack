import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/enterprise_config_service.dart';
import '../database/database_helper.dart';
import '../../features/transactions/data/repositories/transaction_repository.dart';
import '../../features/sms/data/services/enhanced_sms_service.dart';
import '../../features/sms/data/services/sms_service.dart';

/// Service locator for dependency injection
final GetIt serviceLocator = GetIt.instance;

/// Initialize all services and dependencies
Future<void> initializeServices() async {
  try {
    // Core services
    serviceLocator.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);

    // Configuration service
    serviceLocator.registerSingleton<EnterpriseConfigService>(
        EnterpriseConfigService.instance);

    // Check if enterprise features are enabled using the config service
    final config = EnterpriseConfigService.instance;
    final isLLMEnabled = await config.isLLMEnabled();
    final apiKey = await config.getOpenRouterApiKey() ?? '';
    final selectedModel = await config.getLLMModel();

    print('🔧 Service Initialization:');
    print('  LLM Enabled: $isLLMEnabled');
    print('  API Key Present: ${apiKey.isNotEmpty}');
    print('  Selected Model: $selectedModel');

    // SMS Service - use enhanced version if LLM is enabled, fallback to regular
    if (isLLMEnabled && apiKey.isNotEmpty) {
      try {
        print('✅ Attempting to register EnhancedSmsService');
        serviceLocator.registerSingleton<EnhancedSmsService>(
          EnhancedSmsService(
            openRouterApiKey: apiKey,
            model: selectedModel,
          ),
        );
        print('✅ EnhancedSmsService registered successfully');
      } catch (e) {
        print('❌ Failed to register EnhancedSmsService: $e');
        print('🔄 Falling back to regular SmsService');
        serviceLocator.registerSingleton<SmsService>(SmsService());
      }
    } else {
      print('ℹ️ Registering regular SmsService');
      serviceLocator.registerSingleton<SmsService>(SmsService());
    }

    // Repository
    serviceLocator
        .registerSingleton<TransactionRepository>(TransactionRepository());

    print('✅ All services initialized successfully');
  } catch (e) {
    print('❌ Critical error during service initialization: $e');

    // Ensure we have basic services even if advanced features fail
    try {
      if (!serviceLocator.isRegistered<SmsService>() &&
          !serviceLocator.isRegistered<EnhancedSmsService>()) {
        print('🔄 Registering fallback SmsService');
        serviceLocator.registerSingleton<SmsService>(SmsService());
      }

      if (!serviceLocator.isRegistered<TransactionRepository>()) {
        print('🔄 Registering fallback TransactionRepository');
        serviceLocator
            .registerSingleton<TransactionRepository>(TransactionRepository());
      }
    } catch (fallbackError) {
      print('❌ Even fallback service registration failed: $fallbackError');
      rethrow;
    }
  }
}

/// Check if enhanced SMS service is available
bool get isEnhancedSmsServiceAvailable =>
    serviceLocator.isRegistered<EnhancedSmsService>();

/// Get the appropriate SMS service (enhanced or regular)
dynamic getSmsService() {
  if (serviceLocator.isRegistered<EnhancedSmsService>()) {
    return serviceLocator<EnhancedSmsService>();
  } else {
    return serviceLocator<SmsService>();
  }
}
