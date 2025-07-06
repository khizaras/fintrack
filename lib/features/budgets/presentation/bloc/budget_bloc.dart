import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/entities/budget.dart';
import '../../../transactions/domain/entities/category.dart';

// Events
abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgets extends BudgetEvent {
  const LoadBudgets();
}

class AddBudget extends BudgetEvent {
  final Budget budget;

  const AddBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}

class UpdateBudget extends BudgetEvent {
  final Budget budget;

  const UpdateBudget(this.budget);

  @override
  List<Object?> get props => [budget];
}

class DeleteBudget extends BudgetEvent {
  final int budgetId;

  const DeleteBudget(this.budgetId);

  @override
  List<Object?> get props => [budgetId];
}

// States
abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

class BudgetLoaded extends BudgetState {
  final List<Budget> budgets;
  final Map<int, double> spentAmounts;

  const BudgetLoaded({
    required this.budgets,
    required this.spentAmounts,
  });

  @override
  List<Object?> get props => [budgets, spentAmounts];
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  BudgetBloc() : super(const BudgetInitial()) {
    on<LoadBudgets>(_onLoadBudgets);
    on<AddBudget>(_onAddBudget);
    on<UpdateBudget>(_onUpdateBudget);
    on<DeleteBudget>(_onDeleteBudget);
  }

  Future<void> _onLoadBudgets(
    LoadBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      emit(const BudgetLoading());

      // Load budgets with category names
      final budgetMaps = await _databaseHelper.rawQuery('''
        SELECT b.*, c.name as category_name
        FROM budgets b
        LEFT JOIN categories c ON b.category_id = c.id
        WHERE b.is_active = 1
        ORDER BY b.created_at DESC
      ''');

      final budgets = budgetMaps.map((map) => Budget.fromMap(map)).toList();

      // Calculate spent amounts for each budget
      final spentAmounts = <int, double>{};
      for (final budget in budgets) {
        final spent = await _getSpentAmount(budget);
        spentAmounts[budget.id!] = spent;
      }

      emit(BudgetLoaded(
        budgets: budgets,
        spentAmounts: spentAmounts,
      ));
    } catch (e) {
      emit(BudgetError('Failed to load budgets: $e'));
    }
  }

  Future<void> _onAddBudget(
    AddBudget event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await _databaseHelper.insert('budgets', event.budget.toMap());
      add(const LoadBudgets());
    } catch (e) {
      emit(BudgetError('Failed to add budget: $e'));
    }
  }

  Future<void> _onUpdateBudget(
    UpdateBudget event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await _databaseHelper.update(
        'budgets',
        event.budget.toMap(),
        where: 'id = ?',
        whereArgs: [event.budget.id],
      );
      add(const LoadBudgets());
    } catch (e) {
      emit(BudgetError('Failed to update budget: $e'));
    }
  }

  Future<void> _onDeleteBudget(
    DeleteBudget event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await _databaseHelper.delete(
        'budgets',
        where: 'id = ?',
        whereArgs: [event.budgetId],
      );
      add(const LoadBudgets());
    } catch (e) {
      emit(BudgetError('Failed to delete budget: $e'));
    }
  }

  Future<double> _getSpentAmount(Budget budget) async {
    final now = DateTime.now();
    final result = await _databaseHelper.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE category_id = ? 
        AND type = 'expense'
        AND date >= ? 
        AND date <= ?
    ''', [
      budget.categoryId,
      budget.startDate.toIso8601String(),
      budget.endDate.toIso8601String(),
    ]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Category>> getCategories() async {
    final categoryMaps = await _databaseHelper.query(
      'categories',
      orderBy: 'name',
    );
    return categoryMaps.map((map) => Category.fromMap(map)).toList();
  }
}
