import 'package:area_connect/src/imports/imports.dart';

class LocalityFeedPage extends StatefulWidget {
  const LocalityFeedPage({super.key});

  @override
  State<LocalityFeedPage> createState() => _LocalityFeedPageState();
}

class _LocalityFeedPageState extends State<LocalityFeedPage> {
  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;
    // Backend resolves location from stored coords — no GPS needed here
    context.read<PostsBloc>().add(const LoadNearbyPostsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return _LocalityFeedView(
      cs: cs,
      tt: tt,
      onRefresh: _loadFeed,
    );
  }
}

/* ================= UI INTEGRATION ================= */

class _LocalityFeedView extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final RefreshCallback onRefresh;

  const _LocalityFeedView({
    required this.cs,
    required this.tt,
    required this.onRefresh,
  });

  @override
  State<_LocalityFeedView> createState() => _LocalityFeedViewState();
}

class _LocalityFeedViewState extends State<_LocalityFeedView> {
  int _selectedCategoryIndex = 0;

  // UI filter categories mapping to backend categories
  final List<String> _categories = [
    'For you',
    'Society',
    'Advertisements',
    'Sports',
    'Meetups',
    'Needs',
    'General'
  ];

  String? _getBackendCategoryFilter(int index) {
    final cat = _categories[index];
    if (cat == 'For you') return null;
    if (cat == 'Society') return 'Society';
    if (cat == 'Advertisements') return 'Advertisement';
    if (cat == 'Sports') return 'Sports';
    if (cat == 'Meetups') return 'Meetup';
    if (cat == 'Needs') return 'Need';
    return 'General';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.cs.surface,
      appBar: AppTopBar(
        showbackbutton: false,
        title: '',
        titleWidget: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Icon(
                IconsaxPlusLinear.location,
                size: 11,
                color: widget.cs.primary,
              ),
              SizedBox(width: 3.w),
              Text(
                'Within 5 km',
                style: widget.tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.normal,
                  color: widget.cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          subtitle: Text(
            'Locality Feed',
            style: widget.tt.titleMedium?.copyWith(
              color: widget.cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: widget.onRefresh,
            icon: Icon(
              IconsaxPlusLinear.refresh,
              color: widget.cs.onSurface,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.sm.h),

              /// Horizontal Filter Chips
              SizedBox(
                height: 40.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedCategoryIndex;
                    final category = _categories[index];

                    return Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm.w),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: AppDurations.fast,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md.w,
                            vertical: AppSpacing.xs.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.cs.primary
                                : widget.cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(100.r),
                            border: Border.all(
                              color: isSelected
                                  ? widget.cs.primary
                                  : widget.cs.outlineVariant
                                      .withValues(alpha: 0.4),
                              width: 1.5.w,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            category,
                            style: widget.tt.bodyMedium?.copyWith(
                              color: isSelected
                                  ? widget.cs.onPrimary
                                  : widget.cs.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: AppSpacing.lg.h),

              /// Active posts by users nearby
              BlocBuilder<PostsBloc, PostsState>(
                builder: (context, state) {
                  if (state.isLoading && state.posts.isEmpty) {
                    return Skeletonizer(
                      enabled: true,
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 4,
                        shrinkWrap: true,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: AppSpacing.md.h),
                        itemBuilder: (_, __) => const ActivityCard(),
                      ),
                    );
                  }

                  if (state.posts.isEmpty) {
                    return const AppEmptyState(
                      icon: IconsaxPlusLinear.location,
                      title: 'No posts found',
                      subtitle:
                          'Try changing category or refresh to search again.',
                    );
                  }

                  // Apply Category Filter
                  final backendFilter =
                      _getBackendCategoryFilter(_selectedCategoryIndex);
                  final filteredPosts = backendFilter == null
                      ? state.posts
                      : state.posts
                          .where((p) =>
                              p.category.toLowerCase() ==
                              backendFilter.toLowerCase())
                          .toList();

                  if (filteredPosts.isEmpty) {
                    return AppEmptyState(
                      icon: IconsaxPlusLinear.location,
                      title: 'No posts in $backendFilter',
                      subtitle:
                          'Be the first to create one inside this category!',
                    );
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredPosts.length,
                    shrinkWrap: true,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: AppSpacing.md.h),
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      return ActivityCard(post: post);
                    },
                  );
                },
              ),

              SizedBox(height: AppSpacing.xxl.h),
            ],
          ),
        ),
      ),
    );
  }
}
