import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../bloc/insights_bloc.dart';
import '../widgets/chart_card.dart';
import '../widgets/insights_summary.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InsightsBloc()..add(const LoadInsights()),
      child: const InsightsView(),
    );
  }
}

class InsightsView extends StatelessWidget {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.spendingInsights),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<InsightsBloc, InsightsState>(
        builder: (context, state) {
          if (state is InsightsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is InsightsLoaded) {
            return _buildInsightsContent(context, state);
          }

          if (state is InsightsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<InsightsBloc>().add(const LoadInsights());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildInsightsContent(BuildContext context, InsightsLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<InsightsBloc>().add(const LoadInsights());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            InsightsSummary(
              totalIncome: state.totalIncome,
              totalExpense: state.totalExpense,
              transactionCount: state.transactionCount,
            ),
            const SizedBox(height: 24),

            // Category Breakdown Chart
            if (state.categoryData.isNotEmpty) ...[
              ChartCard(
                title: 'Spending by Category',
                child: SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieSections(state.categoryData),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildCategoryLegend(state.categoryData),
              const SizedBox(height: 24),
            ],

            // Monthly Trend Chart
            if (state.monthlyData.isNotEmpty) ...[
              ChartCard(
                title: 'Monthly Spending Trend',
                child: SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              // Validate the value before calculation
                              if (value.isNaN || value.isInfinite) {
                                return const Text('₹0k',
                                    style: TextStyle(fontSize: 12));
                              }
                              final displayValue = (value / 1000);
                              if (displayValue.isNaN ||
                                  displayValue.isInfinite) {
                                return const Text('₹0k',
                                    style: TextStyle(fontSize: 12));
                              }
                              return Text(
                                '₹${displayValue.toStringAsFixed(0)}k',
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              // Validate the value before using it as an index
                              if (value.isNaN || value.isInfinite) {
                                return const Text('',
                                    style: TextStyle(fontSize: 12));
                              }
                              final months = [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec'
                              ];
                              final index = value.toInt();
                              if (index >= 0 && index < months.length) {
                                return Text(
                                  months[index],
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const Text('',
                                  style: TextStyle(fontSize: 12));
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: state.monthlyData
                              .asMap()
                              .entries
                              .where((entry) =>
                                  !entry.value.isNaN && !entry.value.isInfinite)
                              .map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value);
                          }).toList(),
                          isCurved: true,
                          color: AppColors.primaryColor,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Top Spending Categories
            if (state.topCategories.isNotEmpty) ...[
              const Text(
                'Top Spending Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...state.topCategories.map((category) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryColor,
                        child: Text(
                          category['name'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(category['name']),
                      subtitle: Text('${category['count']} transactions'),
                      trailing: Text(
                        NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                            .format(category['amount']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No insights available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some transactions to see\nyour spending insights',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<InsightsBloc>().add(const LoadInsights());
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      Map<String, double> categoryData) {
    final colors = [
      AppColors.primaryColor,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.pink,
    ];

    // Calculate total and ensure it's not zero or NaN
    final total = categoryData.values
        .fold<double>(0.0, (a, b) => a + (b.isNaN ? 0.0 : b));
    if (total <= 0) {
      return [];
    }

    return categoryData.entries
        .where((entry) => entry.value > 0 && !entry.value.isNaN)
        .map((entry) {
      final index = categoryData.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];
      final percentage = (entry.value / total * 100);

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.isNaN ? 0.0 : percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryLegend(Map<String, double> categoryData) {
    final colors = [
      AppColors.primaryColor,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.pink,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categoryData.entries.map((entry) {
        final index = categoryData.keys.toList().indexOf(entry.key);
        final color = colors[index % colors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              entry.key,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}
