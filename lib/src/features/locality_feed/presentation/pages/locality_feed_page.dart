import 'package:area_connect/src/imports/imports.dart';

class LocalityFeedPage extends StatefulWidget {
  const LocalityFeedPage({super.key});

  @override
  State<LocalityFeedPage> createState() => _LocalityFeedPageState();
}

class _LocalityFeedPageState extends State<LocalityFeedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  // UI filter categories mapping to backend categories
  final List<String> _categories = [
    'For you',
    'Promotion',
    'Meetup',
    'Sports',
    'Need',
    'Request',
    'General'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadFeed();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.index != _selectedCategoryIndex) {
      setState(() {
        _selectedCategoryIndex = _tabController.index;
      });
      _loadFeed();
    }
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;

    final selectedCategory = _categories[_selectedCategoryIndex];
    String? type;
    String? category;

    if (selectedCategory == 'Promotion') {
      type = 'business';
    } else if (selectedCategory != 'For you') {
      category = selectedCategory;
    }

    context.read<PostsBloc>().add(LoadNearbyPostsRequested(
          type: type,
          category: category,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppTopBar(
        bottom: AppCapsuleTabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((cat) {
            IconData icon;
            if (cat == 'For you') {
              icon = IconsaxPlusLinear.star;
            } else if (cat == 'Promotion') {
              icon = IconsaxPlusLinear.ticket_discount;
            } else if (cat == 'Meetup') {
              icon = IconsaxPlusLinear.message;
            } else if (cat == 'Sports') {
              icon = IconsaxPlusLinear.flash;
            } else if (cat == 'Need') {
              icon = IconsaxPlusLinear.box;
            } else if (cat == 'Request') {
              icon = IconsaxPlusLinear.info_circle;
            } else {
              icon = IconsaxPlusLinear.element_3;
            }

            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(cat),
                ],
              ),
            );
          }).toList(),
        ),
        showbackbutton: false,
        title: 'Locality Feed',
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.savedOffers),
            icon: Icon(
              Icons.bookmark_border,
              color: cs.onSurface,
            ),
          ),
          IconButton(
            onPressed: _loadFeed,
            icon: Icon(
              IconsaxPlusLinear.refresh,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
      body:

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
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md.h),
                itemBuilder: (_, __) => const ActivityCard(),
              ),
            );
          }

          // Apply Category Filter locally as a fallback
          final selectedCategory = _categories[_selectedCategoryIndex];
          final filteredPosts = selectedCategory == 'For you'
              ? state.posts
              : state.posts.where((p) {
                  final type = p.postType.toLowerCase();
                  final cat = p.category.toLowerCase();
                  final filter = selectedCategory.toLowerCase();

                  if (filter == 'promotion') {
                    return type == 'business' || type == 'promotion';
                  }
                  if (filter == 'general') {
                    return cat == 'general' &&
                        type != 'business' &&
                        type != 'promotion';
                  }
                  return cat == filter;
                }).toList();

          if (filteredPosts.isEmpty) {
            return AppEmptyState(
              icon: IconsaxPlusLinear.location,
              title: 'No posts in $selectedCategory',
              subtitle: 'Be the first to create one inside this category!',
            );
          }

          return RefreshIndicator.adaptive(
            onRefresh: _loadFeed,
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: filteredPosts.length,
              shrinkWrap: true,
              separatorBuilder: (context, index) =>
                  SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                return ActivityCard(post: post);
              },
            ),
          );
        },
      ),
    );
  }
}
