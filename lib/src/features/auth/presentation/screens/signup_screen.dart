import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'User';
  bool _isChecked = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((AuthBloc bloc) => bloc.state.isLoading);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    Future<void> handleSignup() async {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      if (!_isChecked) {
        showToast(context, message: 'Please accept terms and conditions');
        return;
      }

      // Fetch dynamic coordinates from Geolocator via LocationService
      final locationRes = await LocationService.instance.getCurrentPosition();
      final coordinates = locationRes.fold(
        (failure) => const [77.5946, 12.9716], // Fallback if failed
        (position) => [position.longitude, position.latitude],
      );

      if (context.mounted) {
        context.read<AuthBloc>().add(
              SignUpRequested(
                context: context,
                name: _nameController.text.trim(),
                email: _emailController.text.trim(),
                password: _passwordController.text,
                role: _selectedRole,
                coordinates: coordinates,
              ),
            );
      }
    }

    return _SignupView(
      formKey: _formKey,
      nameController: _nameController,
      emailController: _emailController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      obscurePassword: _obscurePassword,
      obscureConfirmPassword: _obscureConfirmPassword,
      isLoading: isLoading,
      onToggleObscure: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onToggleConfirmObscure: () =>
          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
      onSignup: handleSignup,
      cs: cs,
      tt: tt,
      isChecked: _isChecked,
      onChecked: () => setState(() => _isChecked = !_isChecked),
      selectedRole: _selectedRole,
      onRoleChanged: (val) {
        if (val != null) setState(() => _selectedRole = val);
      },
    );
  }
}

class _SignupView extends StatelessWidget {
  const _SignupView({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onToggleConfirmObscure,
    required this.onSignup,
    required this.cs,
    required this.tt,
    required this.isChecked,
    required this.onChecked,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleConfirmObscure;
  final VoidCallback onSignup;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isChecked;
  final VoidCallback onChecked;
  final String selectedRole;
  final ValueChanged<String?> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: ''),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: AppSpacing.sm.h),
              Text(
                'Create Account',
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.sm.h),
              Text(
                'Join your neighborhood in 60 seconds.',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              SizedBox(height: AppSpacing.xl.h),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: nameController,
                      enabled: !isLoading,
                      filled: true,
                      fillColor: cs.surface,
                      label: 'Full Name',
                      prefixIcon: const Icon(IconsaxPlusLinear.user),
                      validator: (v) {
                        if (AppUtils.isBlank(v)) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    AppTextField(
                      controller: emailController,
                      enabled: !isLoading,
                      filled: true,
                      fillColor: cs.surface,
                      label: 'Email',
                      prefixIcon: const Icon(IconsaxPlusLinear.sms),
                      validator: (v) {
                        if (AppUtils.isBlank(v)) {
                          return 'Email is required';
                        }
                        if (!AppUtils.isValidEmail(v!)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    AppTextField(
                      controller: passwordController,
                      enabled: !isLoading,
                      filled: true,
                      fillColor: cs.surface,
                      label: 'Password',
                      obscureText: obscurePassword,
                      prefixIcon: const Icon(IconsaxPlusLinear.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? IconsaxPlusLinear.eye_slash
                              : IconsaxPlusLinear.eye,
                        ),
                        onPressed: onToggleObscure,
                      ),
                      validator: (v) {
                        if (AppUtils.isBlank(v)) {
                          return 'Password is required';
                        }
                        if (v!.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    AppTextField(
                      controller: confirmPasswordController,
                      enabled: !isLoading,
                      filled: true,
                      fillColor: cs.surface,
                      label: 'Confirm Password',
                      obscureText: obscureConfirmPassword,
                      prefixIcon: const Icon(IconsaxPlusLinear.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirmPassword
                            ? IconsaxPlusLinear.eye_slash
                            : IconsaxPlusLinear.eye),
                        onPressed: onToggleConfirmObscure,
                      ),
                      validator: (v) {
                        if (AppUtils.isBlank(v)) {
                          return 'Confirm password is required';
                        }
                        if (v != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cs.surface,
                        labelText: 'Role',
                        prefixIcon: const Icon(IconsaxPlusLinear.user_octagon),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'User', child: Text('User / Resident')),
                        DropdownMenuItem(
                            value: 'BusinessOwner',
                            child: Text('Business Owner')),
                        DropdownMenuItem(
                            value: 'SocietyAdmin',
                            child: Text('Society Admin')),
                      ],
                      onChanged: isLoading ? null : onRoleChanged,
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: (v) => onChecked(),
                          visualDensity: VisualDensity.compact,
                        ),
                        Flexible(
                          child: Text(
                            'By signing up, you agree to our Terms of Service and Privacy Policy',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xxxl.h),
                    AppButton(
                      label: 'Sign Up',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : onSignup,
                      width: ButtonSize.large,
                      isFullWidth: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).paddingSymmetric(horizontal: AppSpacing.ml.w),
      ),
    );
  }
}
