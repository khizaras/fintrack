import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'fintrack.db');

    return await openDatabase(
      path,
      version: 5, // Updated to version 5 for LLM enhancements
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Transactions table with enhanced LLM fields
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        sms_content TEXT,
        bank_name TEXT,
        account_number TEXT,
        merchant_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        recipient_or_sender TEXT,
        available_balance REAL,
        subcategory TEXT,
        transaction_method TEXT,
        location TEXT,
        reference_number TEXT,
        confidence_score REAL,
        anomaly_flags TEXT,
        llm_insights TEXT,
        transaction_time TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Budget table
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // SMS Patterns table for bank SMS recognition
    await db.execute('''
      CREATE TABLE sms_patterns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bank_name TEXT NOT NULL,
        sender_pattern TEXT NOT NULL,
        amount_pattern TEXT NOT NULL,
        account_pattern TEXT,
        description_pattern TEXT,
        balance_pattern TEXT,
        transaction_type_keywords TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);

    // Insert default SMS patterns for common banks
    await _insertDefaultSMSPatterns(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Clear any invalid data that might have been inserted with wrong schema
      await db
          .execute('DELETE FROM transactions WHERE type IS NULL OR type = ""');

      // Ensure all necessary columns exist
      // The transactions table should already have all columns from version 1
      // but we'll validate the data integrity
      final result = await db.rawQuery("PRAGMA table_info(transactions)");
      print('Database upgrade: Current transactions table schema:');
      for (final col in result) {
        print('  Column: ${col['name']} (${col['type']})');
      }
    }

    if (oldVersion < 3) {
      // Remove AI classification fields from existing transactions table
      try {
        print(
            'Database upgrade: Added AI classification fields to transactions table');
      } catch (e) {
        print(
            'Database upgrade: AI fields may already exist or error occurred: $e');
      }
    }

    if (oldVersion < 4) {
      // Remove AI fields and simplify transactions table
      try {
        // Create new table without AI fields
        await db.execute('''
          CREATE TABLE transactions_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            category_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            sms_content TEXT,
            bank_name TEXT,
            account_number TEXT,
            merchant_name TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id),
            FOREIGN KEY (category_id) REFERENCES categories (id)
          )
        ''');

        // Copy data from old table to new table
        await db.execute('''
          INSERT INTO transactions_new (id, user_id, category_id, amount, description, type, date, sms_content, bank_name, account_number, merchant_name, created_at, updated_at)
          SELECT id, user_id, category_id, amount, description, type, date, sms_content, bank_name, account_number, merchant_name, created_at, updated_at FROM transactions
        ''');

        // Drop old table and rename new table
        await db.execute('DROP TABLE transactions');
        await db.execute('ALTER TABLE transactions_new RENAME TO transactions');

        print('Database upgrade v4: Removed AI fields from transactions table');
      } catch (e) {
        print('Database upgrade v4 error: $e');
      }
    }

    if (oldVersion < 5) {
      // Add LLM enhancement fields to transactions table
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN recipient_or_sender TEXT');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN available_balance REAL');
        await db
            .execute('ALTER TABLE transactions ADD COLUMN subcategory TEXT');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN transaction_method TEXT');
        await db.execute('ALTER TABLE transactions ADD COLUMN location TEXT');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN reference_number TEXT');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN confidence_score REAL');
        await db
            .execute('ALTER TABLE transactions ADD COLUMN anomaly_flags TEXT');
        await db
            .execute('ALTER TABLE transactions ADD COLUMN llm_insights TEXT');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN transaction_time TEXT');

        print(
            'Database upgrade v5: Added LLM enhancement fields to transactions table');
      } catch (e) {
        print('Database upgrade v5 error: $e');
      }
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final categories = [
      {
        'name': 'Food',
        'icon': 'restaurant',
        'color': '#FF5722',
        'type': 'expense'
      },
      {
        'name': 'Transport',
        'icon': 'directions_car',
        'color': '#3F51B5',
        'type': 'expense'
      },
      {
        'name': 'Shopping',
        'icon': 'shopping_bag',
        'color': '#E91E63',
        'type': 'expense'
      },
      {
        'name': 'Entertainment',
        'icon': 'movie',
        'color': '#9C27B0',
        'type': 'expense'
      },
      {
        'name': 'Healthcare',
        'icon': 'local_hospital',
        'color': '#009688',
        'type': 'expense'
      },
      {
        'name': 'Utilities',
        'icon': 'home',
        'color': '#795548',
        'type': 'expense'
      },
      {
        'name': 'Education',
        'icon': 'school',
        'color': '#607D8B',
        'type': 'expense'
      },
      {
        'name': 'Income',
        'icon': 'account_balance',
        'color': '#4CAF50',
        'type': 'income'
      },
      {
        'name': 'Other',
        'icon': 'category',
        'color': '#616161',
        'type': 'expense'
      },
    ];

    for (final category in categories) {
      await db.insert('categories', {
        ...category,
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _insertDefaultSMSPatterns(Database db) async {
    final patterns = [
      {
        'bank_name': 'SBI',
        'sender_pattern': 'SBI|SBIPSG',
        'amount_pattern': r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        'account_pattern': r'a\/c\s*(\*+\d{4})',
        'description_pattern': r'at\s+([^.]+)',
        'balance_pattern': r'Avbl\s*bal\s*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        'transaction_type_keywords': 'debited,credited,withdrawn,deposited',
      },
      {
        'bank_name': 'HDFC',
        'sender_pattern': 'HDFC|HDFCBK',
        'amount_pattern': r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        'account_pattern': r'a\/c\s*(\*+\d{4})',
        'description_pattern': r'at\s+([^.]+)',
        'balance_pattern': r'Avl\s*Bal\s*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        'transaction_type_keywords': 'debited,credited,spent,received',
      },
      {
        'bank_name': 'ICICI',
        'sender_pattern': 'ICICI|ICICIB',
        'amount_pattern': r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        'account_pattern': r'a\/c\s*(\*+\d{4})',
        'description_pattern': r'at\s+([^.]+)',
        'balance_pattern': r'Avl\s*bal\s*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        'transaction_type_keywords': 'debited,credited,withdrawn,deposited',
      },
      {
        'bank_name': 'Axis',
        'sender_pattern': 'AXIS|AXISBK',
        'amount_pattern': r'Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        'account_pattern': r'a\/c\s*(\*+\d{4})',
        'description_pattern': r'at\s+([^.]+)',
        'balance_pattern': r'Avl\s*Bal\s*Rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
        'transaction_type_keywords': 'debited,credited,spent,received',
      },
    ];

    for (final pattern in patterns) {
      await db.insert('sms_patterns', {
        ...pattern,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Helper methods for database operations
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
