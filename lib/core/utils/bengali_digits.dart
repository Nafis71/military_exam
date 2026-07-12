const _bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Converts Western digits in [value] to Bengali numerals.
String toBengaliDigits(int value) => toBengaliDigitString(value.toString());

/// Converts Western digits in [value] to Bengali numerals; other chars kept.
String toBengaliDigitString(String value) {
  return value.split('').map((char) {
    final digit = int.tryParse(char);
    if (digit == null) return char;
    return _bengaliDigits[digit];
  }).join();
}

