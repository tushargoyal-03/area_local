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
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final rememberMe = StorageService.instance.getBool('remember_me') ?? false;
    if (rememberMe) {
      final savedEmail = StorageService.instance.getString('saved_email') ?? '';
      final savedPassword = StorageService.instance.getString('saved_password') ?? '';
      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
      });
    }
  }

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

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_rememberMe) {
        await StorageService.instance.setBool('remember_me', true);
        await StorageService.instance.setString('saved_email', email);
        await StorageService.instance.setString('saved_password', password);
      } else {
        await StorageService.instance.setBool('remember_me', false);
        await StorageService.instance.remove('saved_email');
        await StorageService.instance.remove('saved_password');
      }

      if (context.mounted) {
        context.read<AuthBloc>().add(
              LoginRequested(
                context: context,
                email: email,
                password: password,
              ),
            );
      }
    }

    return _LoginView(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      rememberMe: _rememberMe,
      isLoading: isLoading,
      onToggleObscure: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onToggleRememberMe: (value) =>
          setState(() => _rememberMe = value),
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
    required this.rememberMe,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onToggleRememberMe,
    required this.onLogin,
    required this.cs,
    required this.tt,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final ValueChanged<bool> onToggleRememberMe;
  final VoidCallback onLogin;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.ml.h),
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
                          GestureDetector(
                            onTap: () => onToggleRememberMe(!rememberMe),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Row(
                                spacing: 8.w,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    width: 20.w,
                                    height: 20.w,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: rememberMe ? cs.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: rememberMe ? cs.primary : cs.outline.withValues(alpha: 0.6),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 150),
                                      child: rememberMe
                                          ? Icon(
                                              Icons.check,
                                              key: const ValueKey('check'),
                                              size: 14.sp,
                                              color: Colors.white,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                  Text(
                                    'Remember Me',
                                    style: tt.bodySmall?.copyWith(
                                      color: rememberMe ? cs.primary : cs.onSurfaceVariant,
                                      fontWeight: rememberMe ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                      SizedBox(height: 20.h),
                      const AppDivider(),
                      TextButton(
                        onPressed: () {
                          context.go(AppRoutes.signup);
                        },
                        child: Text("Don't have an Account? sign up",
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
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
