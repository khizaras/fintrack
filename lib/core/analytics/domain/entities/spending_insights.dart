import 'package:equatable/equatable.dart';

/// Comprehensive spending insights data model
class SpendingInsights extends Equatable {
  final double totalExpenses;
  final double totalIncome;
  final double netAmount;
  final double averageDaily;
  final double averageWeekly;
  final double averageMonthly;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> monthlyTrends;
  final SpendingTrend overallTrend;
  final List<String> topCategories;
  final List<String> topMerchants;
  final double comparedToLastMonth;
  final double comparedToLastWeek;
  final List<FinancialRecommendation> recommendations;
  final List<SpendingAnomaly> anomalies;
  final DateTime generatedAt;

  const SpendingInsights({
    required this.totalExpenses,
    required this.totalIncome,
    required this.netAmount,
    required this.averageDaily,
    required this.averageWeekly,
    required this.averageMonthly,
    required this.categoryBreakdown,
    required this.monthlyTrends,
    required this.overallTrend,
    required this.topCategories,
    required this.topMerchants,
    required this.comparedToLastMonth,
    required this.comparedToLastWeek,
    required this.recommendations,
    required this.anomalies,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
        totalExpenses,
        totalIncome,
        netAmount,
        averageDaily,
        averageWeekly,
        averageMonthly,
        categoryBreakdown,
        monthlyTrends,
        overallTrend,
        topCategories,
        topMerchants,
        comparedToLastMonth,
        comparedToLastWeek,
        recommendations,
        anomalies,
        generatedAt,
      ];
}

/// Spending trend enumeration
enum SpendingTrend { increasing, decreasing, stable, unknown }

/// Financial recommendation model
class FinancialRecommendation extends Equatable {
  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final RecommendationPriority priority;
  final double? potentialSavings;
  final String? actionUrl;
  final List<String> categories;
  final DateTime createdAt;
  final bool isActionable;

  const FinancialRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.potentialSavings,
    this.actionUrl,
    required this.categories,
    required this.createdAt,
    required this.isActionable,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        priority,
        potentialSavings,
        actionUrl,
        categories,
        createdAt,
        isActionable,
      ];
}

/// Recommendation type enumeration
enum RecommendationType {
  saving,
  budgeting,
  investment,
  spending,
  cashflow,
  optimization
}

/// Recommendation priority levels
enum RecommendationPriority { critical, high, medium, low }

/// Spending anomaly model
class SpendingAnomaly extends Equatable {
  final String id;
  final AnomalyType type;
  final String description;
  final double severity; // 0.0 to 1.0
  final double amount;
  final String? merchant;
  final String? category;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;

  const SpendingAnomaly({
    required this.id,
    required this.type,
    required this.description,
    required this.severity,
    required this.amount,
    this.merchant,
    this.category,
    required this.detectedAt,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        description,
        severity,
        amount,
        merchant,
        category,
        detectedAt,
        metadata,
      ];
}

/// Anomaly type enumeration
enum AnomalyType {
  unusualAmount,
  unusualFrequency,
  unusualTime,
  unusualMerchant
}
