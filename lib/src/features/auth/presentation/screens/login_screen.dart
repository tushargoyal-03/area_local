import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((AuthBloc bloc) => bloc.state.isLoading);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    Future<void> handleLogin() async {
      if (!(_formKey.currentState?.validate() ?? false)) return;

      context.read<AuthBloc>().add(
            LoginRequested(
              context: context,
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }

    return _LoginView(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      isLoading: isLoading,
      onToggleObscure: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onLogin: handleLogin,
      cs: cs,
      tt: tt,
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.cs,
    required this.tt,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.6),
          width: 1.5,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppBorders.button,
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        backgroundColor: cs.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8.w,
        children: [
          icon,
          Text(
            label,
            style: tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onLogin,
    required this.cs,
    required this.tt,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xl.h),
                // Brand icon
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppPalettes.primaryLight,
                        AppPalettes.primary2Light
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    IconsaxPlusBold.location,
                    color: Colors.white,
                    size: 26.sp,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
                Text(
                  'Welcome Back',
                  style:
                      tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  'Sign in to your neighborhood account',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: AppSpacing.xxxl.h),
                // Form Card
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: emailController,
                        enabled: !isLoading,
                        label: 'Email',
                        prefixIcon: const Icon(IconsaxPlusBold.sms),
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
                        label: 'Password',
                        obscureText: obscurePassword,
                        prefixIcon: const Icon(IconsaxPlusBold.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
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
                      SizedBox(height: AppSpacing.sm.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            spacing: 5.w,
                            children: [
                              SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: Checkbox(
                                  value: true,
                                  onChanged: (value) {},
                                ),
                              ),
                              Text(
                                'Remember Me',
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              context.push(AppRoutes.forgotPassword);
                            },
                            child: Text(
                              'Forgot Password?',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg.h),
                      AppButton(
                        label: 'Sign In',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : onLogin,
                        width: ButtonSize.large,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),
                // "Or continue with" divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
                      child: Text(
                        'or continue with',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg.h),
                // Social auth buttons
                Row(
                  spacing: 12.w,
                  children: [
                    Expanded(
                      child: _SocialButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          AppAssets.googleIcon,
                          width: 20.w,
                          height: 20.w,
                        ),
                        label: 'Google',
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                    Expanded(
                      child: _SocialButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          AppAssets.appleIcon,
                          width: 20.w,
                          height: 20.w,
                          colorFilter: ColorFilter.mode(
                            cs.onSurface,
                            BlendMode.srcIn,
                          ),
                        ),
                        label: 'Apple',
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxl.h),
                InkWell(
                  onTap: () {
                    context.push(AppRoutes.signup);
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Don\'t have an account? ',
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
