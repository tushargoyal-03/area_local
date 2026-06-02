/// A validator utility class for form fields, specifically handling email validation.
class EmailValidator {
  /// Regular expression for standard email validation.
  /// This covers most standard email formats.
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// A set of known disposable, temporary, or burner email domains.
  /// Using a Set provides O(1) lookup time for faster validation.
  ///
  /// SCALING BEST PRACTICE:
  /// Hardcoding this list is good for initial MVPs, but as the app scales,
  /// this list will quickly become outdated.
  /// To scale this in a production environment:
  /// 1. API Integration: Fetch the latest blocklist from your backend on app startup
  ///    or periodically, caching it locally (e.g., using SharedPreferences or a local DB).
  /// 2. Third-Party Service: Use an external API (like Kickbox, ZeroBounce, or similar)
  ///    on the backend during the actual signup API call to catch newly created disposable domains.
  /// 3. Backend Verification: Always re-validate the email on the server-side,
  ///    do not rely solely on client-side validation for security/blocking.
  static final Set<String> _disposableDomains = {
    'yopmail.com',
    'mailinator.com',
    'temp-mail.org',
    'guerrillamail.com',
    'emailondeck.com',
    'tempmailo.com',
    'mailsac.com',
    'fakemail.net',
    'throwawaymail.com',
    'mohmal.com',
    'minuteinbox.com',
    'dropmail.me',
    'trashmail.com',
    'burnermail.io',
    'simplelogin.com',
    'simplelogin.io',
    'relay.firefox.com',
    'mozmail.com',
  };

  /// Validates an email string.
  /// Can be used directly in a `TextFormField`'s `validator` property.
  ///
  /// Returns null if the email is valid, otherwise returns an error message.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }

    final email = value.trim();

    // 1. Validate standard email format using Regex
    if (!_emailRegExp.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    // 2. Extract domain and check against disposable domains list
    try {
      final parts = email.split('@');
      if (parts.length == 2) {
        final domain = parts[1].toLowerCase();

        if (_disposableDomains.contains(domain)) {
          return 'Temporary/disposable email addresses are not allowed';
        }
      }
    } catch (e) {
      // Fallback in case of unexpected string manipulation errors
      return 'Enter a valid email address';
    }

    // Email is valid
    return null;
  }
}
