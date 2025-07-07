import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/transactions/domain/entities/transaction.dart';
import '../analytics/analytics_engine.dart';
import '../analytics/domain/entities/spending_insights.dart';

/// Enterprise Notification and Alert System
/// Provides intelligent, context-aware notifications for financial insights
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AnalyticsEngine _analytics = AnalyticsEngine();

  bool _isInitialized = false;
  StreamSubscription<AnalyticsUpdate>? _analyticsSubscription;
  Timer? _periodicInsightTimer;

  /// Initialize notification service with intelligent routing
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeNotifications();
      await _setupAnalyticsListeners();
      await _schedulePeriodicInsights();

      _isInitialized = true;
      _logger.i('Notification service initialized');
    } catch (e) {
      _logger.e('Failed to initialize notification service: $e');
    }
  }

  /// Process new transaction and generate contextual notifications
  Future<void> processTransaction(Transaction transaction) async {
    if (!_isInitialized) await initialize();

    try {
      // Real-time analysis
      final insights = await _analyzeTransactionContext(transaction);

      // Generate appropriate notifications
      await _generateTransactionNotifications(transaction, insights);

      // Check for spending alerts
      await _checkSpendingThresholds(transaction);

      // Detect and notify about anomalies
      await _checkForAnomalies(transaction);
    } catch (e) {
      _logger.e('Error processing transaction notification: $e');
    }
  }

  /// Send smart budget alerts with actionable insights
  Future<void> sendBudgetAlert({
    required String category,
    required double spent,
    required double budget,
    required double threshold,
  }) async {
    final percentage = (spent / budget) * 100;
    final remaining = budget - spent;

    final notification = SmartNotification(
      id: _generateNotificationId('budget', category),
      title: '💰 Budget Alert: $category',
      body: _getBudgetAlertMessage(percentage, remaining, category),
      type: NotificationType.budgetAlert,
      priority: _getBudgetAlertPriority(percentage),
      actions: [
        NotificationAction('view_spending', 'View Spending'),
        NotificationAction('adjust_budget', 'Adjust Budget'),
      ],
      data: {
        'category': category,
        'spent': spent,
        'budget': budget,
        'percentage': percentage,
      },
    );

    await _sendNotification(notification);
  }

  /// Send anomaly detection alerts with explanations
  Future<void> sendAnomalyAlert(SpendingAnomaly anomaly) async {
    final notification = SmartNotification(
      id: _generateNotificationId('anomaly', anomaly.type.toString()),
      title: '🚨 Unusual Activity Detected',
      body: _getAnomalyMessage(anomaly),
      type: NotificationType.anomalyAlert,
      priority: NotificationPriority.high,
      actions: [
        NotificationAction('review_transaction', 'Review Transaction'),
        NotificationAction('mark_normal', 'Mark as Normal'),
      ],
      data: {
        'anomaly_type': anomaly.type.toString(),
        'severity': anomaly.severity,
        'anomaly_id': anomaly.id,
      },
    );

    await _sendNotification(notification);
  }

  /// Send personalized insights and recommendations
  Future<void> sendPersonalizedInsight(FinancialInsight insight) async {
    final notification = SmartNotification(
      id: _generateNotificationId('insight', insight.category),
      title: '💡 Financial Insight',
      body: insight.message,
      type: NotificationType.insight,
      priority: NotificationPriority.medium,
      actions: [
        NotificationAction('view_details', 'View Details'),
        NotificationAction('take_action', insight.actionText),
      ],
      data: {
        'insight_type': insight.type.toString(),
        'category': insight.category,
        'potential_saving': insight.potentialSaving,
      },
    );

    await _sendNotification(notification);
  }

  /// Send monthly financial summary
  Future<void> sendMonthlySummary(SpendingInsights insights) async {
    final savingsRate = insights.totalIncome > 0
        ? ((insights.totalIncome - insights.totalExpenses) /
                insights.totalIncome) *
            100
        : 0;

    final notification = SmartNotification(
      id: _generateNotificationId('summary', 'monthly'),
      title: '📊 Monthly Financial Summary',
      body:
          'You spent ₹${insights.totalExpenses.toStringAsFixed(0)} this month. '
          'Savings rate: ${savingsRate.toStringAsFixed(1)}%',
      type: NotificationType.summary,
      priority: NotificationPriority.medium,
      actions: [
        NotificationAction('view_report', 'View Full Report'),
        NotificationAction('export_data', 'Export Data'),
      ],
      data: {
        'period': 'monthly',
        'total_spent': insights.totalExpenses,
        'total_income': insights.totalIncome,
        'savings_rate': savingsRate,
      },
    );

    await _sendNotification(notification);
  }

  /// Send goal achievement notifications
  Future<void> sendGoalNotification({
    required String goalName,
    required double progress,
    required double target,
    required GoalType type,
  }) async {
    final percentage = (progress / target) * 100;

    final notification = SmartNotification(
      id: _generateNotificationId('goal', goalName),
      title: _getGoalTitle(type, percentage),
      body: _getGoalMessage(goalName, progress, target, percentage),
      type: NotificationType.goalUpdate,
      priority: percentage >= 100
          ? NotificationPriority.high
          : NotificationPriority.medium,
      actions: [
        NotificationAction('view_goal', 'View Goal'),
        NotificationAction('update_goal', 'Update Goal'),
      ],
      data: {
        'goal_name': goalName,
        'progress': progress,
        'target': target,
        'percentage': percentage,
        'goal_type': type.toString(),
      },
    );

    await _sendNotification(notification);
  }

  /// Send smart spending tips based on AI analysis
  Future<void> sendSpendingTip(SpendingTip tip) async {
    final notification = SmartNotification(
      id: _generateNotificationId('tip', tip.category),
      title: '💡 Smart Spending Tip',
      body: tip.message,
      type: NotificationType.tip,
      priority: NotificationPriority.low,
      actions: [
        NotificationAction('learn_more', 'Learn More'),
        NotificationAction('apply_tip', 'Apply Tip'),
      ],
      data: {
        'tip_category': tip.category,
        'potential_saving': tip.potentialSaving,
        'confidence': tip.confidence,
      },
    );

    await _sendNotification(notification);
  }

  /// Initialize local notifications
  Future<void> _initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Request permissions
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Setup analytics listeners for real-time notifications
  Future<void> _setupAnalyticsListeners() async {
    _analyticsSubscription = _analytics.analyticsStream.listen((update) {
      switch (update.type) {
        case AnalyticsUpdateType.anomalyDetected:
          final anomaly = update.data as SpendingAnomaly;
          sendAnomalyAlert(anomaly);
          break;
        case AnalyticsUpdateType.budgetAlert:
          final budgetData = update.data as Map<String, dynamic>;
          sendBudgetAlert(
            category: budgetData['category'],
            spent: budgetData['spent'],
            budget: budgetData['budget'],
            threshold: budgetData['threshold'],
          );
          break;
        case AnalyticsUpdateType.patternRecognized:
          final patterns = update.data as List<String>;
          _handlePatternRecognition(patterns);
          break;
        case AnalyticsUpdateType.predictionUpdate:
          final prediction = update.data as Map<String, dynamic>;
          _handlePredictionUpdate(prediction);
          break;
      }
    });
  }

  /// Schedule periodic financial insights
  Future<void> _schedulePeriodicInsights() async {
    _periodicInsightTimer = Timer.periodic(
      const Duration(hours: 24),
      (timer) => _generateDailyInsights(),
    );
  }

  /// Analyze transaction context for smart notifications
  Future<TransactionContext> _analyzeTransactionContext(
      Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();

    // Get user's spending patterns
    final avgSpending =
        prefs.getDouble('avg_spending_${transaction.category}') ?? 0;
    final lastSimilarTransaction =
        prefs.getString('last_${transaction.category}');

    // Analyze transaction timing
    final isWeekend = transaction.date.weekday > 5;
    final isLateNight = transaction.date.hour > 22 || transaction.date.hour < 6;
    final isBusinessHours =
        transaction.date.hour >= 9 && transaction.date.hour <= 17;

    return TransactionContext(
      transaction: transaction,
      isAboveAverage: transaction.amount > avgSpending * 1.5,
      isUnusualTime: isLateNight,
      isWeekendSpending: isWeekend,
      isBusinessHours: isBusinessHours,
      daysSinceLastSimilar:
          _calculateDaysSinceLastSimilar(lastSimilarTransaction),
    );
  }

  /// Generate contextual transaction notifications
  Future<void> _generateTransactionNotifications(
    Transaction transaction,
    TransactionContext context,
  ) async {
    // Large transaction alert
    if (context.isAboveAverage && transaction.amount > 5000) {
      await _sendLargeTransactionAlert(transaction);
    }

    // Unusual time alert
    if (context.isUnusualTime) {
      await _sendUnusualTimeAlert(transaction);
    }

    // Weekend spending pattern
    if (context.isWeekendSpending &&
        transaction.type == TransactionType.expense) {
      await _sendWeekendSpendingNotification(transaction);
    }

    // Frequent spending alert
    if (context.daysSinceLastSimilar != null &&
        context.daysSinceLastSimilar! < 1) {
      await _sendFrequentSpendingAlert(transaction);
    }
  }

  /// Check spending thresholds and budgets
  Future<void> _checkSpendingThresholds(Transaction transaction) async {
    if (transaction.type != TransactionType.expense) return;

    final prefs = await SharedPreferences.getInstance();
    final categoryBudget =
        prefs.getDouble('budget_${transaction.category}') ?? 0;
    final categorySpent = prefs.getDouble('spent_${transaction.category}') ?? 0;

    if (categoryBudget > 0) {
      final newSpent = categorySpent + transaction.amount;
      final percentage = (newSpent / categoryBudget) * 100;

      // Save updated spending
      await prefs.setDouble('spent_${transaction.category}', newSpent);

      // Check thresholds
      if (percentage >= 90 && categorySpent / categoryBudget < 0.9) {
        await sendBudgetAlert(
          category: transaction.category ?? 'General',
          spent: newSpent,
          budget: categoryBudget,
          threshold: 0.9,
        );
      } else if (percentage >= 75 && categorySpent / categoryBudget < 0.75) {
        await sendBudgetAlert(
          category: transaction.category ?? 'General',
          spent: newSpent,
          budget: categoryBudget,
          threshold: 0.75,
        );
      }
    }
  }

  /// Check for transaction anomalies
  Future<void> _checkForAnomalies(Transaction transaction) async {
    // Implement real-time anomaly detection
    final isAnomaly = await _isTransactionAnomalous(transaction);

    if (isAnomaly) {
      final anomaly = SpendingAnomaly(
        id: 'anomaly_${transaction.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: AnomalyType.unusualAmount,
        severity: await _calculateAnomalyScore(transaction),
        amount: transaction.amount,
        merchant: transaction.description, // Using description as merchant
        category: transaction.category,
        detectedAt: DateTime.now(),
        metadata: {'transaction_id': transaction.id.toString()},
        description:
            'This transaction is significantly different from your usual spending pattern',
      );

      await sendAnomalyAlert(anomaly);
    }
  }

  /// Generate daily financial insights
  Future<void> _generateDailyInsights() async {
    try {
      final insights = await _analytics.generateSpendingInsights(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      // Generate personalized insights
      final personalizedInsights =
          await _generatePersonalizedInsights(insights);

      for (final insight in personalizedInsights) {
        await sendPersonalizedInsight(insight);
      }
    } catch (e) {
      _logger.e('Failed to generate daily insights: $e');
    }
  }

  /// Generate personalized financial insights
  Future<List<FinancialInsight>> _generatePersonalizedInsights(
    SpendingInsights insights,
  ) async {
    final personalizedInsights = <FinancialInsight>[];

    // Spending pattern insights
    // Note: spendingPatterns not yet implemented in SpendingInsights model
    // if (insights.spendingPatterns.timePatterns.peakSpendingHour > 20) {
    //   personalizedInsights.add(FinancialInsight(
    //     type: InsightType.spendingPattern,
    //     category: 'Evening Spending',
    //     message:
    //         'You tend to spend more in the evening. Consider setting a daily spending limit.',
    //     actionText: 'Set Limit',
    //     potentialSaving: 2000,
    //     confidence: 0.8,
    //   ));
    // }

    // Category-specific insights
    for (final category in insights.categoryBreakdown.entries) {
      if (category.value > _getCategoryThreshold(category.key)) {
        personalizedInsights.add(FinancialInsight(
          type: InsightType.categoryAlert,
          category: category.key,
          message:
              'Your ${category.key} spending is above average. Consider reviewing expenses.',
          actionText: 'Review Expenses',
          potentialSaving: category.value * 0.15,
          confidence: 0.75,
        ));
      }
    }

    // Recommendation insights
    for (final recommendation in insights.recommendations.take(2)) {
      personalizedInsights.add(FinancialInsight(
        type: InsightType.recommendation,
        category: 'Optimization',
        message: recommendation.description,
        actionText: 'Apply Suggestion',
        potentialSaving: recommendation.potentialSavings ?? 0.0,
        confidence: 0.85,
      ));
    }

    return personalizedInsights;
  }

  /// Send notification with smart formatting
  Future<void> _sendNotification(SmartNotification notification) async {
    final androidDetails = AndroidNotificationDetails(
      'fintrack_${notification.type.toString()}',
      _getChannelName(notification.type),
      channelDescription: _getChannelDescription(notification.type),
      importance: _getImportance(notification.priority),
      priority: _getPriority(notification.priority),
      actions: notification.actions
          ?.map((action) => AndroidNotificationAction(
                action.id,
                action.label,
              ))
          .toList(),
      styleInformation: _getNotificationStyle(notification),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notification.id,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(notification.data),
    );

    // Log notification for analytics
    _logger.i('Sent notification: ${notification.title}');
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    _logger.i('Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _routeToRelevantScreen(data, response.actionId);
      } catch (e) {
        _logger.e('Failed to parse notification payload: $e');
      }
    }
  }

  /// Route to relevant screen based on notification data
  void _routeToRelevantScreen(Map<String, dynamic> data, String? actionId) {
    // Implement navigation logic based on notification type and action
    switch (actionId) {
      case 'view_spending':
        // Navigate to spending analysis
        break;
      case 'view_goal':
        // Navigate to goals screen
        break;
      case 'review_transaction':
        // Navigate to transaction details
        break;
      case 'view_report':
        // Navigate to insights dashboard
        break;
      default:
        // Navigate to main dashboard
        break;
    }
  }

  // Helper methods for notification content generation
  String _getBudgetAlertMessage(
      double percentage, double remaining, String category) {
    if (percentage >= 100) {
      return 'You\'ve exceeded your $category budget by ₹${(-remaining).toStringAsFixed(0)}!';
    } else if (percentage >= 90) {
      return 'You\'ve used ${percentage.toStringAsFixed(0)}% of your $category budget. ₹${remaining.toStringAsFixed(0)} remaining.';
    } else {
      return 'You\'ve used ${percentage.toStringAsFixed(0)}% of your $category budget.';
    }
  }

  String _getAnomalyMessage(SpendingAnomaly anomaly) {
    switch (anomaly.type) {
      case AnomalyType.unusualAmount:
        return 'Transaction of ₹${anomaly.amount.toStringAsFixed(0)} is unusually high for ${anomaly.category ?? 'this category'}';
      case AnomalyType.unusualFrequency:
        return 'Frequent transactions detected in ${anomaly.category ?? 'this category'}';
      case AnomalyType.unusualTime:
        return 'Transaction at unusual time: ${anomaly.detectedAt.hour}:${anomaly.detectedAt.minute.toString().padLeft(2, '0')}';
      case AnomalyType.unusualMerchant:
        return 'New merchant detected: ${anomaly.merchant ?? 'Unknown'}';
    }
  }

  String _getGoalTitle(GoalType type, double percentage) {
    switch (type) {
      case GoalType.savings:
        if (percentage >= 100) return '🎉 Savings Goal Achieved!';
        if (percentage >= 75) return '💪 Almost There! Savings Goal';
        return '📈 Savings Goal Progress';
      case GoalType.budget:
        if (percentage >= 100) return '⚠️ Budget Goal Exceeded';
        if (percentage >= 90) return '🚨 Budget Goal Alert';
        return '💰 Budget Goal Update';
      case GoalType.investment:
        if (percentage >= 100) return '🚀 Investment Goal Achieved!';
        return '📊 Investment Goal Progress';
    }
  }

  String _getGoalMessage(
      String goalName, double progress, double target, double percentage) {
    return '$goalName: ₹${progress.toStringAsFixed(0)} / ₹${target.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)';
  }

  NotificationPriority _getBudgetAlertPriority(double percentage) {
    if (percentage >= 100) return NotificationPriority.critical;
    if (percentage >= 90) return NotificationPriority.high;
    if (percentage >= 75) return NotificationPriority.medium;
    return NotificationPriority.low;
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.budgetAlert:
        return 'Budget Alerts';
      case NotificationType.anomalyAlert:
        return 'Anomaly Detection';
      case NotificationType.insight:
        return 'Financial Insights';
      case NotificationType.summary:
        return 'Financial Summaries';
      case NotificationType.goalUpdate:
        return 'Goal Updates';
      case NotificationType.tip:
        return 'Spending Tips';
    }
  }

  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.budgetAlert:
        return 'Notifications about budget thresholds and spending limits';
      case NotificationType.anomalyAlert:
        return 'Alerts for unusual spending patterns and transactions';
      case NotificationType.insight:
        return 'Personalized financial insights and recommendations';
      case NotificationType.summary:
        return 'Periodic financial summaries and reports';
      case NotificationType.goalUpdate:
        return 'Updates on financial goals and milestones';
      case NotificationType.tip:
        return 'Smart spending tips and financial advice';
    }
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return Priority.max;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  StyleInformation? _getNotificationStyle(SmartNotification notification) {
    if (notification.type == NotificationType.summary) {
      return const BigTextStyleInformation('');
    }
    return null;
  }

  int _generateNotificationId(String prefix, String suffix) {
    return '${prefix}_$suffix'.hashCode;
  }

  double _getCategoryThreshold(String category) {
    // Return average spending thresholds for different categories
    const thresholds = {
      'Food & Dining': 8000.0,
      'Transport': 3000.0,
      'Shopping': 5000.0,
      'Entertainment': 2000.0,
      'Utilities': 3500.0,
    };
    return thresholds[category] ?? 2000.0;
  }

  int? _calculateDaysSinceLastSimilar(String? lastTransactionDate) {
    if (lastTransactionDate == null) return null;

    try {
      final lastDate = DateTime.parse(lastTransactionDate);
      return DateTime.now().difference(lastDate).inDays;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _isTransactionAnomalous(Transaction transaction) async {
    // Simplified anomaly detection - in production, use ML models
    final prefs = await SharedPreferences.getInstance();
    final avgAmount =
        prefs.getDouble('avg_amount_${transaction.category}') ?? 1000;

    return transaction.amount > avgAmount * 3;
  }

  Future<double> _calculateAnomalyScore(Transaction transaction) async {
    // Simplified scoring - in production, use comprehensive ML scoring
    final prefs = await SharedPreferences.getInstance();
    final avgAmount =
        prefs.getDouble('avg_amount_${transaction.category}') ?? 1000;

    return transaction.amount / avgAmount;
  }

  // Placeholder notification methods
  Future<void> _sendLargeTransactionAlert(Transaction transaction) async {
    await _sendNotification(SmartNotification(
      id: _generateNotificationId(
          'large_transaction', transaction.id?.toString() ?? ''),
      title: '💰 Large Transaction Detected',
      body:
          'Transaction of ₹${transaction.amount.toStringAsFixed(0)} in ${transaction.category}',
      type: NotificationType.anomalyAlert,
      priority: NotificationPriority.high,
      data: {'transaction_id': transaction.id},
    ));
  }

  Future<void> _sendUnusualTimeAlert(Transaction transaction) async {
    await _sendNotification(SmartNotification(
      id: _generateNotificationId(
          'unusual_time', transaction.id?.toString() ?? ''),
      title: '🕐 Late Night Transaction',
      body:
          'Transaction at ${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}',
      type: NotificationType.insight,
      priority: NotificationPriority.medium,
      data: {'transaction_id': transaction.id},
    ));
  }

  Future<void> _sendWeekendSpendingNotification(Transaction transaction) async {
    await _sendNotification(SmartNotification(
      id: _generateNotificationId(
          'weekend_spending', transaction.category ?? ''),
      title: '📅 Weekend Spending',
      body:
          'Spending ₹${transaction.amount.toStringAsFixed(0)} on ${transaction.category}',
      type: NotificationType.insight,
      priority: NotificationPriority.low,
      data: {'category': transaction.category},
    ));
  }

  Future<void> _sendFrequentSpendingAlert(Transaction transaction) async {
    await _sendNotification(SmartNotification(
      id: _generateNotificationId(
          'frequent_spending', transaction.category ?? ''),
      title: '🔁 Frequent Spending Alert',
      body: 'Multiple transactions in ${transaction.category} today',
      type: NotificationType.budgetAlert,
      priority: NotificationPriority.medium,
      data: {'category': transaction.category},
    ));
  }

  void _handlePatternRecognition(List<String> patterns) {
    // Handle recognized spending patterns
    _logger.i('Patterns recognized: $patterns');
  }

  void _handlePredictionUpdate(Map<String, dynamic> prediction) {
    // Handle prediction updates
    _logger.i('Prediction update: $prediction');
  }

  void dispose() {
    _analyticsSubscription?.cancel();
    _periodicInsightTimer?.cancel();
  }
}

// Data classes for notification system

class SmartNotification {
  final int id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final List<NotificationAction>? actions;
  final Map<String, dynamic> data;

  SmartNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.actions,
    this.data = const {},
  });
}

