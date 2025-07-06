import 'package:flutter_test/flutter_test.dart';
import 'package:fin_track/features/sms/data/services/intelligent_sms_classifier.dart';
import 'package:fin_track/features/transactions/domain/entities/transaction.dart';

void main() {
  group('Transaction Type Classification Tests', () {
    late IntelligentSmsClassifier classifier;

    setUp(() {
      classifier = IntelligentSmsClassifier();
    });

    test('should correctly classify debited transaction as expense', () {
      // The problematic SMS from the user
      const smsContent =
          'ICICIBANK Acct xxx961 debited for Rs 5000.00 on01-01-225 anand icici credited call +9988798 for dispute.';

      final result = classifier.determineTransactionType(smsContent);

      expect(result, TransactionType.expense,
          reason:
              'Account debited should be classified as expense, despite "credited" appearing in dispute context');
    });

    test('should correctly classify various debit scenarios', () {
      final debitSmsExamples = [
        'Your account XXX1234 debited for Rs 1000.00 at ATM',
        'SBI Account debited Rs 500 for payment to Amazon',
        'HDFC Acct withdrawn Rs 2000 on 01-Jan-2025',
        'Account XXX debited for Rs 100.00 UPI payment',
        'Your account has been debited for Rs 750.00',
      ];

      for (final sms in debitSmsExamples) {
        final result = classifier.determineTransactionType(sms);
        expect(result, TransactionType.expense,
            reason: 'SMS: "$sms" should be classified as expense');
      }
    });

    test('should correctly classify various credit scenarios', () {
      final creditSmsExamples = [
        'Your account XXX1234 credited with Rs 1000.00 salary',
        'SBI Account credited Rs 500 refund from Amazon',
        'HDFC Acct deposited Rs 2000 on 01-Jan-2025',
        'Account XXX credited Rs 100.00 bonus payment',
        'Amount Rs 750.00 credited to your account',
      ];

      for (final sms in creditSmsExamples) {
        final result = classifier.determineTransactionType(sms);
        expect(result, TransactionType.income,
            reason: 'SMS: "$sms" should be classified as income');
      }
    });

    test('should handle complex mixed-keyword scenarios', () {
      final complexSmsExamples = [
        {
          'sms': 'Your account debited Rs 100 transferred to recipient account',
          'expected': TransactionType.expense,
          'reason': 'Money leaving your account should be expense'
        },
        {
          'sms': 'Amount Rs 500 credited to your account from sender account',
          'expected': TransactionType.income,
          'reason': 'Money coming to your account should be income'
        },
        {
          'sms':
              'Payment successful Rs 200 debited from your account credited to merchant',
          'expected': TransactionType.expense,
          'reason': 'Payment from your account should be expense'
        }
      ];

      for (final example in complexSmsExamples) {
        final result =
            classifier.determineTransactionType(example['sms'] as String);
        expect(result, example['expected'] as TransactionType,
            reason: example['reason'] as String);
      }
    });

    test('should prioritize primary transaction indicators', () {
      // Test that words at the beginning get higher priority
      const primaryDebitSms =
          'Debited Rs 100 from your account. For dispute call customer care';
      final result1 = classifier.determineTransactionType(primaryDebitSms);
      expect(result1, TransactionType.expense);

      const primaryCreditSms =
          'Credited Rs 100 to your account. Previous transaction reversed';
      final result2 = classifier.determineTransactionType(primaryCreditSms);
      expect(result2, TransactionType.income);
    });

    test('should handle bank-specific patterns correctly', () {
      final bankSpecificExamples = [
        'ICICIBANK Acct XX1234 debited for Rs 500.00 on 01-Jan-2025',
        'SBIINB: Your A/c XX5678 is debited Rs 1000 for payment',
        'HDFC Bank: Acct XX9999 debited by Rs 250.00',
        'AXISBK: Your account XX1111 debited Rs 750',
      ];

      for (final sms in bankSpecificExamples) {
        final result = classifier.determineTransactionType(sms);
        expect(result, TransactionType.expense,
            reason:
                'Bank SMS with debit should be classified as expense: "$sms"');
      }
    });

    test('should ignore secondary mentions in dispute context', () {
      final disputeContextExamples = [
        'Your account debited Rs 100. For dispute call credited helpline',
        'Acct debited Rs 500. To dispute this credited transaction call support',
        'Debited Rs 200 from account. Contact customer care for credited refund',
      ];

      for (final sms in disputeContextExamples) {
        final result = classifier.determineTransactionType(sms);
        expect(result, TransactionType.expense,
            reason: 'Should ignore "credited" in dispute context: "$sms"');
      }
    });
  });
}
