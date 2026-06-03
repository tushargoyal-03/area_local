import 'package:area_connect/src/imports/imports.dart';

/// A themed dropdown form field that visually matches [AppTextField].
///
/// Usage:
/// ```dart
/// AppDropdownField<String>(
///   label: 'Role',
///   prefixIcon: const Icon(IconsaxPlusLinear.user_octagon),
///   value: _selectedRole,
///   items: const [
///     DropdownMenuItem(value: 'User', child: Text('Resident')),
///     DropdownMenuItem(value: 'BusinessOwner', child: Text('Business Owner')),
///   ],
///   onChanged: (v) => setState(() => _selectedRole = v!),
/// )
/// ```
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.filled,
    this.fillColor,
    this.isExpanded = true,
    this.isDense = true,
  });

  /// Label shown inside the border (like [AppTextField.label]).
  final String? label;

  /// Hint shown when no value is selected.
  final String? hint;

  /// Currently selected value.
  final T? value;

  /// Dropdown menu items.
  final List<DropdownMenuItem<T>> items;

  /// Called when user picks a new value.
  final ValueChanged<T?>? onChanged;

  /// Validation function.
  final FormFieldValidator<T>? validator;

  /// Leading icon, mirrors [AppTextField.prefixIcon].
  final Widget? prefixIcon;

  /// Trailing icon override (defaults to the standard dropdown arrow).
  final Widget? suffixIcon;

  /// Whether the field is interactive.
  final bool enabled;

  /// Whether background is filled (matches [AppTextField] default `true`).
  final bool? filled;

  /// Custom fill color (defaults to `colorScheme.surface`).
  final Color? fillColor;

  /// Whether the dropdown should expand to fill available width.
  final bool isExpanded;

  /// Compact mode.
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      isExpanded: isExpanded,
      isDense: isDense,
      icon: suffixIcon ??
          Icon(Icons.keyboard_arrow_down_rounded,
              color: cs.onSurfaceVariant, size: 22),
      dropdownColor: cs.surface,
      borderRadius: BorderRadius.circular(AppSpacing.lg.r),
      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        filled: filled ?? true,
        fillColor: fillColor ?? cs.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xxxl.r),
          borderSide: BorderSide(
            color: cs.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xxxl.r),
          borderSide: BorderSide(
            color: cs.primary,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xxxl.r),
          borderSide: BorderSide(
            color: cs.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xxxl.r),
          borderSide: BorderSide(
            color: cs.error,
            width: 1,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xxxl.r),
          borderSide: BorderSide(
            color: cs.outline,
            width: 1,
          ),
        ),
      ),
    );
  }
}
