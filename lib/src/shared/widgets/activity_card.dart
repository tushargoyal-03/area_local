import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class ActivityCard extends StatelessWidget {
  final AppPost? post;
  final bool compact;
  final String who;
  final String title;
  final String tag;
  final String availability;
  final int interested;

  const ActivityCard({
    super.key,
    this.post,
    this.compact = false,
    this.who = 'Neighbor',
    this.title = 'Hyperlocal Activity',
    this.tag = 'General',
    this.availability = 'Today',
    this.interested = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    // Use dynamic post data if available, fallback to manual properties
    final cardWho = post?.authorName ?? who;
    final cardTitle = post?.title ?? title;
    final cardTag = post?.category ?? tag;
    final cardInterested = post?.interestedUsers.length ?? interested;
    final isInterested = post?.isInterested ?? false;
    final currentUserId =
        context.select((SessionBloc bloc) => bloc.state.user?.id ?? '');

    // HSL-derived harmonic styling
    final cardColor = cs.surfaceContainerLow;
    final isMyPost = post != null && post!.authorId == currentUserId;

    final Widget cardBody = Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.15),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name, Category Tag
          Row(
            children: [
              Avatar(
                name: cardWho,
                size: 40.w,
                imageUrl: post?.authorAvatar,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardWho,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          IconsaxPlusLinear.location,
                          size: 11.sp,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Within 5 km',
                          style: tt.bodySmall?.copyWith(
                            fontSize: 11.sp,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Text(
                  cardTag,
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Title
          Text(
            cardTitle,
            maxLines: compact ? 2 : 4,
            overflow: TextOverflow.ellipsis,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14.5.sp,
              height: 1.35,
              color: cs.onSurface,
            ),
          ),

          if (!compact) ...[
            SizedBox(height: 10.h),
            // Description if post is present
            if (post != null && post!.content.isNotEmpty) ...[
              Text(
                post!.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12.h),
            ],
            // Time and Area Info Chips
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                _miniChip(
                  context: context,
                  icon: IconsaxPlusLinear.calendar,
                  text: post != null
                      ? _formatDate(post!.createdAt)
                      : availability,
                ),
                _miniChip(
                  context: context,
                  icon: IconsaxPlusLinear.map_1,
                  text: 'Vaishali Nagar',
                ),
              ],
            ),
          ],

          SizedBox(height: 12.h),
          Divider(
            color: cs.outlineVariant.withValues(alpha: 0.15),
            height: 1.h,
          ),
          SizedBox(height: 10.h),

          // Action Row: Interested metric, Available Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _metaItem(
                    context: context,
                    icon: IconsaxPlusLinear.user,
                    text: '$cardInterested interested',
                  ),
                  SizedBox(width: 14.w),
                  _metaItem(
                    context: context,
                    icon: IconsaxPlusLinear.message,
                    text: post != null ? '${post!.commentsCount}' : '0',
                  ),
                ],
              ),
              if (post != null && !isMyPost)
                ElevatedButton(
                  onPressed: () {
                    if (currentUserId.isNotEmpty) {
                      context.read<PostsBloc>().add(ToggleInterestRequested(
                            postId: post!.id,
                            currentUserId: currentUserId,
                          ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInterested ? Colors.green : cs.primary,
                    foregroundColor: isInterested ? Colors.white : cs.onPrimary,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    minimumSize: Size(0, 36.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                  child: Text(
                    isInterested ? "I'm In" : "I'm Available",
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (post == null)
                // Static layout dummy button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    minimumSize: Size(0, 36.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                  child: Text(
                    "I'm Available",
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: const Duration(milliseconds: 200)).slideY(
        begin: 0.05, end: 0, duration: const Duration(milliseconds: 200));

    // If dynamic post is provided, tap triggers detail screen
    if (post != null) {
      return InkWell(
        onTap: () {
          context.push(AppRoutes.activity, extra: post);
        },
        borderRadius: BorderRadius.circular(24.r),
        child: cardBody,
      );
    }

    return cardBody;
  }

  Widget _miniChip({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    final cs = context.theme.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: cs.onSurfaceVariant),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    final cs = context.theme.colorScheme;
    return Row(
      children: [
        Icon(icon,
            size: 14.sp, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
