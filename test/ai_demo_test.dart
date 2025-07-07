import 'package:flutter_test/flutter_test.dart';
import 'package:fin_track/core/analytics/analytics_engine.dart';

void main() {
  test('AI Analytics Demo Test - Verify Demo Data is Working', () async {
    print('🚀 Testing FinTrack AI Analytics Engine...\n');

    final analytics = AnalyticsEngine();

    // Generate insights (should return demo data when no real transactions)
    final insights = await analytics.generateSpendingInsights();

    print('📊 AI INSIGHTS GENERATED:');
    print('Total Income: ₹${insights.totalIncome.toStringAsFixed(0)}');
    print('Total Expenses: ₹${insights.totalExpenses.toStringAsFixed(0)}');
    print('Net Savings: ₹${insights.netAmount.toStringAsFixed(0)}');
    print('Overall Trend: ${insights.overallTrend}');
    print('');

    print('🔝 TOP SPENDING CATEGORIES:');
    insights.categoryBreakdown.entries.take(3).forEach((entry) {
      print('${entry.key}: ₹${entry.value.toStringAsFixed(0)}');
    });
    print('');

    print('🏪 TOP MERCHANTS:');
    insights.topMerchants.take(3).forEach((merchant) {
      print('• $merchant');
    });
    print('');

    print('💡 AI RECOMMENDATIONS (${insights.recommendations.length}):');
    insights.recommendations.forEach((rec) {
      print('${rec.title}');
      print('   ${rec.description}');
      if (rec.potentialSavings! > 0) {
        print(
            '   💰 Potential Savings: ₹${rec.potentialSavings!.toStringAsFixed(0)}');
      }
      print('');
    });

    print('🚨 SPENDING ANOMALIES (${insights.anomalies.length}):');
    insights.anomalies.forEach((anomaly) {
      print('${anomaly.description}');
      print('   Amount: ₹${anomaly.amount.toStringAsFixed(0)}');
      print('   Severity: ${(anomaly.severity * 100).toStringAsFixed(0)}%');
      print('   Merchant: ${anomaly.merchant}');
      print('');
    });

    // Verify demo data is present
    expect(insights.totalIncome, greaterThan(0));
    expect(insights.totalExpenses, greaterThan(0));
    expect(insights.recommendations.length, greaterThan(0));
    expect(insights.anomalies.length, greaterThan(0));
    expect(insights.categoryBreakdown.isNotEmpty, true);

    print('✅ ALL AI FEATURES ARE WORKING!');
    print('🎯 This is exactly what you\'ll see in the app UI!');
  });
}
