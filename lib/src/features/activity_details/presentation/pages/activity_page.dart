import 'package:area_connect/src/features/activity_details/presentation/widgets/review_participants_sheet.dart';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:area_connect/src/features/comment/presentation/pages/comment.dart';

class ActivityDetailScreen extends StatefulWidget {
  final AppPost post;

  const ActivityDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    final locationRes = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;
    locationRes.fold(
      (failure) => null,
      (position) => setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      }),
    );
  }

  void _centerOnActivity(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 14);
  }

  void _centerOnMe() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final currentUserId =
        context.select((SessionBloc bloc) => bloc.state.user?.id ?? '');

    return BlocBuilder<PostsBloc, PostsState>(
      builder: (context, state) {
        final livePost = state.posts.firstWhere(
          (p) => p.id == widget.post.id,
          orElse: () => widget.post,
        );

        final isInterested = livePost.isInterested;
        final interestedCount = livePost.interestedCount;
        final isMyPost = livePost.authorId == currentUserId;
        final isClosed =
            livePost.status == 'CLOSED' || livePost.status == 'EXPIRED';
        final isFull = livePost.status == 'FULL';

        final meta = livePost.parsedMeta;
        final String displayDescription =
            meta['description'] ?? livePost.content;
        final String displayDate =
            meta['date'] ?? 'Today, ${_formatDate(livePost.createdAt)}';
        final String displayTime = meta['time'] ?? '6:00 – 8:00 PM';
        final String displayLocation = meta['location'] ?? 'JLN Sports, V.N.';

        // Use real accepted count / maxParticipants if available
        final capacityLabel = livePost.maxParticipants != null
            ? '${livePost.acceptedParticipantsCount} / ${livePost.maxParticipants} joined'
            : (meta['capacity'] ?? '$interestedCount interested');

        final distanceLabel = livePost.distanceInMeters != null
            ? '${(livePost.distanceInMeters! / 1000).toStringAsFixed(1)} km away'
            : 'Within 5 km away';

        // Build event time label
        final eventTimeLabel = livePost.eventTime != null
            ? _formatEventTime(livePost.eventTime!)
            : displayTime;

        final items = [
          {'icon': IconsaxPlusLinear.calendar, 'label': displayDate},
          {'icon': IconsaxPlusLinear.clock, 'label': eventTimeLabel},
          {'icon': IconsaxPlusLinear.map_1, 'label': displayLocation},
          {'icon': IconsaxPlusLinear.user, 'label': capacityLabel},
        ];

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: const AppTopBar(
            title: 'Activity',
            centerTitle: true,
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
              ),
            ),
            child: isMyPost
                ? _buildOwnerBar(context, livePost, cs, state)
                : _buildUserBar(context, livePost, currentUserId, isInterested,
                    isClosed, isFull, cs),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Author row
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
                              distanceLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      _StatusBadge(status: livePost.status),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Category chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

                  const SizedBox(height: 12),

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
                    displayDescription,
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

                  /// Live Map / Map Placeholder Card
                  if (livePost.coordinates.length >= 2) ...[
                    SizedBox(
                      height: 180,
                      child: Stack(
                        children: [
                          AppMap(
                            center: LatLng(livePost.coordinates[1],
                                livePost.coordinates[0]),
                            controller: _mapController,
                            markers: [
                              // Activity Marker
                              Marker(
                                point: LatLng(livePost.coordinates[1],
                                    livePost.coordinates[0]),
                                width: 46,
                                height: 46,
                                child: _ActivityMarker(
                                  name: livePost.authorName,
                                  imageUrl: livePost.authorAvatar,
                                  color: theme.primaryColor,
                                ),
                              ),
                              // Current user marker (if location is available)
                              if (_userLocation != null)
                                Marker(
                                  point: _userLocation!,
                                  width: 44,
                                  height: 44,
                                  child: _MeMarker(color: cs.primary),
                                ),
                            ],
                            height: 180,
                          ),

                          /// Open in Map button (bottom left)
                          Positioned(
                            left: 10,
                            bottom: 10,
                            child: GestureDetector(
                              onTap: () => _openInMaps(livePost),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(IconsaxPlusLinear.location,
                                        size: 14, color: Colors.black87),
                                    SizedBox(width: 6),
                                    Text(
                                      'Open in map',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          /// Recenter / Center buttons (bottom right)
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Row(
                              children: [
                                if (_userLocation != null) ...[
                                  GestureDetector(
                                    onTap: _centerOnMe,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(IconsaxPlusLinear.user,
                                          size: 16, color: cs.primary),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                ],
                                GestureDetector(
                                  onTap: () => _centerOnActivity(
                                    livePost.coordinates[1],
                                    livePost.coordinates[0],
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      borderRadius: BorderRadius.circular(20.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(IconsaxPlusLinear.location,
                                            size: 14, color: Colors.white),
                                        SizedBox(width: 4.w),
                                        const Text(
                                          'Recenter',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: () => _openInMaps(livePost),
                      child: Container(
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
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(IconsaxPlusLinear.location, size: 14),
                                    SizedBox(width: 6),
                                    Text(
                                      'Open in map',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  /// Interested count
                  if (interestedCount > 0) ...[
                    Text(
                      '$interestedCount people interested',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 4),
                  Divider(color: cs.outlineVariant.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),

                  /// Comments
                  InkWell(
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            CommentsSheetScreen(postId: livePost.id),
                      );
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                      child: Row(
                        children: [
                          Icon(IconsaxPlusLinear.message,
                              color: theme.primaryColor, size: 20.sp),
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
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 12.sp, color: theme.primaryColor),
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

  Widget _buildOwnerBar(
    BuildContext context,
    AppPost livePost,
    ColorScheme cs,
    PostsState state,
  ) {
    final isClosed =
        livePost.status == 'CLOSED' || livePost.status == 'EXPIRED';
    final hasAccepted = livePost.acceptedParticipantsCount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.interestedUsers,
                    extra: {
                      'postId': livePost.id,
                      'postTitle': livePost.title,
                    },
                  ),
                  icon: const Icon(IconsaxPlusLinear.people, size: 18),
                  label: Text(
                    'Interested (${livePost.interestedCount})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
            if (!isClosed) ...[
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isSubmittingAction
                      ? null
                      : () => context.read<PostsBloc>().add(
                            ClosePostRequested(postId: livePost.id),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Close',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
        if (isClosed && hasAccepted) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showReviewPicker(context, livePost),
              icon: const Icon(Icons.star_outline_rounded, size: 18),
              label: const Text('Write Reviews',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black87,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserBar(
    BuildContext context,
    AppPost livePost,
    String currentUserId,
    bool isInterested,
    bool isClosed,
    bool isFull,
    ColorScheme cs,
  ) {
    final isDisabled = isClosed || isFull;
    final label = isClosed
        ? 'Activity Closed'
        : isFull
            ? 'Activity Full'
            : (isInterested ? "I'm In!" : "I'm Available");

    return Row(
      children: [
        _actionButton(
          icon: isInterested ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
          color: isInterested ? Colors.red : null,
          backgroundColor: cs.surfaceContainerLow,
          onTap: () {
            if (currentUserId.isNotEmpty && !isDisabled) {
              context.read<PostsBloc>().add(ToggleInterestRequested(
                    postId: livePost.id,
                    currentUserId: currentUserId,
                  ));
            }
          },
        ),
        const SizedBox(width: 12),
        _actionButton(
          icon: IconsaxPlusLinear.message,
          backgroundColor: cs.surfaceContainerLow,
          onTap: () {
            if (currentUserId.isNotEmpty) {
              context.read<ChatBloc>().add(StartDirectChatRequested(
                    recipientId: livePost.authorId,
                    recipientName: livePost.authorName,
                    currentUserId: currentUserId,
                    onSuccess: (chatId) {
                      if (context.mounted) {
                        context.push(
                          '/chat-room',
                          extra: {
                            'chatId': chatId,
                            'recipientName': livePost.authorName,
                            'recipientId': livePost.authorId,
                          },
                        );
                      }
                    },
                  ));
            }
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isDisabled || currentUserId.isEmpty
                  ? null
                  : () => context.read<PostsBloc>().add(
                        ToggleInterestRequested(
                          postId: livePost.id,
                          currentUserId: currentUserId,
                        ),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled
                    ? cs.surfaceContainerLow
                    : (isInterested ? const Color(0xFF2E7D32) : cs.primary),
                foregroundColor:
                    isDisabled ? cs.onSurfaceVariant : Colors.white,
                shape: const StadiumBorder(),
              ),
              child: Text(label),
            ),
          ),
        ),
      ],
    );
  }

  void _showReviewPicker(BuildContext context, AppPost livePost) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<PostsBloc>(),
        child: ReviewParticipantsSheet(postId: livePost.id),
      ),
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

  void _openInMaps(AppPost post) {
    // coordinates are stored as [lng, lat]
    if (post.coordinates.length < 2) {
      showGlobalToast(
          message: 'Location not available for this activity', status: 'info');
      return;
    }
    final lng = post.coordinates[0];
    final lat = post.coordinates[1];
    UrlLauncherService.instance
        .launch('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  }

  String _formatDate(DateTime date) {
    const months = [
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

  String _formatEventTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:$minute $period';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'FULL':
        color = Colors.orange;
        break;
      case 'CLOSED':
      case 'EXPIRED':
        color = Colors.grey;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActivityMarker extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final Color color;

  const _ActivityMarker({
    required this.name,
    this.imageUrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Avatar(name: name, size: 42, imageUrl: imageUrl),
    );
  }
}

class _MeMarker extends StatelessWidget {
  final Color color;

  const _MeMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        IconsaxPlusBold.user,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
