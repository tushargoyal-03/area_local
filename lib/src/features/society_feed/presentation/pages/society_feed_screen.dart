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

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Dynamically fetch the user's societies and load the first one's feed
    context.read<SocietyFeedBloc>().add(const InitSocietyFeed());
  }

  void _onCategoryTapped(int index) {
    setState(() => _selectedCategoryIndex = index);
    final category = _categories[index];
    final societyId = context.read<SocietyFeedBloc>().state.societyId;
    if (societyId.isNotEmpty) {
      context
          .read<SocietyFeedBloc>()
          .add(LoadSocietyFeed(societyId, type: category));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppTopBar(
        title: '',
        titleWidget: AnimatedSwitcher(
          duration: AppDurations.medium,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _isSearching
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: TextField(
                    key: const ValueKey('searchField'),
                    controller: _searchController,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Search in society...',
                      hintStyle: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                )
              : BlocBuilder<SocietyFeedBloc, SocietyFeedState>(
                  key: const ValueKey('societyTitle'),
                  buildWhen: (prev, curr) =>
                      prev.societyName != curr.societyName,
                  builder: (context, feedState) {
                    final name = feedState.societyName.isNotEmpty
                        ? feedState.societyName
                        : 'Society';
                    final initial =
                        name.isNotEmpty ? name[0].toUpperCase() : 'S';
                    return Row(
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
                            initial,
                            style: tt.titleMedium?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            name,
                            style: tt.bodyLarge?.copyWith(
                              color: cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          BlocBuilder<SessionBloc, SessionState>(
            builder: (context, sessionState) {
              if (sessionState.user?.role == 'SocietyAdmin') {
                return Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm.w),
                  child: CircleAvatar(
                    radius: 20.r,
                    backgroundColor: cs.surfaceContainerLow,
                    child: IconButton(
                      tooltip: 'Join requests',
                      onPressed: () {
                        final societyId =
                            context.read<SocietyFeedBloc>().state.societyId;
                        if (societyId.isNotEmpty) {
                          context.push('/society-requests/$societyId');
                        } else {
                          showGlobalToast(
                            message:
                                'Create your society first to manage join requests.',
                            status: 'info',
                          );
                        }
                      },
                      icon: Icon(
                        IconsaxPlusLinear.profile_2user,
                        size: 18.w,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg.w),
            child: CircleAvatar(
              radius: 20.r,
              backgroundColor: cs.surfaceContainerLow,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                    }
                  });
                },
                icon: Icon(
                  _isSearching ? Icons.close : IconsaxPlusLinear.search_normal,
                  size: 18.w,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<SocietyFeedBloc, SocietyFeedState>(
        buildWhen: (prev, curr) =>
            prev.hasNoSociety != curr.hasNoSociety ||
            prev.isLoading != curr.isLoading,
        builder: (context, feedState) {
          if (feedState.hasNoSociety) {
            return _buildNoSocietyState(context, cs, tt);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.md.h),

              /// Quick Action Grid (Notice, Issue, Poll, SOS)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(
                      label: 'Notice',
                      icon: IconsaxPlusLinear.volume_high,
                      colors: [Colors.lightBlueAccent, Colors.indigo],
                      onTap: () => _showCreatePostSheet(context, 'Notice'),
                    ),
                    _buildQuickAction(
                      label: 'Issue',
                      icon: IconsaxPlusLinear.warning_2,
                      colors: [Colors.redAccent, Colors.orangeAccent],
                      onTap: () => _showCreatePostSheet(context, 'Complaint'),
                    ),
                    _buildQuickAction(
                      label: 'Poll',
                      icon: IconsaxPlusLinear.ranking,
                      colors: [Colors.greenAccent, Colors.teal],
                      onTap: () => _showCreatePollSheet(context),
                    ),
                    _buildQuickAction(
                      label: 'Event',
                      icon: IconsaxPlusLinear.calendar_1,
                      colors: [Colors.amberAccent, Colors.deepOrange],
                      onTap: () => _showCreateEventSheet(context),
                    ),
                    _buildQuickAction(
                      label: 'SOS',
                      icon: IconsaxPlusLinear.shield_security,
                      colors: [Colors.purpleAccent, Colors.deepPurple],
                      onTap: () => _showCreatePostSheet(context, 'Alert'),
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
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
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
                            color: isSelected
                                ? cs.primary
                                : cs.surfaceContainerLow,
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
                              color: isSelected
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
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
                      padding: EdgeInsets.all(AppSpacing.xs.w),
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
          );
        },
      ),
    );
  }

  Widget _buildNoSocietyState(
      BuildContext context, ColorScheme cs, TextTheme tt) {
    final isAdmin =
        context.select((SessionBloc b) => b.state.user?.role == 'SocietyAdmin');

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(IconsaxPlusLinear.home_1, size: 40.w, color: cs.primary),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Text(
              isAdmin ? 'Create your society' : 'No society yet',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(
              isAdmin
                  ? 'You are registered as a Society Representative. Set up your society so residents nearby can discover and join it.'
                  : 'Join a society to see notices, polls, events, and complaints from your neighborhood.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.xl.h),
            if (isAdmin)
              AppButton(
                label: 'Create Society',
                onPressed: () => context.push(AppRoutes.createSociety),
                isFullWidth: true,
              )
            else
              AppButton(
                label: 'Discover Societies',
                onPressed: () => context.push(AppRoutes.nearbyDiscovery),
                isFullWidth: true,
              ),
            SizedBox(height: AppSpacing.md.h),
            TextButton(
              onPressed: () =>
                  context.read<SocietyFeedBloc>().add(const InitSocietyFeed()),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context, String type) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final societyId = context.read<SocietyFeedBloc>().state.societyId;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<SocietyFeedBloc>(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
              decoration: BoxDecoration(
                color: context.theme.colorScheme.surface,
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
                        color: context.theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'New $type',
                    style: context.theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  AppTextField(controller: titleCtrl, hint: 'Title'),
                  SizedBox(height: 12.h),
                  AppTextField(
                      controller: contentCtrl, hint: 'Details…', maxLines: 2),
                  SizedBox(height: 20.h),
                  BlocBuilder<SocietyFeedBloc, SocietyFeedState>(
                    builder: (context, state) => SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: state.isCreating
                            ? null
                            : () {
                                if (titleCtrl.text.isNotEmpty &&
                                    societyId.isNotEmpty) {
                                  context
                                      .read<SocietyFeedBloc>()
                                      .add(CreateSocietyPostRequested(
                                        societyId: societyId,
                                        type: type,
                                        title: titleCtrl.text,
                                        content: contentCtrl.text,
                                        onSuccess: () => Navigator.pop(ctx),
                                      ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.theme.colorScheme.primary,
                          foregroundColor: context.theme.colorScheme.onPrimary,
                          shape: const StadiumBorder(),
                        ),
                        child: state.isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Post',
                                style: TextStyle(fontWeight: FontWeight.w600)),
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

  void _showCreateEventSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final societyId = context.read<SocietyFeedBloc>().state.societyId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<SocietyFeedBloc>(),
          child: StatefulBuilder(
            builder: (ctx2, setModalState) {
              final cs = ctx2.theme.colorScheme;
              final tt = ctx2.theme.textTheme;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx2).viewInsets.bottom,
                ),
                child: Container(
                  padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28.r)),
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
                      Text('New Event',
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 16.h),
                      AppTextField(controller: titleCtrl, hint: 'Event title'),
                      SizedBox(height: 12.h),
                      AppTextField(
                          controller: contentCtrl,
                          hint: 'Details…',
                          maxLines: 2),
                      SizedBox(height: 12.h),
                      InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx2,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(IconsaxPlusLinear.calendar,
                                  size: 18.w, color: cs.primary),
                              SizedBox(width: 10.w),
                              Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: tt.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text('Change',
                                  style: tt.bodySmall
                                      ?.copyWith(color: cs.primary)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      BlocBuilder<SocietyFeedBloc, SocietyFeedState>(
                        builder: (context, state) => SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: ElevatedButton(
                            onPressed: state.isCreating
                                ? null
                                : () {
                                    if (titleCtrl.text.isNotEmpty &&
                                        societyId.isNotEmpty) {
                                      context
                                          .read<SocietyFeedBloc>()
                                          .add(CreateSocietyPostRequested(
                                            societyId: societyId,
                                            type: 'Event',
                                            title: titleCtrl.text,
                                            content: contentCtrl.text,
                                            eventDate: selectedDate
                                                .toUtc()
                                                .toIso8601String(),
                                            onSuccess: () => Navigator.pop(ctx),
                                          ));
                                    } else {
                                      showGlobalToast(
                                          message: 'Event title is required',
                                          status: 'error');
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              shape: const StadiumBorder(),
                            ),
                            child: state.isCreating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Create Event',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCreatePollSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final optionCtrls = [
      TextEditingController(),
      TextEditingController(),
    ];
    final societyId = context.read<SocietyFeedBloc>().state.societyId;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<SocietyFeedBloc>(),
          child: StatefulBuilder(
            builder: (ctx2, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx2).viewInsets.bottom,
                ),
                child: Container(
                  padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                  decoration: BoxDecoration(
                    color: context.theme.colorScheme.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28.r)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: context.theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Create Poll',
                          style: context.theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16.h),
                        AppTextField(controller: titleCtrl, hint: 'Question'),
                        SizedBox(height: 12.h),
                        AppTextField(
                            controller: contentCtrl,
                            hint: 'Description (optional)'),
                        SizedBox(height: 16.h),
                        Text('Options',
                            style: context.theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        SizedBox(height: 8.h),
                        ...List.generate(
                          optionCtrls.length,
                          (i) => Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: optionCtrls[i],
                                    hint: 'Option ${i + 1}',
                                  ),
                                ),
                                if (i >= 2)
                                  IconButton(
                                    onPressed: () => setModalState(
                                        () => optionCtrls.removeAt(i)),
                                    icon: Icon(Icons.remove_circle_outline,
                                        color: Colors.red.shade400),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (optionCtrls.length < 6)
                          TextButton.icon(
                            onPressed: () => setModalState(
                                () => optionCtrls.add(TextEditingController())),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Option'),
                          ),
                        SizedBox(height: 12.h),
                        BlocBuilder<SocietyFeedBloc, SocietyFeedState>(
                          builder: (context, state) => SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: ElevatedButton(
                              onPressed: state.isCreating
                                  ? null
                                  : () {
                                      final opts = optionCtrls
                                          .map((c) => c.text.trim())
                                          .where((t) => t.isNotEmpty)
                                          .toList();
                                      if (titleCtrl.text.isNotEmpty &&
                                          opts.length >= 2) {
                                        context
                                            .read<SocietyFeedBloc>()
                                            .add(CreatePollRequested(
                                              societyId: societyId,
                                              title: titleCtrl.text,
                                              content: contentCtrl.text,
                                              options: opts,
                                              onSuccess: () =>
                                                  Navigator.pop(ctx),
                                            ));
                                      } else {
                                        showGlobalToast(
                                            message:
                                                'Need a question and at least 2 options',
                                            status: 'error');
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    context.theme.colorScheme.primary,
                                foregroundColor:
                                    context.theme.colorScheme.onPrimary,
                                shape: const StadiumBorder(),
                              ),
                              child: state.isCreating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Create Poll',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
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
                  GestureDetector(
                    onTap: () {
                      if (type == 'complaint') {
                        context
                            .read<SocietyFeedBloc>()
                            .add(UpvoteComplaint(postId: post.id));
                      } else if (type != 'poll') {
                        context
                            .read<SocietyFeedBloc>()
                            .add(LikePost(postId: post.id));
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          type == 'poll'
                              ? IconsaxPlusLinear.box_1
                              : (type == 'complaint'
                                  ? IconsaxPlusLinear.arrow_up_1
                                  : IconsaxPlusLinear.like_1),
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
