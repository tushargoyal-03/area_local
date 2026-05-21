import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class LocalityFeedPage extends StatefulWidget {
  const LocalityFeedPage({super.key});

  @override
  State<LocalityFeedPage> createState() => _LocalityFeedPageState();
}

class _LocalityFeedPageState extends State<LocalityFeedPage> {
  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return _LocalityFeedView(
      cs: cs,
      tt: tt,
    );
  }
}

/* ================= UI ONLY ================= */

class _LocalityFeedView extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;

  const _LocalityFeedView({required this.cs, required this.tt});

  @override
  State<_LocalityFeedView> createState() => _LocalityFeedViewState();
}

class _LocalityFeedViewState extends State<_LocalityFeedView> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'For you',
    'Sports',
    'Wellness',
    'Social',
    'Offers'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.cs.surface,
      appBar: AppBar(
        backgroundColor: widget.cs.surface,
        elevation: 0,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            '📍 Within 2 km',
            style: widget.tt.bodySmall?.copyWith(
              fontWeight: FontWeight.normal,
              color: widget.cs.onSurfaceVariant,
            ),
          ),
          subtitle: Text(
            'Locality',
            style: widget.tt.titleMedium?.copyWith(
              color: widget.cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              IconsaxPlusLinear.search_normal,
              color: widget.cs.onSurface,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.sm.h),

            /// Toggle Switches (Horizontal Filter Chips)
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
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: widget.cs.primary
                                        .withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          category,
                          style: widget.tt.bodyMedium?.copyWith(
                            color: isSelected
                                ? widget.cs.onPrimary
                                : widget.cs.onSurfaceVariant,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
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
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 10,
              shrinkWrap: true,
              separatorBuilder: (context, index) =>
                  SizedBox(height: AppSpacing.md.h),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    context.push(AppRoutes.activity);
                  },
                  child: const ActivityCard(
                    title:
                        'Need a pickleball partner from 6PM – 8PM in Vaishali Nagar',
                    tag: 'Viral',
                    who: 'Rajesh',
                  ),
                );
              },
            ),

            SizedBox(height: AppSpacing.xxl.h),
          ],
        ),
      ),
    );
  }
}