class NotificationAction {
  final String id;
  final String label;

  NotificationAction(this.id, this.label);
}

class TransactionContext {
  final Transaction transaction;
  final bool isAboveAverage;
  final bool isUnusualTime;
  final bool isWeekendSpending;
  final bool isBusinessHours;
  final int? daysSinceLastSimilar;

  TransactionContext({
    required this.transaction,
    required this.isAboveAverage,
    required this.isUnusualTime,
    required this.isWeekendSpending,
    required this.isBusinessHours,
    this.daysSinceLastSimilar,
  });
}

class FinancialInsight {
  final InsightType type;
  final String category;
  final String message;
  final String actionText;
  final double potentialSaving;
  final double confidence;

  FinancialInsight({
    required this.type,
    required this.category,
    required this.message,
    required this.actionText,
    required this.potentialSaving,
    required this.confidence,
  });
}

class SpendingTip {
  final String category;
  final String message;
  final double potentialSaving;
  final double confidence;

  SpendingTip({
    required this.category,
    required this.message,
    required this.potentialSaving,
    required this.confidence,
  });
}

// Enums
enum NotificationType {
  budgetAlert,
  anomalyAlert,
  insight,
  summary,
  goalUpdate,
  tip,
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

enum InsightType {
  spendingPattern,
  categoryAlert,
  recommendation,
  prediction,
}

enum GoalType {
  savings,
  budget,
  investment,
}
