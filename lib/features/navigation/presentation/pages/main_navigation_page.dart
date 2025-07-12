import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/pages/modern_home_page.dart';
import '../../../transactions/presentation/pages/apple_style_transactions_page.dart';
import '../../../budgets/presentation/pages/budgets_page.dart';
import '../../../insights/presentation/pages/enterprise_insights_dashboard.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ModernHomePage(),
    const AppleStyleTransactionsPage(),
    const BudgetsPage(),
    const EnterpriseInsightsDashboard(), // Updated to enterprise dashboard
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AI Insights',
          ),
        ],
      ),
    );
  }
}
