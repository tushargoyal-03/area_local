import 'package:area_connect/src/imports/imports.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  final List<String> categories = [
    'Sports',
    'Events',
    'Help',
    'Hobbies',
    'General',
  ];

  int selectedIndex = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _mapToBackendCategory(String uiCategory) {
    if (uiCategory == 'Events') return 'Meetup';
    if (uiCategory == 'Help') return 'Request';
    if (uiCategory == 'Hobbies') return 'Need';
    return uiCategory;
  }

  Future<void> _handlePost() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final uiCategory = categories[selectedIndex];
    final backendCategory = _mapToBackendCategory(uiCategory);

    final locationRes = await LocationService.instance.getCurrentPosition();

    final coordinates = locationRes.fold(
      (failure) => const [77.5946, 12.9716],
      (position) => [position.longitude, position.latitude],
    );

    if (mounted) {
      context.read<PostsBloc>().add(
            CreatePostRequested(
              context: context,
              category: backendCategory,
              title: title,
              content: content,
              coordinates: coordinates,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final isCreating = context.select((PostsBloc bloc) => bloc.state.isCreating);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leadingWidth: 60,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New activity',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg.w, AppSpacing.sm.h, AppSpacing.lg.w, AppSpacing.xxl.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      categories.length,
                      (index) {
                        final selected = selectedIndex == index;
                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => selectedIndex = index),
                            child: AnimatedContainer(
                              duration: AppDurations.fast,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: selected
                                    ? cs.primary
                                    : cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(100.r),
                                border: Border.all(
                                  color: selected
                                      ? cs.primary
                                      : cs.outlineVariant
                                          .withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                categories[index],
                                style: tt.labelLarge?.copyWith(
                                  color: selected
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.lg.h),

                // Title section
                const _SectionLabel('Title'),
                SizedBox(height: AppSpacing.sm.h),
                TextFormField(
                  controller: _titleController,
                  enabled: !isCreating,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Need a pickleball partner...',
                    hintStyle: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: 2,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (v.trim().length > 80) return 'Title is too long';
                    return null;
                  },
                ),

                SizedBox(height: AppSpacing.lg.h),

                // Description section
                const _SectionLabel('Description'),
                SizedBox(height: AppSpacing.sm.h),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: EdgeInsets.all(AppSpacing.md.w),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  child: TextFormField(
                    controller: _contentController,
                    enabled: !isCreating,
                    maxLines: 5,
                    style: tt.bodyMedium,
                    decoration: InputDecoration(
                      hintText:
                          'Describe details, skill level, date/time, and exact location...',
                      hintStyle: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                ),

                SizedBox(height: AppSpacing.lg.h),

                // Meta details
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 2.7,
                  children: const [
                    _FormRow(
                      icon: IconsaxPlusLinear.calendar,
                      label: 'Today, May 20',
                    ),
                    _FormRow(
                      icon: IconsaxPlusLinear.clock,
                      label: '6:00 – 8:00 PM',
                    ),
                    _FormRow(
                      icon: IconsaxPlusLinear.map,
                      label: 'JLN Sports, V.N.',
                    ),
                    _FormRow(
                      icon: IconsaxPlusLinear.user,
                      label: '2 people',
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.lg.h),

                // Photo upload
                Container(
                  height: 110.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconsaxPlusLinear.camera,
                        size: 28.sp,
                        color: cs.onSurfaceVariant,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Add a photo (optional)',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.xl.h),

                // Post button
                AppButton(
                  label: 'Post Activity',
                  isLoading: isCreating,
                  onPressed: isCreating ? null : _handlePost,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ─── Section Label ─────────────────────────────────────────────────── */

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11.sp,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

/* ─── Form Row ──────────────────────────────────────────────────────── */

class _FormRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FormRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              size: 17.sp,
              color: cs.primary,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

