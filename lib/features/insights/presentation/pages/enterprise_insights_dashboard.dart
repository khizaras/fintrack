import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/enterprise_config_service.dart';
import '../../../../core/ai/llm_service.dart';
import '../../../sms/data/services/enhanced_sms_service.dart';
import '../../../settings/presentation/pages/enterprise_settings_page.dart';
import '../bloc/insights_bloc.dart';

/// Enterprise-level insights dashboard with LLM-powered analytics
class EnterpriseInsightsDashboard extends StatefulWidget {
  const EnterpriseInsightsDashboard({Key? key}) : super(key: key);

  @override
  State<EnterpriseInsightsDashboard> createState() =>
      _EnterpriseInsightsDashboardState();
}

class _EnterpriseInsightsDashboardState
    extends State<EnterpriseInsightsDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  LLMInsights? _llmInsights;
  bool _isLoadingInsights = false;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLLMInsights();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLLMInsights() async {
    setState(() => _isLoadingInsights = true);

    try {
      final config = EnterpriseConfigService.instance;
      final apiKey = await config.getOpenRouterApiKey();
      final isEnabled = await config.isLLMEnabled();

      if (apiKey != null && isEnabled) {
        final smsService = EnhancedSmsService(openRouterApiKey: apiKey);
        final insights = await smsService.generateFinancialInsights();

        setState(() {
          _llmInsights = insights;
          _isLoadingInsights = false;
        });
      } else {
        setState(() => _isLoadingInsights = false);
      }
    } catch (e) {
      setState(() => _isLoadingInsights = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load AI insights: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAnalyticsTab(),
                _buildAnomaliesTab(),
                _buildRecommendationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Enterprise Insights',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        IconButton(
          icon:
              Icon(_isLoadingInsights ? Icons.hourglass_empty : Icons.refresh),
          onPressed: _isLoadingInsights ? null : _loadLLMInsights,
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _navigateToSettings(),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[700],
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Analytics'),
          Tab(text: 'Anomalies'),
          Tab(text: 'Recommendations'),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Period: ',
            style:
                TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          DropdownButton<String>(
            value: _selectedPeriod,
            items: ['This Week', 'This Month', 'Last 3 Months', 'This Year']
                .map((period) =>
                    DropdownMenuItem(value: period, child: Text(period)))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedPeriod = value!);
              _loadLLMInsights();
            },
          ),
          const Spacer(),
          if (_llmInsights != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'AI Powered',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFinancialHealthCard(),
          const SizedBox(height: 16),
          _buildSpendingPatternsCard(),
          const SizedBox(height: 16),
          _buildMerchantInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTrendsCard(),
          const SizedBox(height: 16),
          _buildCategoryBreakdownCard(),
          const SizedBox(height: 16),
          _buildPaymentMethodsCard(),
        ],
      ),
    );
  }

  Widget _buildAnomaliesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAnomalyDetectionCard(),
          const SizedBox(height: 16),
          _buildAnomaliesList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBudgetInsightsCard(),
          const SizedBox(height: 16),
          _buildRecommendationsList(),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard() {
    final healthScore = _llmInsights?.financialHealthScore ?? 0.7;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Financial Health Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'AI Analysis',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '${(healthScore * 100).toInt()}/100',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: healthScore,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              _getHealthScoreDescription(healthScore),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingPatternsCard() {
    final patterns = _llmInsights?.spendingPatterns ?? {};
    final primaryCategories = patterns['primary_categories'] as List? ?? [];
    final peakTimes = patterns['peak_spending_times'] as List? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Spending Patterns',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (primaryCategories.isNotEmpty) ...[
              const Text('Top Categories:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: primaryCategories.take(3).map<Widget>((category) {
                  return Chip(
                    label: Text(category.toString()),
                    backgroundColor: Colors.orange[100],
                    labelStyle: TextStyle(color: Colors.orange[700]),
                  );
                }).toList(),
              ),
            ],
            if (peakTimes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Peak Spending Times:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...peakTimes.take(2).map<Widget>((time) {
                return Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(time.toString()),
                  ],
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantInsightsCard() {
    final merchantInsights = _llmInsights?.merchantInsights ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Merchant Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    'Most Frequent',
                    merchantInsights['most_frequent']?.toString() ?? 'N/A',
                    Icons.repeat,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightItem(
                    'Highest Spend',
                    merchantInsights['highest_spend']?.toString() ?? 'N/A',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    'New This Month',
                    merchantInsights['new_merchants_this_month']?.toString() ??
                        '0',
                    Icons.new_releases,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightItem(
                    'Loyalty Score',
                    '${((merchantInsights['merchant_loyalty_score'] ?? 0.0) * 100).toInt()}%',
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsCard() {
    final trends = _llmInsights?.trends ?? {};
    final monthlyGrowth = trends['monthly_growth'] ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.indigo[600]),
                const SizedBox(width: 8),
                const Text(
                  'Spending Trends',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  monthlyGrowth >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: monthlyGrowth >= 0 ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  '${monthlyGrowth.abs().toStringAsFixed(1)}% ${monthlyGrowth >= 0 ? 'increase' : 'decrease'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: monthlyGrowth >= 0 ? Colors.red : Colors.green,
                  ),
                ),
                const Text(' from last month'),
              ],
            ),
            const SizedBox(height: 16),
            if (trends['prediction_next_month'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Predicted next month: ₹${NumberFormat('#,##,###').format(trends['prediction_next_month'])}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
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

  Widget _buildCategoryBreakdownCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Category Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: const Center(
                child: Text('Interactive pie chart would go here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    final patterns = _llmInsights?.spendingPatterns ?? {};
    final paymentMethods = patterns['payment_methods'] as Map? ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.teal[600]),
                const SizedBox(width: 8),
                const Text(
                  'Payment Methods',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...paymentMethods.entries.map<Widget>((entry) {
              final percentage = entry.value / 100.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text('${entry.value}%'),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.teal[400]!),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyDetectionCard() {
    final anomalies = _llmInsights?.anomaliesDetected ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Anomaly Detection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: anomalies.isEmpty
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${anomalies.length} detected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: anomalies.isEmpty
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (anomalies.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    const Text(
                      'No anomalies detected in your recent transactions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              const Text('Anomalies found. Check the list below for details.'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomaliesList() {
    final anomalies = _llmInsights?.anomaliesDetected ?? [];

    if (anomalies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: anomalies.map<Widget>((anomaly) {
          final severity = anomaly['severity'] ?? 'low';
          final color = _getSeverityColor(severity);

          return ListTile(
            leading: Icon(Icons.warning, color: color),
            title: Text(anomaly['description'] ?? 'Unknown anomaly'),
            subtitle: Text(anomaly['recommendation'] ?? ''),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                severity.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBudgetInsightsCard() {
    final budgetInsights = _llmInsights?.budgetInsights ?? {};
    final potentialSavings = budgetInsights['potential_savings'] ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.savings, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Budget Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (potentialSavings > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'Potential Monthly Savings',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${NumberFormat('#,##,###').format(potentialSavings)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
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

  Widget _buildRecommendationsList() {
    final recommendations = _llmInsights?.recommendations ?? [];

    if (recommendations.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.psychology, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No recommendations available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add more transactions for personalized insights',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: recommendations.map<Widget>((recommendation) {
          final priority = recommendation['priority'] ?? 'medium';
          final color = _getPriorityColor(priority);
          final savings = recommendation['potential_savings'] ?? 0.0;

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lightbulb, color: color),
            ),
            title: Text(
              recommendation['title'] ?? 'Recommendation',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recommendation['description'] ?? ''),
                if (savings > 0)
                  Text(
                    'Potential savings: ₹${NumberFormat('#,##,###').format(savings)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                priority.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showLLMConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => const LLMConfigDialog(),
    ).then((_) => _loadLLMInsights());
  }

  String _getHealthScoreDescription(double score) {
    if (score >= 0.8) return 'Excellent financial health! Keep it up.';
    if (score >= 0.6) return 'Good financial habits with room for improvement.';
    if (score >= 0.4)
      return 'Moderate financial health. Consider optimizing spending.';
    return 'Financial health needs attention. Review recommendations.';
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.yellow[700]!;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EnterpriseSettingsPage(),
      ),
    );
  }
}

/// Dialog for configuring LLM settings
class LLMConfigDialog extends StatefulWidget {
  const LLMConfigDialog({Key? key}) : super(key: key);

  @override
  State<LLMConfigDialog> createState() => _LLMConfigDialogState();
}

class _LLMConfigDialogState extends State<LLMConfigDialog> {
  final _apiKeyController = TextEditingController();
  bool _isEnabled = false;
  bool _autoAnalysis = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final config = EnterpriseConfigService.instance;
    final apiKey = await config.getOpenRouterApiKey();
    final enabled = await config.isLLMEnabled();
    final autoAnalysis = await config.isAutoAnalysisEnabled();

    setState(() {
      _apiKeyController.text = apiKey ?? '';
      _isEnabled = enabled;
      _autoAnalysis = autoAnalysis;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'AI Configuration',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'OpenRouter API Key',
                hintText: 'sk-or-...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable LLM Features'),
              subtitle: const Text('Use AI for transaction analysis'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
            SwitchListTile(
              title: const Text('Auto Analysis'),
              subtitle: const Text('Automatically analyze new transactions'),
              value: _autoAnalysis,
              onChanged: (value) => setState(() => _autoAnalysis = value),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get Free API Key:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.blue[700]),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1. Visit openrouter.ai\n2. Sign up for free account\n3. Create API key\n4. Paste above',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final config = EnterpriseConfigService.instance;

      if (_apiKeyController.text.isNotEmpty) {
        await config.setOpenRouterApiKey(_apiKeyController.text);
      }

      await config.setLLMEnabled(_isEnabled);
      await config.setAutoAnalysisEnabled(_autoAnalysis);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
