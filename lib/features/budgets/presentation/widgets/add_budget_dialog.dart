import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../transactions/domain/entities/category.dart';
import '../../domain/entities/budget.dart';
import '../bloc/budget_bloc.dart';

class AddBudgetDialog extends StatefulWidget {
  final Budget? budget;

  const AddBudgetDialog({super.key, this.budget});

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  Category? _selectedCategory;
  String _selectedPeriod = 'monthly';
  List<Category> _categories = [];
  bool _isLoading = true;

  final List<String> _periods = ['weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.budget != null) {
      _amountController.text = widget.budget!.amount.toStringAsFixed(0);
      _selectedPeriod = widget.budget!.period;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final budgetBloc = context.read<BudgetBloc>();
      final categories = await budgetBloc.getCategories();

      setState(() {
        _categories = categories.where((c) => c.type == 'expense').toList();
        _isLoading = false;

        if (widget.budget != null) {
          _selectedCategory = _categories.firstWhere(
            (c) => c.id == widget.budget!.categoryId,
            orElse: () => _categories.first,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.budget == null ? 'Add Budget' : 'Edit Budget'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (Category? value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Budget Amount (₹)',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Period',
                        border: OutlineInputBorder(),
                      ),
                      items: _periods.map((period) {
                        return DropdownMenuItem<String>(
                          value: period,
                          child: Text(period.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedPeriod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveBudget,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.budget == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  void _saveBudget() {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      return;
    }

    final amount = double.parse(_amountController.text);
    final now = DateTime.now();

    // Calculate period dates
    DateTime startDate, endDate;
    switch (_selectedPeriod) {
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
      case 'monthly':
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
    }

    final budget = Budget(
      id: widget.budget?.id,
      userId: 1, // Default user ID for now
      categoryId: _selectedCategory!.id!,
      categoryName: _selectedCategory!.name,
      amount: amount,
      period: _selectedPeriod,
      startDate: startDate,
      endDate: endDate,
      createdAt: widget.budget?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.budget == null) {
      context.read<BudgetBloc>().add(AddBudget(budget));
    } else {
      context.read<BudgetBloc>().add(UpdateBudget(budget));
    }

    Navigator.of(context).pop();
  }
}
