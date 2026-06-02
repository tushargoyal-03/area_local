import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:area_connect/src/features/auth/data/repositories/auth_repository_impl.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'User';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'User',
      'title': 'Local Resident',
      'desc':
          'Connect with neighbors, find activities, join sports, and borrow resources nearby.',
      'icon': IconsaxPlusBold.user,
      'gradient': const [AppPalettes.primaryLight, AppPalettes.primary2Light],
    },
    {
      'id': 'BusinessOwner',
      'title': 'Local Business Owner',
      'desc':
          'Promote your store, share active deals, and drive neighborhood foot traffic.',
      'icon': IconsaxPlusBold.shop,
      'gradient': const [Color(0xFFFF8C42), Color(0xFFE06A2A)],
    },
    {
      'id': 'SocietyAdmin',
      'title': 'Society Representative',
      'desc':
          'Manage society circulars, moderate local posts, and coordinate building events.',
      'icon': IconsaxPlusBold.home_1,
      'gradient': const [Color(0xFF2E7D6E), Color(0xFF4CAF96)],
    },
  ];

  Future<void> _handleRoleUpdate() async {
    setState(() => _isLoading = true);

    final result = await AuthRepositoryImpl().updateRole(role: _selectedRole);

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        showGlobalToast(message: failure.message, status: 'error');
      },
      (user) {
        showGlobalToast(
          message:
              'Role upgraded to ${_selectedRole == 'User' ? 'Resident' : _selectedRole == 'BusinessOwner' ? 'Business Owner' : 'Society Representative'} successfully!',
          status: 'success',
        );
        // Dispatch session update
        context.read<SessionBloc>().add(SessionUserChanged(user));

        // A freshly upgraded Society Representative needs a society to manage,
        // so guide them straight into the society hub to create one.
        if (_selectedRole == 'SocietyAdmin') {
          context.go(AppRoutes.societyFeed);
        } else {
          context.go(AppRoutes.home);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Choose your role',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Select how you want to engage with your neighborhood. You can change this anytime.',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 28.h),
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => SizedBox(height: 16.h),
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRole = role['id'] as String;
                        });
                      },
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primaryContainer.withValues(alpha: 0.15)
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(
                            color: isSelected
                                ? cs.primary
                                : cs.outlineVariant.withValues(alpha: 0.3),
                            width: 2.w,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: role['gradient'] as List<Color>,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Icon(
                                role['icon'] as IconData,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role['title'] as String,
                                    style: tt.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? cs.primary
                                          : cs.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    role['desc'] as String,
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      height: 1.4,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Padding(
                                padding: EdgeInsets.only(left: 8.w),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: cs.primary,
                                  size: 22.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ).animate(target: isSelected ? 1 : 0).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.02, 1.02),
                          duration: AppDurations.fast,
                          curve: Curves.easeOutBack,
                        );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              AppButton(
                label: 'Confirm Role',
                isLoading: _isLoading,
                onPressed: _handleRoleUpdate,
                isFullWidth: true,
              ).paddingOnly(bottom: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
