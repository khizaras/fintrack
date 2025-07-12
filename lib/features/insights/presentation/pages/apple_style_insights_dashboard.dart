import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/analytics/analytics_engine.dart';
import '../../../../core/analytics/domain/entities/spending_insights.dart';
import '../../../transactions/domain/entities/transaction.dart';

/// Apple Wallet-style Insights Dashboard with detailed analytics
class AppleStyleInsightsDashboard extends StatefulWidget {
  const AppleStyleInsightsDashboard({Key? key}) : super(key: key);

  @override
  State<AppleStyleInsightsDashboard> createState() =>
      _AppleStyleInsightsDashboardState();
}

class _AppleStyleInsightsDashboardState
    extends State<AppleStyleInsightsDashboard>
    with SingleTickerProviderStateMixin {
  final AnalyticsEngine _analytics = AnalyticsEngine();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  SpendingInsights? _insights;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isUsingRealData = false;
  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last 3 Months',
    'This Year'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadInsights();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    try {
      final insights = await _analytics.generateSpendingInsights();
      final transactions =
          await _analytics.getTransactionsFromDatabase(null, null);

      _isUsingRealData = transactions.isNotEmpty;

      setState(() {
        _insights = insights;
        _transactions = transactions;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    _buildPeriodSelector(),
                    _buildSummaryCards(),
                    _buildSpendingBreakdown(),
                    _buildTrendAnalysis(),
                    _buildPaymentMethodAnalysis(),
                    _buildBankAnalysis(),
                    _buildAccountAnalysis(),
                    _buildMerchantAnalysis(),
                    _buildLLMInsightsSection(),
                    _buildTransactionInsights(),
                    _buildAnomaliesSection(),
                    _buildRecommendations(),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: const Color(0xFFF2F2F7),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            'AI-powered financial analysis',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF007AFF)),
            onPressed: _loadInsights,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _periods.length,
          itemBuilder: (context, index) {
            final period = _periods[index];
            final isSelected = _selectedPeriod == period;

            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF007AFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                  _loadInsights();
                },
                selectedColor: const Color(0xFF007AFF),
                backgroundColor: Colors.white,
                elevation: isSelected ? 4 : 1,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_insights == null) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main balance card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Worth',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'AI Analyzed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${_formatCurrency(_insights!.netAmount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Income',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              '₹${_formatCurrency(_insights!.totalIncome)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expenses',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              '₹${_formatCurrency(_insights!.totalExpenses)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Quick stats grid
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    'Daily Avg',
                    '₹${_formatCurrency(_insights!.averageDaily)}',
                    Icons.today,
                    const Color(0xFF34C759),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatCard(
                    'Weekly Avg',
                    '₹${_formatCurrency(_insights!.averageWeekly)}',
                    Icons.calendar_view_week,
                    const Color(0xFFFF9500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    'Transactions',
                    '${_transactions.length}',
                    Icons.receipt_long,
                    const Color(0xFF5856D6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatCard(
                    'Categories',
                    '${_insights!.categoryBreakdown.length}',
                    Icons.category,
                    const Color(0xFFFF2D92),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingBreakdown() {
    if (_insights == null || _insights!.categoryBreakdown.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spending Breakdown',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'AI Categorized',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: _buildPieChartSections(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...(_insights!.categoryBreakdown.entries.take(5).map((entry) {
              final percentage = (entry.value / _insights!.totalExpenses * 100);
              return _buildCategoryItem(entry.key, entry.value, percentage);
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, double percentage) {
    final color = _getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatCurrency(amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    if (_insights == null) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spending Trends',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'Time Analysis',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_insights!.monthlyTrends.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _buildTrendSpots(),
                        isCurved: true,
                        color: const Color(0xFF007AFF),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF007AFF).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTrendSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSummary() {
    final trendIcon = _insights!.comparedToLastMonth >= 0
        ? Icons.trending_up
        : Icons.trending_down;
    final trendColor = _insights!.comparedToLastMonth >= 0
        ? const Color(0xFFFF3B30)
        : const Color(0xFF34C759);
    final trendText =
        _insights!.comparedToLastMonth >= 0 ? 'increased' : 'decreased';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(trendIcon, color: trendColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your spending has $trendText by ${_insights!.comparedToLastMonth.abs().toStringAsFixed(1)}% compared to last month',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodAnalysis() {
    // Analyze payment methods from transactions
    final paymentMethods = <String, double>{};
    double totalAmount = 0;

    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.expense) {
        final method = transaction.bankName ?? 'Unknown Bank';
        paymentMethods[method] =
            (paymentMethods[method] ?? 0) + transaction.amount;
        totalAmount += transaction.amount;
      }
    }

    if (paymentMethods.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ...paymentMethods.entries.take(5).map((entry) {
              final percentage =
                  totalAmount > 0 ? (entry.value / totalAmount * 100) : 0;
              return _buildPaymentMethodItem(
                  entry.key, entry.value.toDouble(), percentage.toDouble());
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(
      String method, double amount, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Color(0xFF007AFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}% of total spending',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${_formatCurrency(amount)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAnalysis() {
    // Analyze bank distribution from transactions
    final bankDistribution = <String, double>{};
    final bankTransactionCount = <String, int>{};

    for (final transaction in _transactions) {
      final bank = transaction.bankName ?? 'Unknown Bank';
      bankDistribution[bank] =
          (bankDistribution[bank] ?? 0) + transaction.amount;
      bankTransactionCount[bank] = (bankTransactionCount[bank] ?? 0) + 1;
    }

    if (bankDistribution.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox());

    // Sort banks by transaction volume
    final sortedBanks = bankDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bank Analysis',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'SMS Extracted',
                    style: TextStyle(
                      color: Color(0xFF34C759),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...sortedBanks.take(5).map((entry) {
              final bank = entry.key;
              final amount = entry.value;
              final transactionCount = bankTransactionCount[bank] ?? 0;
              final percentage = _insights!.totalExpenses > 0
                  ? (amount / _insights!.totalExpenses * 100)
                  : 0;

              return _buildBankItem(
                  bank, amount, transactionCount, percentage.toDouble());
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBankItem(
      String bank, double amount, int transactionCount, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Color(0xFF007AFF),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$transactionCount transactions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatCurrency(amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountAnalysis() {
    // Analyze account usage patterns
    final accountDistribution = <String, double>{};
    final accountTransactionCount = <String, int>{};

    for (final transaction in _transactions) {
      final account = transaction.accountNumber ?? 'Unknown Account';
      // Mask account number for privacy
      final maskedAccount = account.length > 4
          ? '****${account.substring(account.length - 4)}'
          : account;

      accountDistribution[maskedAccount] =
          (accountDistribution[maskedAccount] ?? 0) + transaction.amount;
      accountTransactionCount[maskedAccount] =
          (accountTransactionCount[maskedAccount] ?? 0) + 1;
    }

    if (accountDistribution.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox());

    // Sort accounts by transaction volume
    final sortedAccounts = accountDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Account Usage',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'Privacy Protected',
                    style: TextStyle(
                      color: Color(0xFFFF9500),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...sortedAccounts.take(3).map((entry) {
              final account = entry.key;
              final amount = entry.value;
              final transactionCount = accountTransactionCount[account] ?? 0;
              final percentage = _insights!.totalExpenses > 0
                  ? (amount / _insights!.totalExpenses * 100)
                  : 0;

              return _buildAccountItem(
                  account, amount, transactionCount, percentage.toDouble());
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountItem(
      String account, double amount, int transactionCount, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.credit_card,
              color: Color(0xFFFF9500),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$transactionCount transactions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatCurrency(amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInsights() {
    // Calculate advanced transaction insights
    final Map<String, dynamic> insights = {
      'totalTransactions': _transactions.length,
      'avgTransactionAmount': _transactions.isNotEmpty
          ? _insights!.totalExpenses / _transactions.length
          : 0,
      'largestTransaction': _transactions.isNotEmpty
          ? _transactions.map((t) => t.amount).reduce((a, b) => a > b ? a : b)
          : 0,
      'smallestTransaction': _transactions.isNotEmpty
          ? _transactions.map((t) => t.amount).reduce((a, b) => a < b ? a : b)
          : 0,
      'uniqueMerchants':
          _transactions.map((t) => t.merchantName ?? 'Unknown').toSet().length,
      'uniqueBanks':
          _transactions.map((t) => t.bankName ?? 'Unknown').toSet().length,
      'weekdayTransactions':
          _transactions.where((t) => t.date.weekday <= 5).length,
      'weekendTransactions':
          _transactions.where((t) => t.date.weekday > 5).length,
    };

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Insights',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            // Insights grid
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    'Avg Amount',
                    '₹${_formatCurrency(insights['avgTransactionAmount'])}',
                    Icons.analytics,
                    const Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    'Largest',
                    '₹${_formatCurrency(insights['largestTransaction'])}',
                    Icons.trending_up,
                    const Color(0xFF34C759),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    'Merchants',
                    '${insights['uniqueMerchants']}',
                    Icons.store,
                    const Color(0xFFFF9500),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    'Banks',
                    '${insights['uniqueBanks']}',
                    Icons.account_balance,
                    const Color(0xFF5856D6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Weekday vs Weekend analysis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending Patterns',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF007AFF),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Weekdays: ${insights['weekdayTransactions']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF9500),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Weekends: ${insights['weekendTransactions']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Icon(Icons.info_outline, color: color.withOpacity(0.6), size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantAnalysis() {
    if (_insights == null || _insights!.topMerchants.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    // Calculate merchant spending with transaction count
    final merchantData = <String, Map<String, dynamic>>{};

    for (final transaction in _transactions) {
      final merchant = transaction.merchantName ?? 'Unknown Merchant';
      if (merchantData.containsKey(merchant)) {
        merchantData[merchant]!['amount'] += transaction.amount;
        merchantData[merchant]!['count'] += 1;
      } else {
        merchantData[merchant] = {
          'amount': transaction.amount,
          'count': 1,
        };
      }
    }

    // Sort by amount spent
    final sortedMerchants = merchantData.entries.toList()
      ..sort((a, b) => b.value['amount'].compareTo(a.value['amount']));

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Merchants',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5856D6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'Smart Detected',
                    style: TextStyle(
                      color: Color(0xFF5856D6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...sortedMerchants.take(5).map((entry) {
              final merchant = entry.key;
              final amount = entry.value['amount'];
              final count = entry.value['count'];
              final percentage = _insights!.totalExpenses > 0
                  ? (amount / _insights!.totalExpenses * 100)
                  : 0;

              return _buildMerchantItem(merchant, amount, count, percentage);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantItem(
      String merchant, double amount, int count, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF5856D6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getMerchantIcon(merchant),
              color: const Color(0xFF5856D6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$count transactions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatCurrency(amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesSection() {
    if (_insights == null || _insights!.anomalies.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spending Anomalies',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D92).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'AI Detected',
                    style: TextStyle(
                      color: Color(0xFFFF2D92),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...(_insights!.anomalies.map((anomaly) {
              return _buildAnomalyItem(anomaly);
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyItem(SpendingAnomaly anomaly) {
    Color anomalyColor = const Color(0xFFFF2D92);
    IconData anomalyIcon = Icons.warning;

    switch (anomaly.type) {
      case AnomalyType.unusualAmount:
        anomalyColor = const Color(0xFFFF9500);
        anomalyIcon = Icons.trending_up;
        break;
      case AnomalyType.unusualFrequency:
        anomalyColor = const Color(0xFF5856D6);
        anomalyIcon = Icons.repeat;
        break;
      case AnomalyType.unusualMerchant:
        anomalyColor = const Color(0xFF34C759);
        anomalyIcon = Icons.new_label;
        break;
      case AnomalyType.unusualTime:
        anomalyColor = const Color(0xFF007AFF);
        anomalyIcon = Icons.schedule;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: anomalyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: anomalyColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: anomalyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              anomalyIcon,
              color: anomalyColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anomaly.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_formatCurrency(anomaly.amount)} detected',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: anomalyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${(anomaly.severity * 100).toInt()}%',
              style: TextStyle(
                color: anomalyColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_insights == null || _insights!.recommendations.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Smart Recommendations',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'AI Powered',
                    style: TextStyle(
                      color: Color(0xFF34C759),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...(_insights!.recommendations.map((recommendation) {
              return _buildRecommendationItem(recommendation);
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(FinancialRecommendation recommendation) {
    Color recommendationColor = const Color(0xFF34C759);
    IconData recommendationIcon = Icons.lightbulb;

    switch (recommendation.type) {
      case RecommendationType.budgeting:
        recommendationColor = const Color(0xFF007AFF);
        recommendationIcon = Icons.pie_chart;
        break;
      case RecommendationType.spending:
        recommendationColor = const Color(0xFFFF9500);
        recommendationIcon = Icons.trending_down;
        break;
      case RecommendationType.investment:
        recommendationColor = const Color(0xFF5856D6);
        recommendationIcon = Icons.swap_horiz;
        break;
      case RecommendationType.saving:
        recommendationColor = const Color(0xFF34C759);
        recommendationIcon = Icons.savings;
        break;
      case RecommendationType.optimization:
        recommendationColor = const Color(0xFF007AFF);
        recommendationIcon = Icons.auto_graph;
        break;
      case RecommendationType.cashflow:
        recommendationColor = const Color(0xFFFF2D92);
        recommendationIcon = Icons.account_balance;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommendationColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: recommendationColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: recommendationColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              recommendationIcon,
              color: recommendationColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (recommendation.potentialSavings != null &&
              recommendation.potentialSavings! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: recommendationColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Save ₹${_formatCurrency(recommendation.potentialSavings!)}',
                style: TextStyle(
                  color: recommendationColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  List<PieChartSectionData> _buildPieChartSections() {
    final sections = <PieChartSectionData>[];
    final colors = [
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFFF2D92),
      const Color(0xFF5856D6),
    ];

    int index = 0;
    for (final entry in _insights!.categoryBreakdown.entries.take(5)) {
      final percentage = entry.value / _insights!.totalExpenses * 100;
      sections.add(
        PieChartSectionData(
          color: colors[index % colors.length],
          value: percentage,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    }

    return sections;
  }

  List<FlSpot> _buildTrendSpots() {
    final spots = <FlSpot>[];
    int index = 0;

    for (final entry in _insights!.monthlyTrends.entries) {
      spots.add(FlSpot(index.toDouble(), entry.value));
      index++;
    }

    return spots;
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food & Dining': const Color(0xFFFF9500),
      'Transportation': const Color(0xFF007AFF),
      'Shopping': const Color(0xFFFF2D92),
      'Entertainment': const Color(0xFF5856D6),
      'Healthcare': const Color(0xFFFF3B30),
      'Utilities': const Color(0xFF34C759),
      'Education': const Color(0xFF5AC8FA),
    };
    return colors[category] ?? const Color(0xFF8E8E93);
  }

  Color _getMerchantColor(String merchant) {
    final lowerMerchant = merchant.toLowerCase();
    if (lowerMerchant.contains('swiggy') || lowerMerchant.contains('zomato')) {
      return const Color(0xFFFF9500);
    } else if (lowerMerchant.contains('uber') ||
        lowerMerchant.contains('ola')) {
      return const Color(0xFF007AFF);
    } else if (lowerMerchant.contains('amazon') ||
        lowerMerchant.contains('flipkart')) {
      return const Color(0xFFFF2D92);
    }
    return const Color(0xFF5856D6);
  }

  IconData _getMerchantIcon(String merchant) {
    final lowerMerchant = merchant.toLowerCase();
    if (lowerMerchant.contains('swiggy') || lowerMerchant.contains('zomato')) {
      return Icons.restaurant;
    } else if (lowerMerchant.contains('uber') ||
        lowerMerchant.contains('ola')) {
      return Icons.directions_car;
    } else if (lowerMerchant.contains('amazon') ||
        lowerMerchant.contains('flipkart')) {
      return Icons.shopping_bag;
    }
    return Icons.store;
  }

  double _getMerchantAmount(String merchant) {
    double amount = 0;
    for (final transaction in _transactions) {
      if (transaction.merchantName
              ?.toLowerCase()
              .contains(merchant.toLowerCase()) ==
          true) {
        amount += transaction.amount;
      }
    }
    return amount;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
