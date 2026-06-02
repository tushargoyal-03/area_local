import 'package:area_connect/src/imports/imports.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const List<({String title, String subtitle, int type})> _pages = [
    (
      title: 'Meet Your\nNeighbors',
      subtitle:
          'Connect with residents, discover who lives nearby, and build real community bonds around you.',
      type: 0,
    ),
    (
      title: 'Discover Local\nActivities',
      subtitle:
          'Find sports, meetups, and events happening within 5 km. Join in or create your own.',
      type: 1,
    ),
    (
      title: 'Stay\nConnected',
      subtitle:
          'Chat directly with neighbors, stay updated on local posts, and never miss what\'s happening nearby.',
      type: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppDurations.medium,
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Brand header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg.w,
                vertical: AppSpacing.md.h,
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/area_connect_logo.png',
                    width: 34.w,
                    height: 34.w,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Area Connect',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20.sp,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                    child: Column(
                      children: [
                        Expanded(
                          child: _OnboardingIllustration(type: page.type),
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 28.sp,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fade(duration: AppDurations.slow).slideY(
                            begin: 0.15, end: 0, duration: AppDurations.slow),
                        SizedBox(height: AppSpacing.md.h),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.6,
                            fontSize: 14.sp,
                          ),
                        ).animate().fade(
                              delay: const Duration(milliseconds: 100),
                              duration: AppDurations.slow,
                            ),
                        SizedBox(height: AppSpacing.sm.h),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg.w,
                0,
                AppSpacing.lg.w,
                AppSpacing.xl.h,
              ),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8.h,
                      dotWidth: 8.w,
                      activeDotColor: cs.primary,
                      dotColor: cs.primary.withValues(alpha: 0.2),
                      expansionFactor: 4,
                      spacing: 6.w,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  AppButton(
                    label: _currentIndex == _pages.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    onPressed: _handleContinue,
                    isFullWidth: true,
                  ),
                  if (_currentIndex < _pages.length - 1) ...[
                    SizedBox(height: AppSpacing.sm.h),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(
                        'Skip for now',
                        style:
                            tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ] else
                    SizedBox(height: 44.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ─── Illustration switcher ─────────────────────────────────────────── */

class _OnboardingIllustration extends StatelessWidget {
  final int type;

  const _OnboardingIllustration({required this.type});

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      0 => const _NeighborsIllustration(),
      1 => const _DiscoverIllustration(),
      _ => const _ChatIllustration(),
    };
  }
}

/* ─── Page 1: Meet Your Neighbors ──────────────────────────────────── */

class _NeighborsIllustration extends StatelessWidget {
  const _NeighborsIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Center(
      child: SizedBox(
        width: 270.w,
        height: 270.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 270.w,
              height: 270.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.05),
              ),
            ),
            // Middle ring
            Container(
              width: 190.w,
              height: 190.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.08),
              ),
            ),
            // Center icon
            Container(
              width: 96.w,
              height: 96.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppPalettes.primaryLight, AppPalettes.primary2Light],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                IconsaxPlusBold.home_1,
                color: Colors.white,
                size: 38.sp,
              ),
            ),
            // Neighbor chips
            Positioned(top: 18.h, child: _NeighborChip('Riya', cs)),
            Positioned(left: 8.w, child: _NeighborChip('Karan', cs)),
            Positioned(right: 8.w, child: _NeighborChip('Meera', cs)),
            Positioned(bottom: 18.h, child: _NeighborChip('You', cs)),
          ],
        ),
      ),
    );
  }
}

class _NeighborChip extends StatelessWidget {
  final String name;
  final ColorScheme cs;

  const _NeighborChip(this.name, this.cs);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11.w,
            backgroundColor: cs.primary.withValues(alpha: 0.15),
            child: Text(
              name[0],
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            name,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/* ─── Page 2: Discover Activities ──────────────────────────────────── */

class _DiscoverIllustration extends StatelessWidget {
  const _DiscoverIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final items = [
      (IconsaxPlusLinear.flash, 'Sports', cs.primary),
      (IconsaxPlusLinear.calendar, 'Events', const Color(0xFF2196F3)),
      (IconsaxPlusLinear.message, 'Meetup', AppPalettes.primary2Light),
      (IconsaxPlusLinear.location, 'Nearby', const Color(0xFF4CAF50)),
      (IconsaxPlusLinear.home_1, 'Society', const Color(0xFFFF9800)),
      (IconsaxPlusLinear.search_normal, 'Explore', const Color(0xFF9C27B0)),
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Location badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(100.r),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconsaxPlusBold.location,
                  color: cs.primary,
                  size: 18.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Within 5 km',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          // Activity chips grid
          Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: items
                .map(
                  (item) => Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: item.$3.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: item.$3.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(item.$1, color: item.$3, size: 22.sp),
                        SizedBox(height: 5.h),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: item.$3,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/* ─── Page 3: Stay Connected ────────────────────────────────────────── */

class _ChatIllustration extends StatelessWidget {
  const _ChatIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _ChatBubble(
              text: 'Hey! Are you joining the yoga session tomorrow?',
              isMe: false,
              cs: cs,
            ),
          ),
          SizedBox(height: 10.h),
          Align(
            alignment: Alignment.centerRight,
            child: _ChatBubble(
              text: 'Absolutely! 6:30 AM at Central Park',
              isMe: true,
              cs: cs,
            ),
          ),
          SizedBox(height: 10.h),
          // Typing indicator
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(4.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 4.w : 0),
                    child: Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ).paddingSymmetric(horizontal: AppSpacing.sm.w),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final ColorScheme cs;

  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 240.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isMe ? cs.primary : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
          bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(4.r),
          bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(16.r),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isMe ? cs.onPrimary : cs.onSurface,
          fontSize: 13.sp,
          height: 1.4,
        ),
      ),
    );
  }
}
