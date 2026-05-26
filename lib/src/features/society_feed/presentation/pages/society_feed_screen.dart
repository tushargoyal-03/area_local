import 'package:area_connect/src/features/society_feed/domain/entities/society_post.dart';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import '../providers/society_feed_bloc.dart';

class SocietyFeedScreen extends StatefulWidget {
  const SocietyFeedScreen({super.key});

  @override
  State<SocietyFeedScreen> createState() => _SocietyFeedScreenState();
}

class _SocietyFeedScreenState extends State<SocietyFeedScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'All',
    'Notices',
    'Complaints',
    'Polls',
    'Events'
  ];

  @override
  void initState() {
    super.initState();
    // Assuming society ID is known or passed. For demo, we use a mock one.
    // In a real app, this might come from User profile `session_bloc`
    context
        .read<SocietyFeedBloc>()
        .add(const LoadSocietyFeed('mock_society_id_123', type: 'All'));
  }

  void _onCategoryTapped(int index) {
    setState(() => _selectedCategoryIndex = index);
    final category = _categories[index];
    context
        .read<SocietyFeedBloc>()
        .add(LoadSocietyFeed('mock_society_id_123', type: category));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppTopBar(
        title: '',
        titleWidget: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, AppPalettes.primary2Light],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Text(
                'G',
                style: tt.titleMedium?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Greenwood Heights',
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '824 residents · Block A',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg.w),
            child: CircleAvatar(
              radius: 20.r,
              backgroundColor: cs.surfaceContainerLow,
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  IconsaxPlusLinear.search_normal,
                  size: 18.w,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.md.h),

          /// Quick Action Grid (Notice, Issue, Poll, SOS)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction(
                  label: 'Notice',
                  icon: IconsaxPlusLinear.volume_high,
                  colors: [Colors.lightBlueAccent, Colors.indigo],
                  onTap: () {},
                ),
                _buildQuickAction(
                  label: 'Issue',
                  icon: IconsaxPlusLinear.warning_2,
                  colors: [Colors.redAccent, Colors.orangeAccent],
                  onTap: () {},
                ),
                _buildQuickAction(
                  label: 'Poll',
                  icon: IconsaxPlusLinear.ranking,
                  colors: [Colors.greenAccent, Colors.teal],
                  onTap: () {},
                ),
                _buildQuickAction(
                  label: 'SOS',
                  icon: IconsaxPlusLinear.shield_security,
                  colors: [Colors.purpleAccent, Colors.deepPurple],
                  onTap: () {},
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.lg.h),

          /// Tab/Filter chips
          SizedBox(
            height: 38.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedCategoryIndex;
                final category = _categories[index];

                return Padding(
                  padding: EdgeInsets.only(right: AppSpacing.xs.w),
                  child: GestureDetector(
                    onTap: () => _onCategoryTapped(index),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md.w,
                        vertical: AppSpacing.xs.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primary : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(100.r),
                        border: Border.all(
                          color: isSelected
                              ? cs.primary
                              : cs.outlineVariant.withValues(alpha: 0.4),
                          width: 1.w,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category,
                        style: tt.bodyMedium?.copyWith(
                          color:
                              isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: AppSpacing.md.h),

          /// Divider line
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),

          /// Society Posts List
          Expanded(
            child: BlocBuilder<SocietyFeedBloc, SocietyFeedState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null) {
                  return Center(child: Text(state.error!));
                }

                if (state.posts.isEmpty) {
                  return const Center(child: Text('No posts found.'));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(AppSpacing.lg.w),
                  itemCount: state.posts.length,
                  itemBuilder: (context, index) {
                    final post = state.posts[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                      child: _buildSocietyPost(
                        post: post,
                        cs: cs,
                        tt: tt,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    final tt = context.theme.textTheme;
    final cs = context.theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: colors[1].withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.w,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocietyPost({
    required SocietyPost post,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    final type = post.type;
    final String label =
        type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : '';

    IconData icon = IconsaxPlusLinear.message;
    List<Color> gradientColors = [Colors.blue, Colors.blueAccent];

    if (type == 'notice') {
      icon = IconsaxPlusLinear.volume_high;
      gradientColors = [Colors.lightBlueAccent, Colors.indigo];
    } else if (type == 'complaint') {
      icon = IconsaxPlusLinear.warning_2;
      gradientColors = [Colors.redAccent, Colors.orangeAccent];
    } else if (type == 'poll') {
      icon = IconsaxPlusLinear.ranking;
      gradientColors = [Colors.greenAccent, Colors.teal];
    } else if (type == 'event') {
      icon = IconsaxPlusLinear.calendar_1;
      gradientColors = [Colors.purpleAccent, Colors.deepPurple];
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Top Row
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16.w,
                ),
              ),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: gradientColors[1].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: Text(
                            label,
                            style: tt.bodySmall?.copyWith(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: gradientColors[1],
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs.w),
                        Text(
                          _formatTime(post.createdAt),
                          style: tt.bodySmall?.copyWith(
                            fontSize: 10.sp,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      post.authorName,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.md.h),

          /// Title
          Text(
            post.title,
            style: tt.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              height: 1.3,
            ),
          ),

          /// Body (optional)
          if (post.content != null && post.content!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              post.content!,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 12.5.sp,
                height: 1.4,
              ),
            ),
          ],

          /// Poll Option Section
          if (type == 'poll' && post.pollOptions != null) ...[
            SizedBox(height: AppSpacing.md.h),
            _buildPollSection(post, cs, tt),
          ],

          SizedBox(height: AppSpacing.md.h),

          Divider(
            color: cs.outlineVariant.withValues(alpha: 0.15),
            height: 1.h,
          ),

          SizedBox(height: AppSpacing.sm.h),

          /// Bottom Reply/Like row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    IconsaxPlusLinear.message,
                    size: 14.w,
                    color: cs.onSurfaceVariant,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${post.commentsCount} replies',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  Icon(
                    type == 'poll'
                        ? IconsaxPlusLinear.box_1
                        : IconsaxPlusLinear.like_1,
                    size: 14.w,
                    color: cs.onSurfaceVariant,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    type == 'poll'
                        ? '${post.totalVotes ?? 0} votes cast'
                        : '${post.likesCount}',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 14.w,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollSection(SocietyPost post, ColorScheme cs, TextTheme tt) {
    final options = post.pollOptions!;
    final total = post.totalVotes ?? 0;
    final votedIndex = post.userVotedOptionIndex;

    return Column(
      children: List.generate(options.length, (index) {
        final opt = options[index];
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
          child: _buildPollOption(
            post: post,
            label: opt.text,
            votes: opt.votes,
            total: total,
            index: index,
            isSelected: votedIndex == index,
            hasVoted: votedIndex != null,
            cs: cs,
            tt: tt,
          ),
        );
      }),
    );
  }

  Widget _buildPollOption({
    required SocietyPost post,
    required String label,
    required int votes,
    required int total,
    required int index,
    required bool isSelected,
    required bool hasVoted,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    final double percent = total > 0 ? (votes / total) : 0;
    final int percentInt = (percent * 100).round();

    return GestureDetector(
      onTap: () {
        if (!hasVoted) {
          context
              .read<SocietyFeedBloc>()
              .add(VotePoll(postId: post.id, optionIndex: index));
        }
      },
      child: Container(
        height: 38.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? cs.primary : Colors.transparent,
            width: 1.w,
          ),
        ),
        child: Stack(
          children: [
            // Filled part
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: AppDurations.medium,
                  height: double.infinity,
                  width: constraints.maxWidth * percent,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.18)
                        : cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                );
              },
            ),
            // Text & percentage part
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: cs.onSurface,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    '$percentInt%',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays == 1) return 'Yest';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}
