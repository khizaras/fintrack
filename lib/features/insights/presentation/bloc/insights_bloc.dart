import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/database/database_helper.dart';

// Events
abstract class InsightsEvent extends Equatable {
  const InsightsEvent();

  @override
  List<Object?> get props => [];
}

class LoadInsights extends InsightsEvent {
  const LoadInsights();
}

class LoadInsightsForPeriod extends InsightsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadInsightsForPeriod({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

// States
abstract class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

class InsightsLoaded extends InsightsState {
  final double totalIncome;
  final double totalExpense;
  final int transactionCount;
  final Map<String, double> categoryData;
  final List<double> monthlyData;
  final List<Map<String, dynamic>> topCategories;

  const InsightsLoaded({
    required this.totalIncome,
    required this.totalExpense,
    required this.transactionCount,
    required this.categoryData,
    required this.monthlyData,
    required this.topCategories,
  });

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpense,
        transactionCount,
        categoryData,
        monthlyData,
        topCategories,
      ];
}

class InsightsError extends InsightsState {
  final String message;

  const InsightsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  InsightsBloc() : super(const InsightsInitial()) {
    on<LoadInsights>(_onLoadInsights);
    on<LoadInsightsForPeriod>(_onLoadInsightsForPeriod);
  }

  Future<void> _onLoadInsights(
    LoadInsights event,
    Emitter<InsightsState> emit,
  ) async {
    try {
      emit(const InsightsLoading());

      // Calculate date range for current month
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      await _loadInsightsData(emit, startDate, endDate);
    } catch (e) {
      emit(InsightsError('Failed to load insights: $e'));
    }
  }

  Future<void> _onLoadInsightsForPeriod(
    LoadInsightsForPeriod event,
    Emitter<InsightsState> emit,
  ) async {
    try {
      emit(const InsightsLoading());
      await _loadInsightsData(emit, event.startDate, event.endDate);
    } catch (e) {
      emit(InsightsError('Failed to load insights: $e'));
    }
  }

  Future<void> _loadInsightsData(
    Emitter<InsightsState> emit,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Get total income
    final incomeResult = await _databaseHelper.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = 'income' AND date >= ? AND date <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final totalIncome =
        (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Get total expense
    final expenseResult = await _databaseHelper.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = 'expense' AND date >= ? AND date <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final totalExpense =
        (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Get transaction count
    final countResult = await _databaseHelper.rawQuery('''
      SELECT COUNT(*) as count
      FROM transactions
      WHERE date >= ? AND date <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final transactionCount = (countResult.first['count'] as int?) ?? 0;

    // Get category breakdown
    final categoryResult = await _databaseHelper.rawQuery('''
      SELECT c.name, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.type = 'expense' AND t.date >= ? AND t.date <= ?
      GROUP BY c.name
      ORDER BY total DESC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final categoryData = <String, double>{};
    for (final row in categoryResult) {
      final amount = (row['total'] as num?)?.toDouble() ?? 0.0;
      // Only add valid amounts (not NaN or infinite)
      if (!amount.isNaN && !amount.isInfinite && amount > 0) {
        categoryData[row['name'] as String] = amount;
      }
    }

    // Get monthly data for the last 12 months
    final monthlyData = await _getMonthlyData();

    // Get top spending categories
    final topCategories = await _getTopCategories();

    emit(InsightsLoaded(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactionCount: transactionCount,
      categoryData: categoryData,
      monthlyData: monthlyData,
      topCategories: topCategories,
    ));
  }

  Future<List<double>> _getMonthlyData() async {
    final now = DateTime.now();
    final monthlyData = <double>[];

    for (int i = 11; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);

      final result = await _databaseHelper.rawQuery('''
        SELECT SUM(amount) as total
        FROM transactions
        WHERE type = 'expense' AND date >= ? AND date <= ?
      ''', [monthStart.toIso8601String(), monthEnd.toIso8601String()]);

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      // Ensure we don't add NaN or infinite values
      monthlyData.add(total.isNaN || total.isInfinite ? 0.0 : total);
    }

    return monthlyData;
  }

  Future<List<Map<String, dynamic>>> _getTopCategories() async {
    final result = await _databaseHelper.rawQuery('''
      SELECT c.name, SUM(t.amount) as amount, COUNT(t.id) as count
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.type = 'expense'
      GROUP BY c.name
      ORDER BY amount DESC
      LIMIT 5
    ''');

    return result
        .map((row) => {
              'name': row['name'] as String,
              'amount': (row['amount'] as num).toDouble(),
              'count': row['count'] as int,
            })
        .toList();
  }
}
