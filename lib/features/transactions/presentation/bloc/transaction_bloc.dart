import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../../sms/data/services/sms_service.dart';

// Events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionType? type;

  const LoadTransactions({
    this.startDate,
    this.endDate,
    this.type,
  });

  @override
  List<Object?> get props => [startDate, endDate, type];
}

class ScanSMSMessages extends TransactionEvent {
  const ScanSMSMessages();
}

class LoadRecentTransactions extends TransactionEvent {
  const LoadRecentTransactions();
}

class LoadTransactionStats extends TransactionEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadTransactionStats({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class ScanSmsForTransactions extends TransactionEvent {
  const ScanSmsForTransactions();
}

class ReclassifyExistingTransactions extends TransactionEvent {
  const ReclassifyExistingTransactions();
}

class ClearAllTransactions extends TransactionEvent {
  const ClearAllTransactions();
}

class AddTransaction extends TransactionEvent {
  final Transaction transaction;

  const AddTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class UpdateTransaction extends TransactionEvent {
  final Transaction transaction;

  const UpdateTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransaction extends TransactionEvent {
  final int transactionId;

  const DeleteTransaction(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

// States
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final TransactionStats? stats;
  final List<Transaction>? recentTransactions;

  const TransactionLoaded({
    required this.transactions,
    this.stats,
    this.recentTransactions,
  });

  @override
  List<Object?> get props => [transactions, stats, recentTransactions];

  TransactionLoaded copyWith({
    List<Transaction>? transactions,
    TransactionStats? stats,
    List<Transaction>? recentTransactions,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      stats: stats ?? this.stats,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

class SmsProcessing extends TransactionState {
  const SmsProcessing();
}

class SmsProcessed extends TransactionState {
  final int transactionsFound;
  final List<Transaction> newTransactions;

  const SmsProcessed({
    required this.transactionsFound,
    required this.newTransactions,
  });

  @override
  List<Object?> get props => [transactionsFound, newTransactions];
}

class DatabaseCleared extends TransactionState {
  const DatabaseCleared();
}

// BLoC
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _transactionRepository;
  final SmsService _smsService;

  TransactionBloc({
    required TransactionRepository transactionRepository,
    required SmsService smsService,
  })  : _transactionRepository = transactionRepository,
        _smsService = smsService,
        super(const TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<LoadRecentTransactions>(_onLoadRecentTransactions);
    on<LoadTransactionStats>(_onLoadTransactionStats);
    on<ScanSMSMessages>(_onScanSMSMessages);
    on<ScanSmsForTransactions>(_onScanSmsForTransactions);
    on<ReclassifyExistingTransactions>(_onReclassifyExistingTransactions);
    on<ClearAllTransactions>(_onClearAllTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      emit(const TransactionLoading());

      List<Transaction> transactions;

      if (event.startDate != null && event.endDate != null) {
        // Filter by date range
        transactions = await _transactionRepository.getTransactionsByDateRange(
          event.startDate!,
          event.endDate!,
        );
      } else if (event.type != null) {
        // Filter by transaction type
        transactions =
            await _transactionRepository.getTransactionsByType(event.type!);
      } else {
        // Get all transactions
        transactions = await _transactionRepository.getAllTransactions();
      }

      emit(TransactionLoaded(transactions: transactions));
    } catch (e) {
      emit(TransactionError('Failed to load transactions: $e'));
    }
  }

  Future<void> _onLoadRecentTransactions(
    LoadRecentTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final current = state;
      final recentTransactions =
          await _transactionRepository.getRecentTransactions(limit: 5);

      if (current is TransactionLoaded) {
        emit(current.copyWith(recentTransactions: recentTransactions));
      } else {
        emit(TransactionLoaded(
          transactions: const [],
          recentTransactions: recentTransactions,
        ));
      }
    } catch (e) {
      emit(TransactionError('Failed to load recent transactions: $e'));
    }
  }

  Future<void> _onLoadTransactionStats(
    LoadTransactionStats event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final current = state;
      final stats = await _transactionRepository.getTransactionStats(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      if (current is TransactionLoaded) {
        emit(current.copyWith(stats: stats));
      } else {
        emit(TransactionLoaded(
          transactions: const [],
          stats: stats,
        ));
      }
    } catch (e) {
      emit(TransactionError('Failed to load transaction stats: $e'));
    }
  }

  Future<void> _onScanSmsForTransactions(
    ScanSmsForTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      emit(const SmsProcessing());

      // Check permissions first
      final hasPermission = await _smsService.checkSmsPermissions();
      if (!hasPermission) {
        final granted = await _smsService.requestSmsPermissions();
        if (!granted) {
          emit(const TransactionError(
              'SMS permission is required to scan messages'));
          return;
        }
      }

      // Read and parse SMS messages
      final newTransactions = await _smsService.readAllSmsTransactions();

      if (newTransactions.isNotEmpty) {
        // Transactions are already saved to database by SMS service
        emit(SmsProcessed(
          transactionsFound: newTransactions.length,
          newTransactions: newTransactions,
        ));

        // Reload all transactions to reflect the changes
        add(const LoadTransactions());
      } else {
        emit(const SmsProcessed(
          transactionsFound: 0,
          newTransactions: [],
        ));
      }
    } catch (e) {
      emit(TransactionError('Failed to scan SMS: $e'));
    }
  }

  Future<void> _onScanSMSMessages(
    ScanSMSMessages event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      emit(const SmsProcessing());

      // Check permissions first
      final hasPermission = await _smsService.checkSmsPermissions();
      if (!hasPermission) {
        final granted = await _smsService.requestSmsPermissions();
        if (!granted) {
          emit(const TransactionError(
              'SMS permission is required to scan messages'));
          return;
        }
      }

      // Read and parse SMS messages
      final newTransactions = await _smsService.readAllSmsTransactions();

      if (newTransactions.isNotEmpty) {
        // Transactions are already saved to database by SMS service
        emit(SmsProcessed(
          transactionsFound: newTransactions.length,
          newTransactions: newTransactions,
        ));

        // Reload all transactions to reflect the changes
        add(const LoadTransactions());
      } else {
        emit(const SmsProcessed(
          transactionsFound: 0,
          newTransactions: [],
        ));
      }
    } catch (e) {
      emit(TransactionError('Failed to scan SMS: $e'));
    }
  }

  Future<void> _onClearAllTransactions(
    ClearAllTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      emit(const TransactionLoading());
      await _transactionRepository.clearAllTransactions();

      // Emit success state first
      emit(const DatabaseCleared());

      // Then load empty transactions list
      add(const LoadTransactions());
    } catch (e) {
      emit(TransactionError('Failed to clear transactions: $e'));
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _transactionRepository.saveTransaction(event.transaction);
      add(const LoadTransactions()); // Reload transactions
    } catch (e) {
      emit(TransactionError('Failed to add transaction: $e'));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _transactionRepository.updateTransaction(event.transaction);
      add(const LoadTransactions()); // Reload transactions
    } catch (e) {
      emit(TransactionError('Failed to update transaction: $e'));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _transactionRepository.deleteTransaction(event.transactionId);
      add(const LoadTransactions()); // Reload transactions
    } catch (e) {
      emit(TransactionError('Failed to delete transaction: $e'));
    }
  }

  Future<void> _onReclassifyExistingTransactions(
    ReclassifyExistingTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      emit(const TransactionLoading());

      // Re-classify existing transactions
      final reclassifiedCount =
          await _smsService.reclassifyExistingTransactions();

      // Reload transactions to show updated classifications
      add(const LoadTransactions());

      // Note: We could emit a specific success state here if needed
      // For now, LoadTransactions will handle the emission
    } catch (e) {
      emit(TransactionError('Failed to re-classify transactions: $e'));
    }
  }
}
