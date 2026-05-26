import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:area_connect/src/features/comment/presentation/pages/comment.dart';
class ActivityDetailScreen extends StatelessWidget {
  final AppPost post;

  const ActivityDetailScreen({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final currentUserId =
        context.select((SessionBloc bloc) => bloc.state.user?.id ?? '');

    return BlocBuilder<PostsBloc, PostsState>(
      builder: (context, state) {
        // Find the latest post representation from Bloc state to support reactive UI changes (e.g. liked status)
        final livePost = state.posts.firstWhere(
          (p) => p.id == post.id,
          orElse: () => post,
        );

        final isInterested = livePost.isInterested;
        final interestedCount = livePost.interestedUsers.length;
        final isMyPost = livePost.authorId == currentUserId;

        final items = [
          {
            'icon': IconsaxPlusLinear.calendar,
            'label': 'Today, ${_formatDate(livePost.createdAt)}',
          },
          {
            'icon': IconsaxPlusLinear.clock,
            'label': '6:00 – 8:00 PM',
          },
          {
            'icon': IconsaxPlusLinear.map_1,
            'label': 'JLN Sports, V.N.',
          },
          {
            'icon': IconsaxPlusLinear.user,
            'label': '${livePost.interestedUsers.length} interested',
          },
        ];

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            title: const Text('Activity'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (isMyPost)
                IconButton(
                  onPressed: () {
                    context
                        .read<PostsBloc>()
                        .add(DeletePostRequested(postId: livePost.id));
                    Navigator.pop(context);
                  },
                  icon: const Icon(IconsaxPlusLinear.trash, color: Colors.red),
                ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                _actionButton(
                  icon: isInterested
                      ? IconsaxPlusBold.heart
                      : IconsaxPlusLinear.heart,
                  color: isInterested ? Colors.red : null,
                  backgroundColor: cs.surfaceContainerLow,
                  onTap: () {
                    if (currentUserId.isNotEmpty) {
                      context.read<PostsBloc>().add(ToggleInterestRequested(
                            postId: livePost.id,
                            currentUserId: currentUserId,
                          ));
                    }
                  },
                ),
                const SizedBox(width: 12),
                // Message Author button (only if not my own post)
                if (!isMyPost) ...[
                  _actionButton(
                    icon: IconsaxPlusLinear.message,
                    backgroundColor: cs.surfaceContainerLow,
                    onTap: () {
                      if (currentUserId.isNotEmpty) {
                        context.read<ChatBloc>().add(StartDirectChatRequested(
                              context: context,
                              recipientId: livePost.authorId,
                              recipientName: livePost.authorName,
                              currentUserId: currentUserId,
                            ));
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (currentUserId.isNotEmpty) {
                          context.read<PostsBloc>().add(ToggleInterestRequested(
                                postId: livePost.id,
                                currentUserId: currentUserId,
                              ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isInterested ? const Color(0xFF2E7D32) : cs.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(isInterested ? "I'm In!" : "I'm Available"),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// User Info
                  Row(
                    children: [
                      Avatar(
                        name: livePost.authorName,
                        size: 48,
                        ring: true,
                        imageUrl: livePost.authorAvatar,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              livePost.authorName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Within 5 km away',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          livePost.category,
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Title
                  Text(
                    livePost.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Description
                  Text(
                    livePost.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Info Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.4,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                size: 18,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  /// Map Placeholder Card
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.25),
                          AppPalettes.primary2Light.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 14,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  IconsaxPlusLinear.location,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Open in map',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Interested Users
                  if (interestedCount > 0) ...[
                    Text(
                      '$interestedCount people interested',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(
                          interestedCount > 3 ? 3 : interestedCount, (index) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: CircleAvatar(
                            radius: 18,
                            child: Text(
                              (livePost.interestedUsers[index].isNotEmpty)
                                  ? livePost.interestedUsers[index][0]
                                      .toUpperCase()
                                  : 'N',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Divider(color: cs.outlineVariant.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),

                  /// Comments Section
                  InkWell(
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CommentsSheetScreen(postId: livePost.id),
                      );
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                      child: Row(
                        children: [
                          Icon(
                            IconsaxPlusLinear.message,
                            color: theme.primaryColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Comments (${livePost.commentsCount})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'View all',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12.sp,
                            color: theme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required IconData icon,
    Color? color,
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: color),
      ),
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
