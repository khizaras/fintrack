import '../../../../core/database/database_helper.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/category.dart';

class TransactionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Save a transaction to the database
  Future<int> saveTransaction(Transaction transaction) async {
    final id =
        await _databaseHelper.insert('transactions', transaction.toMap());
    return id;
  }

  /// Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    final maps = await _databaseHelper.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final maps = await _databaseHelper.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get transactions by category
  Future<List<Transaction>> getTransactionsByCategory(int categoryId) async {
    final maps = await _databaseHelper.query(
      'transactions',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Get monthly transactions
  Future<List<Transaction>> getMonthlyTransactions(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return getTransactionsByDateRange(startDate, endDate);
  }

  /// Update a transaction
  Future<int> updateTransaction(Transaction transaction) async {
    return await _databaseHelper.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Delete a transaction
  Future<int> deleteTransaction(int id) async {
    return await _databaseHelper.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all transactions from the database
  Future<void> clearAllTransactions() async {
    await _databaseHelper.delete('transactions');
  }

  /// Get the total number of transactions
  Future<int> getTransactionCount() async {
    final result = await _databaseHelper.query(
      'transactions',
      columns: ['COUNT(*) as count'],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Get transaction statistics
  Future<TransactionStats> getTransactionStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final whereClause =
        startDate != null && endDate != null ? 'date BETWEEN ? AND ?' : null;
    final whereArgs = startDate != null && endDate != null
        ? [startDate.toIso8601String(), endDate.toIso8601String()]
        : null;

    final transactions = await _databaseHelper.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
    );

    double totalIncome = 0;
    double totalExpense = 0;
    int transactionCount = transactions.length;

    for (final transactionMap in transactions) {
      final transaction = Transaction.fromMap(transactionMap);
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    return TransactionStats(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      transactionCount: transactionCount,
    );
  }

  /// Get category-wise spending
  Future<List<CategorySpending>> getCategorySpending({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final whereClause = startDate != null && endDate != null
        ? "t.date BETWEEN ? AND ? AND t.transaction_type = 'expense'"
        : "t.transaction_type = 'expense'";
    final whereArgs = startDate != null && endDate != null
        ? [startDate.toIso8601String(), endDate.toIso8601String()]
        : <dynamic>[];

    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        c.id, 
        c.name, 
        c.color, 
        c.icon,
        SUM(t.amount) as total_amount,
        COUNT(t.id) as transaction_count
      FROM categories c
      LEFT JOIN transactions t ON c.id = t.category_id
      WHERE $whereClause
      GROUP BY c.id, c.name, c.color, c.icon
      ORDER BY total_amount DESC
    ''', whereArgs);

    return result.map((map) => CategorySpending.fromMap(map)).toList();
  }

  /// Get recent transactions
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    final maps = await _databaseHelper.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  /// Save multiple transactions (bulk insert)
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();

    for (final transaction in transactions) {
      batch.insert('transactions', transaction.toMap());
    }

    await batch.commit();
  }
}

/// Transaction statistics model
class TransactionStats {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;

  TransactionStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
  });

  double get savings => totalIncome - totalExpense;
  double get savingsRate => totalIncome > 0 ? (savings / totalIncome) * 100 : 0;
}

/// Category spending model
class CategorySpending {
  final int categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final double totalAmount;
  final int transactionCount;

  CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.totalAmount,
    required this.transactionCount,
  });

  factory CategorySpending.fromMap(Map<String, dynamic> map) {
    return CategorySpending(
      categoryId: map['id']?.toInt() ?? 0,
      categoryName: map['name'] ?? '',
      categoryColor: map['color'] ?? '',
      categoryIcon: map['icon'] ?? '',
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      transactionCount: map['transaction_count']?.toInt() ?? 0,
    );
  }
}
