import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class PromoCard extends StatefulWidget {
  final Map<String, dynamic> promo;
  final bool showAnalytics;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onAnalytics;

  const PromoCard({
    super.key,
    required this.promo,
    required this.showAnalytics,
    this.onTap,
    this.onSave,
    this.onAnalytics,
  });

  @override
  State<PromoCard> createState() => PromoCardState();
}

class PromoCardState extends State<PromoCard> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final mediaUrls = widget.promo['mediaUrls'] as List<dynamic>? ?? [];
    final hasImages = mediaUrls.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImages)
              Stack(
                children: [
                  SizedBox(
                    height: 200.h,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: mediaUrls.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: mediaUrls[index].toString(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => ColoredBox(
                            color: cs.surfaceContainerHighest,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => ColoredBox(
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.broken_image_rounded,
                                size: 40, color: cs.onSurfaceVariant),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 16.h,
                    left: 16.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_rounded,
                              size: 16, color: Colors.white),
                          SizedBox(width: 6.w),
                          Text(
                            widget.promo['businessName'] ?? 'Business',
                            style: tt.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (mediaUrls.length > 1)
                    Positioned(
                      bottom: 12.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: mediaUrls.length,
                          effect: WormEffect(
                            dotHeight: 6,
                            dotWidth: 6,
                            activeDotColor: cs.primary,
                            dotColor: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasImages) ...[
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(widget.promo['businessName'] ?? 'Business',
                          style: tt.labelSmall?.copyWith(color: cs.primary)),
                    ),
                    SizedBox(height: 12.h),
                  ],
                  Text(
                    widget.promo['title'] ?? 'Promotion',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.promo['description'] ?? '',
                    style: tt.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.promo['discountCode'] != null &&
                      widget.promo['discountCode'].toString().isNotEmpty) ...[
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: cs.secondary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Code:',
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSecondaryContainer)),
                          Text(
                            widget.promo['discountCode'],
                            style: tt.titleMedium?.copyWith(
                                color: cs.secondary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      if (!widget.showAnalytics && widget.onSave != null)
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: widget.onSave,
                            icon: Icon(
                                widget.promo['isSaved'] == true
                                    ? Icons.bookmark
                                    : Icons.bookmark_outline,
                                size: 20),
                            label: Text(widget.promo['isSaved'] == true
                                ? 'Saved'
                                : 'Save Offer'),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r)),
                              backgroundColor: widget.promo['isSaved'] == true
                                  ? cs.primary
                                  : null,
                              foregroundColor: widget.promo['isSaved'] == true
                                  ? cs.onPrimary
                                  : null,
                            ),
                          ),
                        ),
                      if (widget.showAnalytics && widget.onAnalytics != null)
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: widget.onAnalytics,
                            icon: const Icon(Icons.bar_chart_rounded, size: 20),
                            label: const Text('View Analytics'),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
