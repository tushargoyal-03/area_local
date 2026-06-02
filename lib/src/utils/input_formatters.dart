import 'package:flutter/services.dart';

class FormCardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' '); // Add space every 4 digits
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

/// Reusable, strict [TextInputFormatter]s for constraining user input at the
/// keystroke level. Pair these with [Validators] for full input safety.
class AppInputFormatters {
  AppInputFormatters._();

  /// Blocks every whitespace character (spaces, tabs, newlines).
  /// Ideal for email, password and username fields.
  static final TextInputFormatter noWhitespace =
      FilteringTextInputFormatter.deny(RegExp(r'\s'));

  /// Collapses repeated spaces into a single space. Useful for names.
  static final TextInputFormatter singleSpace =
      _TransformFormatter((text) => text.replaceAll(RegExp(r'\s{2,}'), ' '));

  /// Allows digits only.
  static final TextInputFormatter digitsOnly =
      FilteringTextInputFormatter.digitsOnly;

  /// Allows characters valid in a phone number (digits, +, -, spaces, parens).
  static final TextInputFormatter phone =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'));

  /// Allows characters valid in a person's name.
  static final TextInputFormatter name =
      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s.'-]"));

  /// Forces all entered characters to lowercase (e.g. emails, usernames).
  static final TextInputFormatter lowercase =
      _TransformFormatter((text) => text.toLowerCase());

  /// Limits the field to [max] characters.
  static TextInputFormatter maxLength(int max) =>
      LengthLimitingTextInputFormatter(max);

  // ─── Convenience bundles ────────────────────────────────────────────────

  /// Email: no spaces, forced lowercase, capped length.
  static List<TextInputFormatter> get email => [
        noWhitespace,
        lowercase,
        maxLength(254),
      ];

  /// Password: no spaces, capped length.
  static List<TextInputFormatter> get password => [
        noWhitespace,
        maxLength(64),
      ];

  /// Full name: allowed characters only, single spaced, capped length.
  static List<TextInputFormatter> get fullName => [
        name,
        singleSpace,
        maxLength(50),
      ];

  /// OTP: digits only, capped to [length].
  static List<TextInputFormatter> otp([int length = 6]) => [
        digitsOnly,
        maxLength(length),
      ];
}

/// Applies a pure string transform to the incoming text while keeping the
/// caret at the end. Kept private; expose behavior via [AppInputFormatters].
class _TransformFormatter extends TextInputFormatter {
  _TransformFormatter(this.transform);

  final String Function(String) transform;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final transformed = transform(newValue.text);
    if (transformed == newValue.text) return newValue;
    return TextEditingValue(
      text: transformed,
      selection: TextSelection.collapsed(offset: transformed.length),
      composing: TextRange.empty,
    );
  }
}
