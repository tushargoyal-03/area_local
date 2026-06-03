import 'dart:io';
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

    // Parse dynamic post meta
    final meta = post != null ? post!.parsedMeta : <String, String>{};
    final String displayDescription =
        meta['description'] ?? (post?.content ?? '');
    final String displayDate = meta['date'] ?? availability;
    final String displayLocation = meta['location'] ?? 'Vaishali Nagar';

    if (post?.postType == 'promotion') {
      final promoMap = {
        '_id': post!.id,
        'businessName': post!.businessName ?? post!.authorName,
        'title': post!.title,
        'description': post!.content,
        'discountCode': post!.discountCode,
        'mediaUrls': post!.mediaUrls,
        'isInterested': post!.isInterested,
        'isSaved': post!.isSaved,
      };

      return PromoCard(
        promo: promoMap,
        showAnalytics: false,
        onTap: () {
          context.push(AppRoutes.activity, extra: post);
        },
        onSave: () {
          if (currentUserId.isNotEmpty) {
            context.read<PostsBloc>().add(ToggleInterestRequested(
                  postId: post!.id,
                  currentUserId: currentUserId,
                ));
            showGlobalToast(
                message: post!.isSaved
                    ? 'Offer removed from saved'
                    : 'Offer saved successfully!',
                status: 'success');
          }
        },
      ).animate().fade(duration: const Duration(milliseconds: 200)).slideY(
          begin: 0.05, end: 0, duration: const Duration(milliseconds: 200));
    }

    // HSL-derived harmonic styling
    final cardColor = cs.surfaceContainerLow;
    final isMyPost = post != null && post!.authorId == currentUserId;

    final isAd = post != null &&
        (post!.authorRole == 'BusinessOwner' ||
            post!.category.toLowerCase() == 'advertisement' ||
            post!.category.toLowerCase() == 'promotion');

    final Widget cardBody;

    if (isAd) {
      // Business/Shop Advertisement Card Layout
      cardBody = Container(
        padding: EdgeInsets.all(AppSpacing.md.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Shop avatar, Shop Name, Sponsored badge
            Row(
              children: [
                Avatar(
                  name: cardWho,
                  size: 42.w,
                  imageUrl: post?.authorAvatar,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cardWho,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5.sp,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Text(
                              'SPONSORED',
                              style: tt.labelSmall?.copyWith(
                                color: cs.primary,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
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
                            post?.distanceInMeters != null
                                ? 'Within ${(post!.distanceInMeters! / 1000).toStringAsFixed(1)} km'
                                : 'Vaishali Nagar',
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
              ],
            ),

            SizedBox(height: 12.h),

            // Ad Title / Offer Headline
            Text(
              cardTitle,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15.sp,
                height: 1.3,
                color: cs.onSurface,
              ),
            ),

            if (!compact) ...[
              SizedBox(height: 8.h),
              // Ad Description
              if (displayDescription.isNotEmpty) ...[
                Text(
                  displayDescription,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 13.sp,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              // Big Ad Cover Image/Banner
              FeedImagePreview(
                imageUrl: post != null && post!.mediaUrls.isNotEmpty
                    ? post!.mediaUrls.first
                    : 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?q=80&w=600',
                height: 165.h,
                borderRadius: BorderRadius.circular(18.r),
              ),
              SizedBox(height: 12.h),

              // Offer Expiry details or location
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  _miniChip(
                    context: context,
                    icon: IconsaxPlusLinear.shop,
                    text: 'Exclusive Deal',
                  ),
                  _miniChip(
                    context: context,
                    icon: IconsaxPlusLinear.location,
                    text: displayLocation,
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

            // Footer Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _metaItem(
                      context: context,
                      icon: IconsaxPlusLinear.user,
                      text: '$cardInterested claimed',
                    ),
                    SizedBox(width: 14.w),
                    _metaItem(
                      context: context,
                      icon: IconsaxPlusLinear.message,
                      text: post != null ? '${post!.commentsCount}' : '0',
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (post != null && currentUserId.isNotEmpty) {
                      context.read<PostsBloc>().add(ToggleInterestRequested(
                            postId: post!.id,
                            currentUserId: currentUserId,
                          ));
                    }
                  },
                  icon: Icon(
                    isInterested
                        ? Icons.check_circle_rounded
                        : IconsaxPlusLinear.ticket_discount,
                    size: 15.sp,
                  ),
                  label: Text(
                    isInterested ? 'Claimed' : 'Claim Offer',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                ),
              ],
            ),
          ],
        ),
      ).animate().fade(duration: const Duration(milliseconds: 200)).slideY(
          begin: 0.05, end: 0, duration: const Duration(milliseconds: 200));
    } else {
      // Standard Resident Activity Card
      cardBody = Container(
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
                            post?.distanceInMeters != null
                                ? 'Within ${(post!.distanceInMeters! / 1000).toStringAsFixed(1)} km'
                                : 'Nearby',
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
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
              if (post != null && displayDescription.isNotEmpty) ...[
                Text(
                  displayDescription,
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

              // Standard Post Image Preview
              if (post != null && post!.mediaUrls.isNotEmpty) ...[
                FeedImagePreview(
                  imageUrl: post!.mediaUrls.first,
                  height: 145.h,
                  borderRadius: BorderRadius.circular(16.r),
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
                    text: displayDate,
                  ),
                  _miniChip(
                    context: context,
                    icon: IconsaxPlusLinear.map_1,
                    text: displayLocation,
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
                      foregroundColor:
                          isInterested ? Colors.white : cs.onPrimary,
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
    }

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
}

class FeedImagePreview extends StatelessWidget {
  final String imageUrl;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const FeedImagePreview({
    super.key,
    required this.imageUrl,
    this.height = 160.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final isLocal = imageUrl.startsWith('/') ||
        imageUrl.startsWith('file://') ||
        !imageUrl.startsWith('http');

    Widget imageWidget;
    if (isLocal) {
      final cleanPath = imageUrl.replaceFirst('file://', '');
      final file = File(cleanPath);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: fit,
          width: double.infinity,
          height: height,
        );
      } else {
        imageWidget = _buildErrorWidget(context);
      }
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: double.infinity,
        height: height,
        placeholder: (context, url) => Skeletonizer(
          enabled: true,
          child: Container(
            width: double.infinity,
            height: height,
            color: cs.surfaceContainerHigh,
          ),
        ),
        errorWidget: (context, url, error) => _buildErrorWidget(context),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: imageWidget,
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.surfaceContainerHigh,
            cs.surfaceContainerLow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconsaxPlusLinear.image,
            size: 32.sp,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          SizedBox(height: 8.h),
          Text(
            'Image unavailable',
            style: TextStyle(
              fontSize: 11.sp,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
