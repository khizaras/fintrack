import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual data from BLoC
    final transactions = [
      {
        'title': 'Groceries',
        'subtitle': 'BigBasket',
        'amount': '-₹1,250',
        'date': 'Today, 2:30 PM',
        'icon': Icons.shopping_basket,
        'color': AppColors.categoryFood,
        'isExpense': true,
      },
      {
        'title': 'Salary Credit',
        'subtitle': 'ABC Company',
        'amount': '+₹45,000',
        'date': 'Yesterday, 9:00 AM',
        'icon': Icons.account_balance,
        'color': AppColors.income,
        'isExpense': false,
      },
      {
        'title': 'Metro Card Recharge',
        'subtitle': 'DMRC',
        'amount': '-₹500',
        'date': 'Yesterday, 8:30 AM',
        'icon': Icons.train,
        'color': AppColors.categoryTransport,
        'isExpense': true,
      },
      {
        'title': 'Netflix Subscription',
        'subtitle': 'Entertainment',
        'amount': '-₹199',
        'date': '2 days ago',
        'icon': Icons.movie,
        'color': AppColors.categoryEntertainment,
        'isExpense': true,
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: transactions.isEmpty
          ? Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your recent transactions will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 60,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (transaction['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      transaction['icon'] as IconData,
                      color: transaction['color'] as Color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    transaction['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['subtitle'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transaction['date'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    transaction['amount'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: (transaction['isExpense'] as bool)
                          ? AppColors.expense
                          : AppColors.income,
                    ),
                  ),
                  onTap: () {
                    // TODO: Navigate to transaction details
                  },
                );
              },
            ),
    );
  }
}
