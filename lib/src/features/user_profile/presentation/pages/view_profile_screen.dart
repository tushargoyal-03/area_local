import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import '../providers/user_profile_bloc.dart';

class ViewProfileScreen extends StatefulWidget {
  final String userId;
  const ViewProfileScreen({super.key, required this.userId});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserProfileBloc>().add(LoadPublicProfile(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state.error != null) {
          return Scaffold(
            appBar: const AppTopBar(title: 'Profile'),
            body: Center(child: Text(state.error!)),
          );
        }

        final profile = state.currentViewedProfile;
        if (profile == null) {
          return const Scaffold(
            appBar: AppTopBar(title: 'Profile'),
            body: Center(child: Text('Profile not found')),
          );
        }

        final name = profile['displayName'] ?? 'Neighbor';
        final avatar = profile['avatarUrl'];
        final role = profile['role'] ?? 'User';
        final isVerified = profile['isVerified'] == true;
        final lookingFor = List<String>.from(profile['lookingFor'] ?? []);

        return Scaffold(
          appBar: const AppTopBar(
            title: '',
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 56.r,
                    backgroundColor: cs.surfaceContainerHigh,
                    backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null ? Icon(Icons.person, size: 56.r, color: cs.onSurfaceVariant) : null,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (isVerified) ...[
                        SizedBox(width: 8.w),
                        Icon(Icons.verified, color: cs.primary, size: 20.r),
                      ]
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Text(
                      role,
                      style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionBtn(
                        icon: IconsaxPlusLinear.message, 
                        label: 'Say Hi', 
                        onTap: () {
                          // Trigger sayHi via ChatBloc
                          final currentUserId = context.read<SessionBloc>().state.user?.id;
                          if (currentUserId != null) {
                            context.read<ChatBloc>().add(StartDirectChatRequested(
                              context: context, 
                              recipientId: widget.userId, 
                              recipientName: name, 
                              currentUserId: currentUserId
                            ));
                          }
                        }
                      ),
                      _buildActionBtn(
                        icon: IconsaxPlusLinear.profile_delete, 
                        label: 'Block', 
                        onTap: () {
                           showGlobalToast(message: 'User blocked', status: 'info');
                        }
                      ),
                    ],
                  ),
                  if (lookingFor.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xxl.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Looking For', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: lookingFor.map((tag) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(100.r),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Text(tag, style: tt.bodySmall),
                      )).toList(),
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    final cs = context.theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: cs.primary),
          ),
          SizedBox(height: 8.h),
          Text(label, style: context.theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
