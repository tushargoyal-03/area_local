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

  final LocalAuthentication auth = LocalAuthentication();

  void _loadSavedCredentials() async {
    final rememberMe = StorageService.instance.getBool('remember_me') ?? false;
    if (rememberMe) {
      final savedEmail = StorageService.instance.getString('saved_email') ?? '';

      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
      });

      final savedPassword =
          StorageService.instance.getString('saved_password') ?? '';
      if (savedPassword.isNotEmpty) {
        try {
          final bool canAuthenticateWithBiometrics =
              await auth.canCheckBiometrics;
          final bool canAuthenticate =
              canAuthenticateWithBiometrics || await auth.isDeviceSupported();

          if (canAuthenticate) {
            final bool didAuthenticate = await auth.authenticate(
                localizedReason:
                    'Please authenticate to autofill your password',
                biometricOnly: true);

            if (didAuthenticate) {
              setState(() {
                _passwordController.text = savedPassword;
              });
            }
          }
          // ignore: empty_catches
        } catch (e) {}
      }
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
                email: email,
                password: password,
                onSuccess: () {
                  if (mounted) {
                    context.go(AppRoutes.home);
                  }
                },
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
      onToggleRememberMe: (value) => setState(() => _rememberMe = value),
      onLogin: handleLogin,
      cs: cs,
      tt: tt,
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
                Image.asset(
                  'assets/area_connect_logo.png',
                  width: 150.w,
                  height: 150.w,
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
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(IconsaxPlusBold.sms),
                        inputFormatters: AppInputFormatters.email,
                        validator: Validators.email,
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: passwordController,
                        enabled: !isLoading,
                        label: 'Password',
                        obscureText: obscurePassword,
                        prefixIcon: const Icon(IconsaxPlusBold.lock),
                        inputFormatters: AppInputFormatters.password,
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: onToggleObscure,
                        ),
                        validator: (v) =>
                            Validators.required(v, fieldName: 'Password'),
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
                                      color: rememberMe
                                          ? cs.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: rememberMe
                                            ? cs.primary
                                            : cs.outline.withValues(alpha: 0.6),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 150),
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
                                      color: rememberMe
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                      fontWeight: rememberMe
                                          ? FontWeight.w600
                                          : FontWeight.normal,
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
                      SizedBox(height: AppSpacing.sm.h),
                      InkWell(
                        onTap: () {
                          context.push(AppRoutes.signup);
                        },
                        child: RichText(
                          text: TextSpan(
                            text: 'Don\'t have an account? ',
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
