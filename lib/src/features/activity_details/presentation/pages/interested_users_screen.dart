import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class InterestedUsersScreen extends StatefulWidget {
  final String postId;
  final String postTitle;

  const InterestedUsersScreen({
    super.key,
    required this.postId,
    required this.postTitle,
  });

  @override
  State<InterestedUsersScreen> createState() => _InterestedUsersScreenState();
}

class _InterestedUsersScreenState extends State<InterestedUsersScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<PostsBloc>()
        .add(LoadInterestedUsersRequested(postId: widget.postId));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppTopBar(
        title: 'Interested Users',
        centerTitle: true,
      ),
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          if (state.isLoadingInterestedUsers) {
            return ListView.builder(
              padding: EdgeInsets.all(AppSpacing.lg.w),
              itemCount: 6,
              itemBuilder: (_, __) => _SkeletonCard(),
            );
          }

          if (state.interestedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(IconsaxPlusLinear.people,
                      size: 48.w, color: cs.onSurfaceVariant),
                  SizedBox(height: 12.h),
                  Text('No interested users yet.',
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            itemCount: state.interestedUsers.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm.h),
            itemBuilder: (context, index) {
              final item = state.interestedUsers[index] as Map<String, dynamic>;
              return _UserCard(
                item: item,
                postId: widget.postId,
                isSubmitting: state.isSubmittingAction,
              );
            },
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String postId;
  final bool isSubmitting;

  const _UserCard({
    required this.item,
    required this.postId,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final user = item['user'] as Map<String, dynamic>? ?? item;
    final userId = item['userId']?.toString() ?? user['_id']?.toString() ?? '';
    final displayName =
        user['displayName']?.toString() ?? user['name']?.toString() ?? 'User';
    final avatarUrl = user['avatarUrl']?.toString();
    final status = item['status']?.toString() ?? 'INTERESTED';

    Color statusColor;
    switch (status) {
      case 'ACCEPTED':
        statusColor = Colors.green;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = cs.primary;
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Avatar(name: displayName, size: 44, imageUrl: avatarUrl),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(
                    status,
                    style: tt.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (status == 'INTERESTED') ...[
            SizedBox(width: 8.w),
            if (isSubmitting)
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              _ActionBtn(
                icon: IconsaxPlusLinear.tick_circle,
                color: Colors.green,
                onTap: () => context.read<PostsBloc>().add(
                      AcceptInterestRequested(
                        postId: postId,
                        targetUserId: userId,
                      ),
                    ),
              ),
              SizedBox(width: 8.w),
              _ActionBtn(
                icon: IconsaxPlusLinear.close_circle,
                color: Colors.red,
                onTap: () => context.read<PostsBloc>().add(
                      RejectInterestRequested(
                        postId: postId,
                        targetUserId: userId,
                      ),
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 36.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 18.w),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
      child: Container(
        height: 68.h,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }
}
