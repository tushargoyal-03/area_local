import 'package:flutter/material.dart';

/// App-specific colors that aren't part of the standard [ColorScheme].
/// Access via `context.appColors` (defined in `context_extension.dart`).
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    this.successContainer,
    this.onSuccessContainer,
    this.warningContainer,
    this.onWarningContainer,
    this.infoContainer,
    this.onInfoContainer,
    required this.primary2,
    required this.primarySoft,
    required this.secondary,
    required this.muted,
    required this.accent,
    required this.border,
    required this.input,
    required this.ring,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;
  final Color? successContainer;
  final Color? onSuccessContainer;
  final Color? warningContainer;
  final Color? onWarningContainer;
  final Color? infoContainer;
  final Color? onInfoContainer;

  // New integrated custom colors
  final Color primary2;
  final Color primarySoft;
  final Color secondary;
  final Color muted;
  final Color accent;
  final Color border;
  final Color input;
  final Color ring;

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? primary2,
    Color? primarySoft,
    Color? secondary,
    Color? muted,
    Color? accent,
    Color? border,
    Color? input,
    Color? ring,
  }) {
    return AppColorsExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      primary2: primary2 ?? this.primary2,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t),
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t),
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t),
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t),
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t),
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t),
      primary2: Color.lerp(primary2, other.primary2, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
    );
  }
}

/// Helper class to define the actual color palettes
class AppPalettes {
  AppPalettes._();

  // Integrated Color Theme Constants
  static const Color backgroundLight = Color(0xFFFCFAF7);
  static const Color foregroundLight = Color(0xFF382B24);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color primaryLight = Color(0xFFE06A2A); // saffron/terracotta
  static const Color primary2Light = Color(0xFFC94B7A); // rose-plum
  static const Color primarySoftLight = Color(0xFFFBE9DF);
  static const Color secondaryLight = Color(0xFFF6F1E7);
  static const Color mutedLight = Color(0xFFF8F5F1);
  static const Color accentLight = Color(0xFFD95C9A);
  static const Color borderLight = Color(0xFFE8DDD3);
  static const Color inputLight = Color(0xFFF2E9E0);
  static const Color ringLight = Color(0xFFE06A2A);

  static const Color backgroundDark = Color(0xFF1B1614);
  static const Color foregroundDark = Color(0xFFF5EEE8);
  static const Color cardDark = Color(0xFF26201D);
  static const Color primaryDark = Color(0xFFFF8A4C);
  static const Color primary2Dark = Color(0xFFFF6FA3);
  static const Color primarySoftDark = Color(0xFF35251F);
  static const Color secondaryDark = Color(0xFF2D2622);
  static const Color mutedDark = Color(0xFF2A2320);
  static const Color accentDark = Color(0xFFE965A9);
  static const Color borderDark = Color(0xFF3A302B);
  static const Color inputDark = Color(0xFF40352F);
  static const Color ringDark = Color(0xFFFF8A4C);

  static const light = AppColorsExtension(
    success: Color(0xFF2E7D32),
    onSuccess: Colors.white,
    successContainer: Color(0xFFA5D6A7),
    onSuccessContainer: Color(0xFF1B5E20),
    warning: Color(0xFFED6C02),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFFCC80),
    onWarningContainer: Color(0xFFE65100),
    info: Color(0xFF0288D1),
    onInfo: Colors.white,
    infoContainer: Color(0xFF81D4FA),
    onInfoContainer: Color(0xFF01579B),
    primary2: primary2Light,
    primarySoft: primarySoftLight,
    secondary: secondaryLight,
    muted: mutedLight,
    accent: accentLight,
    border: borderLight,
    input: inputLight,
    ring: ringLight,
  );

  static const dark = AppColorsExtension(
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF003300),
    successContainer: Color(0xFF1B5E20),
    onSuccessContainer: Color(0xFFA5D6A7),
    warning: Color(0xFFFFB74D),
    onWarning: Color(0xFF5D4037),
    warningContainer: Color(0xFFE65100),
    onWarningContainer: Color(0xFFFFCC80),
    info: Color(0xFF4FC3F7),
    onInfo: Color(0xFF01579B),
    infoContainer: Color(0xFF0277BD),
    onInfoContainer: Color(0xFFE1F5FE),
    primary2: primary2Dark,
    primarySoft: primarySoftDark,
    secondary: secondaryDark,
    muted: mutedDark,
    accent: accentDark,
    border: borderDark,
    input: inputDark,
    ring: ringDark,
  );
}

/// Access semantic colors via `context.appColors` from `context_extension.dart`.
/// Example: `context.appColors.success`