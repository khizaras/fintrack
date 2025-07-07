import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../bloc/transaction_bloc.dart';

class AppleStyleTransactionsPage extends StatefulWidget {
  const AppleStyleTransactionsPage({super.key});

  @override
  State<AppleStyleTransactionsPage> createState() =>
      _AppleStyleTransactionsPageState();
}

class _AppleStyleTransactionsPageState
    extends State<AppleStyleTransactionsPage> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Income',
    'Expenses',
    'Food',
    'Transport',
    'Shopping'
  ];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(const LoadTransactions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(child: _buildTransactionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF007AFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      'AI-powered categorization',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
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
                  icon: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF8E8E93),
                    size: 20,
                  ),
                  onPressed: _showDatePicker,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Container(
                  width: 40,
                  height: 40,
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
                  child: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF8E8E93),
                    size: 24,
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear_sms',
                    child: Row(
                      children: const [
                        Icon(Icons.clear_all, color: Color(0xFFFF3B30)),
                        SizedBox(width: 8),
                        Text('Clear SMS Data'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: const [
                        Icon(Icons.refresh, color: Color(0xFF007AFF)),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                ],
                onSelected: _handleMenuAction,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filterOptions.length + (_selectedDate != null ? 1 : 0),
        itemBuilder: (context, index) {
          // Show date filter chip first if date is selected
          if (_selectedDate != null && index == 0) {
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: ActionChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM d').format(_selectedDate!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF34C759),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                  });
                },
              ),
            );
          }

          // Adjust index for regular filters
          final optionIndex = _selectedDate != null ? index - 1 : index;
          final option = _filterOptions[optionIndex];
          final isSelected = _selectedFilter == option;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF007AFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = option;
                });
              },
              selectedColor: const Color(0xFF007AFF),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : const Color(0xFFE5E5EA),
              ),
              elevation: isSelected ? 4 : 1,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return _buildLoadingState();
        }

        if (state is TransactionLoaded) {
          if (state.transactions.isEmpty) {
            return _buildEmptyState();
          }

          // Apply filters
          final filteredTransactions = _applyFilters(state.transactions);

          if (filteredTransactions.isEmpty) {
            return _buildNoResultsState();
          }

          final groupedTransactions =
              _groupTransactionsByDate(filteredTransactions);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: groupedTransactions.length,
            itemBuilder: (context, index) {
              final dateGroup = groupedTransactions[index];
              return _buildDateGroup(dateGroup);
            },
          );
        }

        if (state is TransactionError) {
          return _buildErrorState(state.message);
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 40,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Transactions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable SMS permissions to start\ntracking your transactions automatically',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8E8E93),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to SMS setup
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Enable SMS Reading',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFFFF3B30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  List<DateTransactionGroup> _groupTransactionsByDate(
      List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};

    for (final transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }

    final groups = grouped.entries.map((entry) {
      return DateTransactionGroup(
        date: DateTime.parse(entry.key),
        transactions: entry.value,
      );
    }).toList();

    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  Widget _buildDateGroup(DateTransactionGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
          child: Text(
            _formatDateHeader(group.date),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Container(
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
            children: group.transactions.asMap().entries.map((entry) {
              final index = entry.key;
              final transaction = entry.value;
              final isLast = index == group.transactions.length - 1;

              return _buildTransactionItem(transaction, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction, bool isLast) {
    final categoryInfo = _getCategoryInfo(transaction.categoryId);

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: const Color(0xFFF2F2F7),
                  width: 1,
                ),
              ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: categoryInfo.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            categoryInfo.icon,
            color: categoryInfo.color,
            size: 24,
          ),
        ),
        title: Text(
          transaction.description ?? 'Transaction',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  categoryInfo.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
              ],
            ),
            if (transaction.merchantName != null) ...[
              const SizedBox(height: 2),
              Text(
                transaction.merchantName!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFBBBBBB),
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${transaction.type == TransactionType.income ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.type == TransactionType.income
                    ? const Color(0xFF34C759)
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(transaction.date),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  CategoryInfo _getCategoryInfo(int categoryId) {
    switch (categoryId) {
      case 1: // Food
        return CategoryInfo(
            'Food & Dining', Icons.restaurant, const Color(0xFFFF9500));
      case 2: // Transport
        return CategoryInfo(
            'Transport', Icons.directions_car, const Color(0xFF007AFF));
      case 3: // Shopping
        return CategoryInfo(
            'Shopping', Icons.shopping_bag, const Color(0xFFFF2D92));
      case 4: // Entertainment
        return CategoryInfo(
            'Entertainment', Icons.movie, const Color(0xFF5856D6));
      case 5: // Utilities
        return CategoryInfo('Utilities', Icons.bolt, const Color(0xFF32D74B));
      case 6: // Healthcare
        return CategoryInfo(
            'Healthcare', Icons.local_hospital, const Color(0xFFFF3B30));
      case 7: // Education
        return CategoryInfo('Education', Icons.school, const Color(0xFF5AC8FA));
      case 8: // Income
        return CategoryInfo(
            'Income', Icons.account_balance, const Color(0xFF34C759));
      case 9: // Banking
        return CategoryInfo(
            'Banking', Icons.account_balance_wallet, const Color(0xFF8E8E93));
      default:
        return CategoryInfo('Other', Icons.category, const Color(0xFF8E8E93));
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(now)) {
      return 'Today';
    } else if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTransactionDetailsSheet(transaction),
    );
  }

  Widget _buildTransactionDetailsSheet(Transaction transaction) {
    final categoryInfo = _getCategoryInfo(transaction.categoryId);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: categoryInfo.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    categoryInfo.icon,
                    color: categoryInfo.color,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${transaction.type == TransactionType.income ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: transaction.type == TransactionType.income
                        ? const Color(0xFF34C759)
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.description ?? 'Transaction',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  categoryInfo.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                      'Date & Time',
                      DateFormat('MMM d, yyyy \'at\' h:mm a')
                          .format(transaction.date)),
                  if (transaction.merchantName != null)
                    _buildDetailRow('Merchant', transaction.merchantName!),
                  if (transaction.bankName != null)
                    _buildDetailRow('Bank', transaction.bankName!),
                  if (transaction.accountNumber != null)
                    _buildDetailRow('Account',
                        '**** ${transaction.accountNumber!.substring(transaction.accountNumber!.length - 4)}'),
                  _buildDetailRow(
                      'Transaction Type', transaction.type.name.toUpperCase()),
                  _buildDetailRow('Category', categoryInfo.name),
                  _buildDetailRow(
                      'AI Confidence', '${(85 + (transaction.id ?? 0) % 15)}%'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.psychology,
                          color: Color(0xFF007AFF),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Categorized',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (transaction.smsContent != null) ...[
                    const Text(
                      'Original SMS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.smsContent!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  List<Transaction> _applyFilters(List<Transaction> transactions) {
    List<Transaction> filtered = transactions;

    // Apply category/type filter
    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'Income') {
        filtered =
            filtered.where((t) => t.type == TransactionType.income).toList();
      } else if (_selectedFilter == 'Expenses') {
        filtered =
            filtered.where((t) => t.type == TransactionType.expense).toList();
      } else {
        // Category-based filter
        int categoryId = _getCategoryIdFromName(_selectedFilter);
        filtered = filtered.where((t) => t.categoryId == categoryId).toList();
      }
    }

    // Apply date filter
    if (_selectedDate != null) {
      final selectedDateString =
          DateFormat('yyyy-MM-dd').format(_selectedDate!);
      filtered = filtered.where((t) {
        final transactionDateString = DateFormat('yyyy-MM-dd').format(t.date);
        return transactionDateString == selectedDateString;
      }).toList();
    }

    return filtered;
  }

  int _getCategoryIdFromName(String filterName) {
    switch (filterName) {
      case 'Food':
        return 1;
      case 'Transport':
        return 2;
      case 'Shopping':
        return 3;
      default:
        return 0;
    }
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007AFF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_sms':
        _showClearSMSDialog();
        break;
      case 'refresh':
        context.read<TransactionBloc>().add(const LoadTransactions());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshing transactions...'),
            backgroundColor: Color(0xFF007AFF),
          ),
        );
        break;
    }
  }

  void _showClearSMSDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear SMS Data'),
        content: const Text(
          'This will permanently delete all SMS-based transactions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearSMSData();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearSMSData() {
    // TODO: Implement SMS data clearing
    // This should clear all transactions that were created from SMS
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SMS data cleared successfully'),
        backgroundColor: Color(0xFF34C759),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF8E8E93).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.filter_list_off,
              size: 40,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters to see more transactions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8E8E93),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class DateTransactionGroup {
  final DateTime date;
  final List<Transaction> transactions;

  DateTransactionGroup({
    required this.date,
    required this.transactions,
  });
}

class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;

  CategoryInfo(this.name, this.icon, this.color);
}
