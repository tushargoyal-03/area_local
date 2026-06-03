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
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
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
                    backgroundImage:
                        avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? Icon(Icons.person,
                            size: 56.r, color: cs.onSurfaceVariant)
                        : null,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: tt.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (isVerified) ...[
                        SizedBox(width: 8.w),
                        Icon(Icons.verified, color: cs.primary, size: 20.r),
                      ]
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Text(
                      role,
                      style: tt.bodySmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold),
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
                            final currentUserId =
                                context.read<SessionBloc>().state.user?.id;
                            if (currentUserId != null) {
                              context
                                  .read<ChatBloc>()
                                  .add(StartDirectChatRequested(
                                      recipientId: widget.userId,
                                      recipientName: name,
                                      currentUserId: currentUserId,
                                      onSuccess: (chatId) {
                                        if (mounted) {
                                          context.push(
                                            '/chat-room',
                                            extra: {
                                              'chatId': chatId,
                                              'recipientName': name,
                                              'recipientId': widget.userId,
                                            },
                                          );
                                        }
                                      }));
                            }
                          }),
                      _buildActionBtn(
                          icon: IconsaxPlusLinear.profile_delete,
                          label: 'Block',
                          onTap: () => _confirmBlock(context, name)),
                      _buildActionBtn(
                          icon: IconsaxPlusLinear.flag,
                          label: 'Report',
                          onTap: () => _showReportSheet(context, name)),
                    ],
                  ),
                  if (lookingFor.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xxl.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Looking For',
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: lookingFor
                          .map((tag) => Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(100.r),
                                  border: Border.all(color: cs.outlineVariant),
                                ),
                                child: Text(tag, style: tt.bodySmall),
                              ))
                          .toList(),
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

  Future<void> _confirmBlock(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: const Text('Block user?'),
        content: Text(
          '$name will no longer be able to message you, and you won\'t see '
          'their messages. You can unblock them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ChatService.instance.blockUser(widget.userId);
    result.fold(
      (failure) => showGlobalToast(message: failure.message, status: 'error'),
      (_) =>
          showGlobalToast(message: '$name has been blocked', status: 'success'),
    );
  }

  void _showReportSheet(BuildContext context, String name) {
    const reasons = <String, String>{
      'HARASSMENT_OR_BULLYING': 'Harassment or bullying',
      'INAPPROPRIATE_CONTENT': 'Inappropriate content',
      'SPAM_OR_SCAM': 'Spam or scam',
      'IMPERSONATION': 'Impersonation',
      'OTHER': 'Other',
    };

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = ctx.theme.colorScheme;
        final tt = ctx.theme.textTheme;
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text('Report $name',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 12.h),
              ...reasons.entries.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.value, style: tt.bodyMedium),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant),
                  onTap: () {
                    Navigator.pop(ctx);
                    _submitReport(e.key, name);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReport(String reason, String name) async {
    final result = await ChatService.instance.reportUser(
      userId: widget.userId,
      reason: reason,
    );
    result.fold(
      (failure) => showGlobalToast(message: failure.message, status: 'error'),
      (_) => showGlobalToast(
          message: 'Report submitted. Thanks for keeping the community safe.',
          status: 'success'),
    );
  }

  Widget _buildActionBtn(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
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
          Text(label,
              style: context.theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
