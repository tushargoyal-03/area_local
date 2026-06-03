import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onResetPassword() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthBloc>().add(
          ResetPasswordRequested(
            email: widget.email,
            otp: _otpController.text,
            newPassword: _passwordController.text,
            onSuccess: () {
              if (mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final isLoading = context.select((AuthBloc bloc) => bloc.state.isLoading);

    return Scaffold(
      appBar: const AppTopBar(title: ''),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Password',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 26.sp,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: AppSpacing.xs.h),
              Text(
                'Enter the 6-digit OTP sent to ${widget.email} and your new password.',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppSpacing.xxl.h),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _otpController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                      label: 'OTP Code',
                      prefixIcon: const Icon(IconsaxPlusBold.key),
                      inputFormatters: AppInputFormatters.otp(6),
                      validator: (v) => Validators.otp(v, length: 6),
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    AppTextField(
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: _obscureText,
                      label: 'New Password',
                      prefixIcon: const Icon(IconsaxPlusBold.lock_1),
                      inputFormatters: AppInputFormatters.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? IconsaxPlusLinear.eye_slash
                              : IconsaxPlusLinear.eye,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      validator: Validators.password(),
                    ),
                    SizedBox(height: AppSpacing.xxxl.h),
                    AppButton(
                      label: 'Reset Password',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onResetPassword,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
