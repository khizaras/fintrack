/// Utility functions for safe string operations
class StringUtils {
  /// Safely format account number with masking
  static String formatAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.isEmpty) {
      return 'Unknown Account';
    }

    if (accountNumber.length >= 4) {
      return '**** ${accountNumber.substring(accountNumber.length - 4)}';
    }

    return accountNumber; // Return as-is if less than 4 characters
  }

  /// Safely truncate string to specified length
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) {
      return text;
    }

    return '${text.substring(0, maxLength)}$suffix';
  }

  /// Safely get last N characters of a string
  static String getLastNChars(String text, int n) {
    if (text.length <= n) {
      return text;
    }

    return text.substring(text.length - n);
  }

  /// Safely get first N characters of a string
  static String getFirstNChars(String text, int n) {
    if (text.length <= n) {
      return text;
    }

    return text.substring(0, n);
  }

  /// Format SMS content for logging (safely truncated)
  static String formatSmsForLogging(String smsContent, {int maxLength = 50}) {
    return truncate(smsContent, maxLength);
  }

  /// Mask sensitive data in strings
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }

    final masked = '*' * (data.length - visibleChars);
    final visible = data.substring(data.length - visibleChars);
    return '$masked$visible';
  }
}
