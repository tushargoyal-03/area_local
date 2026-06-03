import 'dart:async';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String signupId;
  const VerifyOtpScreen({super.key, required this.signupId});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  bool _isFocused = false;

  // Timer State
  late Timer _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Focus listeners
    _otpFocusNode.addListener(_onFocusChange);
    // Request focus on next frame to auto-focus keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _otpFocusNode.hasFocus;
    });
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 24;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _resendCode() {
    if (_secondsRemaining > 0) return;
    context.read<AuthBloc>().add(
          ResendOtpRequested(
            email:
                widget.signupId.isEmpty ? 'mock@example.com' : widget.signupId,
          ),
        );
    _startTimer();
  }

  void _onVerify() {
    if (_otpController.text.length < 6) return;

    context.read<AuthBloc>().add(
          VerifyOtpRequested(
            otp: _otpController.text,
            email:
                widget.signupId.isEmpty ? 'mock@example.com' : widget.signupId,
            onSuccess: (user) {
              if (mounted) {
                context.read<SessionBloc>().add(SessionUserChanged(user));
                context.go(AppRoutes.roleSelection);
              }
            },
          ),
        );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.removeListener(_onFocusChange);
    _otpFocusNode.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final isLoading = context.select((AuthBloc bloc) => bloc.state.isLoading);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _otpFocusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Image.asset('assets/area_connect_logo.png',
                  width: 150.w, height: 150.w),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppSpacing.md.h),
                        Text(
                          'Verify your number',
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 26.sp,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs.h),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'We sent a 6-digit code to ',
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              TextSpan(
                                text: widget.signupId.isEmpty
                                    ? '+91 98••• ••432'
                                    : widget.signupId,
                                style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.xxl.h),

                        // Hidden TextField for actual keyboard input
                        SizedBox(
                          height: 0,
                          width: 0,
                          child: TextField(
                            controller: _otpController,
                            focusNode: _otpFocusNode,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            autofocus: true,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              setState(
                                  () {}); // Rebuild to update individual digits
                            },
                          ),
                        ),

                        // Custom OTP Boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            final text = _otpController.text;
                            final hasValue = index < text.length;
                            final digit = hasValue ? text[index] : '';

                            final isActive = index == text.length && _isFocused;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: AnimatedContainer(
                                    duration: AppDurations.fast,
                                    decoration: BoxDecoration(
                                      color: hasValue
                                          ? cs.primary.withValues(alpha: 0.08)
                                          : cs.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: isActive
                                            ? cs.primary
                                            : (hasValue
                                                ? cs.primary
                                                    .withValues(alpha: 0.5)
                                                : cs.outlineVariant),
                                        width: 2.w,
                                      ),
                                      boxShadow: isActive
                                          ? [
                                              BoxShadow(
                                                color: cs.primary
                                                    .withValues(alpha: 0.15),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (hasValue)
                                          Text(
                                            digit,
                                            style: tt.titleLarge?.copyWith(
                                              fontSize: 24.sp,
                                              fontWeight: FontWeight.bold,
                                              color: cs.primary,
                                            ),
                                          ),
                                        if (isActive) const _PulsingCursor(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        SizedBox(height: AppSpacing.xxl.h),

                        // Timer / Resend Code
                        Center(
                          child: _secondsRemaining > 0
                              ? Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Resend code in ',
                                        style: tt.bodyMedium?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _timerText,
                                        style: tt.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: cs.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : TextButton(
                                  onPressed: _resendCode,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 8.h),
                                  ),
                                  child: Text(
                                    'Resend OTP',
                                    style: tt.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Verify Button at bottom
              AppButton(
                label: 'Verify',
                isLoading: isLoading,
                onPressed: isLoading || _otpController.text.length < 6
                    ? null
                    : _onVerify,
                isFullWidth: true,
              ).paddingOnly(
                left: AppSpacing.lg.w,
                right: AppSpacing.lg.w,
                bottom: AppSpacing.xxl.h,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _timerText {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PulsingCursor extends StatefulWidget {
  const _PulsingCursor();

  @override
  State<_PulsingCursor> createState() => _PulsingCursorState();
}

class _PulsingCursorState extends State<_PulsingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2.w,
        height: 24.h,
        decoration: BoxDecoration(
          color: context.theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(1.r),
        ),
      ),
    );
  }
}
