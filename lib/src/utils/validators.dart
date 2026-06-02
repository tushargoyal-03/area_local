import 'app_utils.dart';

/// Centralized, strict form validation helpers.
///
/// Every method returns a `String?` error message (or `null` when valid), so
/// they plug directly into Flutter `TextFormField` / `AppTextField` validators:
///
/// ```dart
/// AppTextField(validator: Validators.email);
/// AppTextField(validator: Validators.password());
/// AppTextField(
///   validator: Validators.combine([
///     Validators.required,
///     (v) => Validators.minLength(v, 3),
///   ]),
/// );
/// ```
class Validators {
  Validators._();

  // ─── Reusable strict patterns ──────────────────────────────────────────
  static final RegExp _lowercase = RegExp(r'[a-z]');
  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _specialChar =
      RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.?/]');
  static final RegExp _whitespace = RegExp(r'\s');
  static final RegExp _nameAllowed = RegExp(r"^[a-zA-Z][a-zA-Z\s.'-]*$");
  static final RegExp _otpDigits = RegExp(r'^\d+$');

  // ─── Default strict password policy ────────────────────────────────────
  static const int defaultMinPasswordLength = 8;
  static const int defaultMaxPasswordLength = 64;

  /// Validates a required, non-blank field.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (AppUtils.isBlank(value)) return '$fieldName is required';
    return null;
  }

  /// Validates a person's full name.
  ///
  /// Requires at least 2 non-space characters, allows letters, spaces and the
  /// common name punctuation `. ' -`, and rejects leading digits/symbols.
  static String? name(String? value, {String fieldName = 'Name'}) {
    if (AppUtils.isBlank(value)) return '$fieldName is required';
    final trimmed = value!.trim();
    if (trimmed.length < 2) return '$fieldName is too short';
    if (trimmed.length > 50) return '$fieldName is too long';
    if (!_nameAllowed.hasMatch(trimmed)) {
      return 'Enter a valid $fieldName';
    }
    return null;
  }

  /// Validates an email address.
  static String? email(String? value) {
    if (AppUtils.isBlank(value)) return 'Email is required';
    final trimmed = value!.trim();
    if (_whitespace.hasMatch(trimmed)) {
      return 'Email cannot contain spaces';
    }
    if (!AppUtils.isValidEmail(trimmed)) return 'Enter a valid email';
    return null;
  }

  /// Validates a strong password against a strict policy.
  ///
  /// Returns a `FormFieldValidator`-compatible function. Defaults enforce:
  /// min length, lowercase, uppercase, digit, special character and no spaces.
  static String? Function(String?) password({
    int minLength = defaultMinPasswordLength,
    int maxLength = defaultMaxPasswordLength,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireDigit = true,
    bool requireSpecialChar = true,
  }) {
    return (String? value) {
      if (AppUtils.isBlank(value)) return 'Password is required';
      final v = value!;
      if (_whitespace.hasMatch(v)) return 'Password cannot contain spaces';
      if (v.length < minLength) {
        return 'Password must be at least $minLength characters';
      }
      if (v.length > maxLength) {
        return 'Password must be under $maxLength characters';
      }
      if (requireLowercase && !_lowercase.hasMatch(v)) {
        return 'Add at least one lowercase letter';
      }
      if (requireUppercase && !_uppercase.hasMatch(v)) {
        return 'Add at least one uppercase letter';
      }
      if (requireDigit && !_digit.hasMatch(v)) {
        return 'Add at least one number';
      }
      if (requireSpecialChar && !_specialChar.hasMatch(v)) {
        return 'Add at least one special character';
      }
      return null;
    };
  }

  /// Validates that [value] matches the [original] password.
  static String? Function(String?) confirmPassword(
    String Function() original, {
    String fieldName = 'Confirm password',
  }) {
    return (String? value) {
      if (AppUtils.isBlank(value)) return '$fieldName is required';
      if (value != original()) return 'Passwords do not match';
      return null;
    };
  }

  /// Validates a phone number using the shared [AppUtils.isPhoneNumber] rule.
  static String? phone(String? value, {bool isRequired = true}) {
    if (AppUtils.isBlank(value)) {
      return isRequired ? 'Phone number is required' : null;
    }
    if (!AppUtils.isPhoneNumber(value!.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validates a numeric OTP/verification code of an exact [length].
  static String? otp(String? value, {int length = 6}) {
    if (AppUtils.isBlank(value)) return 'Code is required';
    final trimmed = value!.trim();
    if (!_otpDigits.hasMatch(trimmed)) return 'Code must be digits only';
    if (trimmed.length != length) return 'Enter the $length-digit code';
    return null;
  }

  /// Validates a URL using the shared [AppUtils.isURL] rule.
  static String? url(String? value, {bool isRequired = false}) {
    if (AppUtils.isBlank(value)) {
      return isRequired ? 'URL is required' : null;
    }
    if (!AppUtils.isURL(value!.trim())) return 'Enter a valid URL';
    return null;
  }

  /// Enforces a minimum trimmed length.
  static String? minLength(
    String? value,
    int min, {
    String fieldName = 'This field',
  }) {
    if (AppUtils.isBlank(value)) return '$fieldName is required';
    if (value!.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  /// Enforces a maximum trimmed length (does not require a value).
  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'This field',
  }) {
    if (value != null && value.trim().length > max) {
      return '$fieldName must be under $max characters';
    }
    return null;
  }

  /// Runs [validators] in order and returns the first error, or null.
  ///
  /// Useful for composing field-specific rules:
  /// ```dart
  /// validator: Validators.combine([
  ///   Validators.required,
  ///   (v) => Validators.minLength(v, 3),
  /// ]),
  /// ```
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
