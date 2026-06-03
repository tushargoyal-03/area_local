import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:area_connect/src/utils/email_validator.dart';

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

      // Email Validation
      final email = _emailController.text.trim();
      if (!context.mounted) return;

      // Validator
      final emailError = EmailValidator.validateEmail(email);

      if (email.isEmpty) {
        showToast(context, message: 'Email is required', status: 'error');
        return;
      }

      if (emailError != null) {
        showToast(context, message: emailError, status: 'error');
        return;
      }

      context.read<AuthBloc>().add(
            SignUpRequested(
              name: _nameController.text.trim(),
              email: email,
              password: _passwordController.text,
              role: _selectedRole,
              coordinates: coordinates,
              onSuccess: (user) {
                if (mounted) {
                  context.go(AppRoutes.verifyOtp, extra: user.email);
                }
              },
            ),
          );
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
      appBar: AppTopBar(
        showbackbutton: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: '',
      ),
      body: SafeArea(
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
                      keyboardType: TextInputType.name,
                      label: 'Full Name',
                      prefixIcon: const Icon(IconsaxPlusLinear.user),
                      inputFormatters: AppInputFormatters.fullName,
                      validator: (v) => Validators.name(v),
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    AppTextField(
                      controller: emailController,
                      enabled: !isLoading,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(IconsaxPlusLinear.sms),
                      inputFormatters: AppInputFormatters.email,
                      validator: Validators.email,
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    AppTextField(
                      controller: passwordController,
                      enabled: !isLoading,
                      label: 'Password',
                      obscureText: obscurePassword,
                      prefixIcon: const Icon(IconsaxPlusLinear.lock),
                      inputFormatters: AppInputFormatters.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? IconsaxPlusLinear.eye_slash
                              : IconsaxPlusLinear.eye,
                        ),
                        onPressed: onToggleObscure,
                      ),
                      validator: Validators.password(),
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    AppTextField(
                      controller: confirmPasswordController,
                      enabled: !isLoading,
                      label: 'Confirm Password',
                      obscureText: obscureConfirmPassword,
                      prefixIcon: const Icon(IconsaxPlusLinear.lock),
                      inputFormatters: AppInputFormatters.password,
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirmPassword
                            ? IconsaxPlusLinear.eye_slash
                            : IconsaxPlusLinear.eye),
                        onPressed: onToggleConfirmObscure,
                      ),
                      validator: Validators.confirmPassword(
                        () => passwordController.text,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    AppDropdownField<String>(
                      label: 'Role',
                      prefixIcon: const Icon(IconsaxPlusLinear.user_octagon),
                      value: selectedRole,
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
                    SizedBox(height: AppSpacing.lg),
                    CheckboxListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: isChecked,
                      onChanged: (v) => onChecked(),
                      visualDensity: const VisualDensity(
                          horizontal: VisualDensity.minimumDensity,
                          vertical: VisualDensity.minimumDensity),
                      title: Text(
                        'By signing up, you agree to our Terms of Service and Privacy Policy',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: 'Sign Up',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : onSignup,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).paddingSymmetric(horizontal: AppSpacing.xs.w),
      ),
    );
  }
}
