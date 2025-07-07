import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/database/database_helper.dart';
import 'features/transactions/data/repositories/transaction_repository.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';
import 'features/sms/data/services/sms_service.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database, SMS patterns, and real data
  await _initializeApp();

  runApp(const FinTrackApp());
}

Future<void> _initializeApp() async {
  try {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database; // Initialize database
    await _initializeSmsPatterns();

    // Initialize SMS service and read real transactions
    await _initializeRealData();
  } catch (e) {
    // Database not available (e.g., on web), continue with demo mode
    print('Database initialization skipped: $e');
  }
}

Future<void> _initializeRealData() async {
  try {
    final smsService = SmsService();

    // Check if we have SMS permissions
    final hasPermission = await smsService.checkSmsPermissions();

    if (hasPermission) {
      print('📱 Reading SMS messages for transaction extraction...');
      // Read SMS messages and extract transactions
      final transactions = await smsService.readAllSmsTransactions();
      print('✅ Extracted ${transactions.length} transactions from SMS');
    } else {
      print('⚠️ SMS permission not granted. Will show demo data in analytics.');
    }
  } catch (e) {
    print('⚠️ SMS reading failed: $e. Will show demo data in analytics.');
  }
}

Future<void> _initializeSmsPatterns() async {
  final dbHelper = DatabaseHelper.instance;

  // Check if patterns already exist
  final existingPatterns = await dbHelper.query('sms_patterns');
  if (existingPatterns.isNotEmpty) return;

  // Add default SMS patterns for common banks
  final defaultPatterns = [
    {
      'bank_name': 'SBI',
      'sender_pattern': r'SBI|SBIINB',
      'amount_pattern': r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      'account_pattern': r'A/c\s*[X*]+(\d{4})',
      'description_pattern': r'at\s+([^.]+)',
      'transaction_type_keywords': 'debited,credited,withdrawn,deposited',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'bank_name': 'HDFC',
      'sender_pattern': r'HDFC|HDFCBK',
      'amount_pattern': r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      'account_pattern': r'A/C\s*[X*]+(\d{4})',
      'description_pattern': r'at\s+([^.]+)',
      'transaction_type_keywords': 'debited,credited,withdrawn,deposited',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'bank_name': 'ICICI',
      'sender_pattern': r'ICICI|ICICIB',
      'amount_pattern': r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      'account_pattern': r'A/C\s*[X*]+(\d{4})',
      'description_pattern': r'at\s+([^.]+)',
      'transaction_type_keywords': 'debited,credited,withdrawn,deposited',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'bank_name': 'AXIS',
      'sender_pattern': r'AXIS|AXISBK',
      'amount_pattern': r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      'account_pattern': r'A/C\s*[X*]+(\d{4})',
      'description_pattern': r'at\s+([^.]+)',
      'transaction_type_keywords': 'debited,credited,withdrawn,deposited',
      'created_at': DateTime.now().toIso8601String(),
    },
  ];

  for (final pattern in defaultPatterns) {
    await dbHelper.insert('sms_patterns', pattern);
  }
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionBloc>(
          create: (context) => TransactionBloc(
            transactionRepository: TransactionRepository(),
            smsService: SmsService(),
          )..add(const LoadTransactions()),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primaryColor,
          scaffoldBackgroundColor: AppColors.backgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const SplashPage(),
      ),
    );
  }
}
