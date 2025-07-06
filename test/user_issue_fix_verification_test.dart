import 'package:flutter_test/flutter_test.dart';
import 'package:fin_track/features/sms/data/services/intelligent_sms_classifier.dart';
import 'package:fin_track/features/transactions/domain/entities/transaction.dart';

void main() {
  test('User reported issue: ICICI SMS should be classified as expense', () {
    // This is the exact SMS from the user's report
    const userReportedSms =
        'ICICIBANK Acct xxx961 debited for Rs 5000.00 on01-01-225 anand icici credited call +9988798 for dispute.';

    final classifier = IntelligentSmsClassifier();
    final result = classifier.determineTransactionType(userReportedSms);

    expect(result, TransactionType.expense,
        reason:
            'The account was debited (money left the account), so this should be an expense, not income. The word "credited" appears only in the dispute contact context.');

    print(
        '✅ FIXED: The problematic SMS is now correctly classified as EXPENSE');
    print('SMS: $userReportedSms');
    print(
        'Classification: ${result == TransactionType.expense ? "EXPENSE" : "INCOME"}');
  });
}
