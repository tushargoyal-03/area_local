import 'dart:async';

import 'package:area_connect/src/features/nearby_discovery/presentation/providers/nearby_discovery_bloc.dart';
import 'package:area_connect/src/imports/imports.dart';
import 'package:area_connect/src/features/locality_feed/presentation/pages/locality_feed_page.dart';
import 'package:area_connect/src/features/home/presentation/screens/conversations_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with WidgetsBindingObserver {
  int _currentTab = 0;
  String _locationAddress = 'Vaishali Nagar, Jaipur';
  StreamSubscription<Position>? _locationSubscription;

  /// Fetch the current GPS position, update the address label, and sync
  /// coordinates to the backend.  Pass [showFeedback] = true only on the
  /// first explicit sync (init / login) — background updates are silent.
  Future<void> _syncLocation({bool showFeedback = false}) async {
    final locationRes = await LocationService.instance.getCurrentPosition();
    locationRes.fold(
      (failure) {
        if (showFeedback) {
          showGlobalToast(
            message:
                'Location issue: ${failure.message}. Using default location.',
            status: 'warning',
          );
        }
        debugPrint('Location sync failed: ${failure.message}');
      },
      (position) async {
        debugPrint(
            'Location synced: [${position.longitude}, ${position.latitude}]');

        // Reverse geocode to show a real suburb / city name in the header.
        final addressRes =
            await LocationService.instance.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        addressRes.fold(
          (failure) => debugPrint('Reverse geocode failed: ${failure.message}'),
          (address) {
            if (mounted) setState(() => _locationAddress = address);
          },
        );

        // Push to backend so all geo queries use fresh coords.
        final updateRes = await UsersService.instance.updateLocation(
          [position.longitude, position.latitude],
        );
        updateRes.fold(
          (failure) =>
              debugPrint('Backend location sync failed: ${failure.message}'),
          (_) => debugPrint('Backend location updated.'),
        );
      },
    );
  }

  /// Start a foreground position stream: fires whenever the user moves more
  /// than 100 m so the backend always has a fresh location while the app is
  /// open.  Updates are silent (no toasts).
  void _startLocationStream() {
    _locationSubscription =
        LocationService.instance.getPositionStream(distanceFilter: 100).listen(
      (position) async {
        debugPrint(
            'Position stream update: [${position.longitude}, ${position.latitude}]');
        final addressRes =
            await LocationService.instance.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        addressRes.fold(
          (_) {},
          (address) {
            if (mounted) setState(() => _locationAddress = address);
          },
        );
        UsersService.instance
            .updateLocation([position.longitude, position.latitude]);
      },
      onError: (Object error) =>
          debugPrint('Location stream error (ignored): $error'),
      cancelOnError: false,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.init();
    NotificationService.instance.requestPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sessionState = context.read<SessionBloc>().state;
      if (sessionState.status == SessionStatus.authenticated &&
          sessionState.user != null) {
        final user = sessionState.user!;
        _syncLocation(); // Initial silent sync on boot
        _startLocationStream(); // Keep updating as user moves
        context
            .read<ChatBloc>()
            .add(LoadConversationsRequested(currentUserId: user.id));
        Future.delayed(const Duration(seconds: 2), () {
          final socket = ChatService.instance.socket;
          if (socket != null) {
            NotificationService.instance.setupSocketListeners(socket, user.id);
            ChatService.instance.updatePresenceStatus(true);
          }
        });
      }

      // Pre-fetch nearby posts and neighbors — backend resolves location from stored coords
      context.read<PostsBloc>().add(const LoadNearbyPostsRequested());
      context.read<NearbyDiscoveryBloc>().add(const LoadNearbyNeighbors());
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ChatService.instance.updatePresenceStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final sessionState = context.read<SessionBloc>().state;
    if (sessionState.status == SessionStatus.authenticated &&
        sessionState.user != null) {
      if (state == AppLifecycleState.resumed) {
        // Foreground: update presence and re-sync location (user may have moved)
        ChatService.instance.updatePresenceStatus(true);
        _syncLocation();
      } else if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached ||
          state == AppLifecycleState.inactive) {
        ChatService.instance.updatePresenceStatus(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final List<Widget> tabs = [
      _HomeFeedTab(
        onExploreTap: () => setState(() => _currentTab = 1),
        locationAddress: _locationAddress,
      ),
      const LocalityFeedPage(),
      const ConversationsScreen(),
      const _ProfileSettingsTab(),
    ];

    return BlocListener<SessionBloc, SessionState>(
      listener: (context, sessionState) {
        if (sessionState.status == SessionStatus.authenticated &&
            sessionState.user != null) {
          final user = sessionState.user!;
          _syncLocation(); // Sync location after login (silent)
          _startLocationStream();
          // Wait for Socket to establish connect before binding listeners
          Future.delayed(const Duration(seconds: 2), () {
            final socket = ChatService.instance.socket;
            if (socket != null) {
              NotificationService.instance
                  .setupSocketListeners(socket, user.id);
              ChatService.instance.updatePresenceStatus(true);
            }
          });
        }
      },
      child: Scaffold(
        body: tabs[_currentTab],
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (index) => setState(() => _currentTab = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: cs.surface,
            selectedItemColor: cs.primary,
            unselectedItemColor: cs.onSurfaceVariant.withValues(alpha: 0.6),
            selectedLabelStyle: tt.bodySmall
                ?.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
            unselectedLabelStyle: tt.bodySmall?.copyWith(fontSize: 10),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(IconsaxPlusLinear.home),
                activeIcon: Icon(IconsaxPlusBold.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(IconsaxPlusLinear.location),
                activeIcon: Icon(IconsaxPlusBold.location),
                label: 'Discover',
              ),
              BottomNavigationBarItem(
                icon: Icon(IconsaxPlusLinear.message),
                activeIcon: Icon(IconsaxPlusBold.message),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(IconsaxPlusLinear.user),
                activeIcon: Icon(IconsaxPlusBold.user),
                label: 'Profile',
              ),
            ],
          ),
        ),
        floatingActionButton: _currentTab == 1
            ? FloatingActionButton(
                onPressed: () => context.push(AppRoutes.createActivity),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: CircleBorder(
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(IconsaxPlusLinear.add),
              )
            : null,
      ),
    );
  }
}

/* ================= HOME FEED TAB ================= */

class _HomeFeedTab extends StatelessWidget {
  final VoidCallback onExploreTap;
  final String locationAddress;

  const _HomeFeedTab(
      {required this.onExploreTap, required this.locationAddress});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final user = context.select((SessionBloc bloc) => bloc.state.user);

    return SafeArea(
      child: Column(
        children: [
          _TopBar(
            cs: cs,
            tt: tt,
            userName: user?.name ?? 'Resident',
            userRole: user?.role ?? 'User',
            onSearchTap: () => context.push(AppRoutes.searchUsers),
            onBellTap: () => context.push(AppRoutes.notification),
            locationAddress: locationAddress,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _HeroCard(onExploreTap: onExploreTap, tt: tt),
                  const SizedBox(height: 20),
                  _QuickActions(onExploreTap: onExploreTap),
                  const SizedBox(height: 20),
                  _TrendingSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String userName;
  final String userRole;
  final VoidCallback onSearchTap;
  final VoidCallback onBellTap;
  final String locationAddress;

  const _TopBar({
    required this.cs,
    required this.tt,
    required this.userName,
    required this.userRole,
    required this.onSearchTap,
    required this.onBellTap,
    required this.locationAddress,
  });

  String _formatRole(String role) {
    if (role == 'BusinessOwner') return 'Local Business Owner';
    if (role == 'SocietyAdmin') return 'Society Representative';
    return 'Resident';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Avatar(name: userName, size: 42, ring: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      IconsaxPlusLinear.location,
                      size: 11.sp,
                      color: cs.primary,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      locationAddress,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Hello, $userName',
                  style:
                      TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(
                    _formatRole(userRole),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSearchTap,
            icon: const Icon(IconsaxPlusLinear.search_normal),
          ),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final unreadCount =
                  state.notifications.where((n) => !n.isRead).length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onBellTap,
                    icon: const Icon(IconsaxPlusLinear.notification),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16.w,
                          minHeight: 16.w,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onExploreTap;
  final TextTheme tt;

  const _HeroCard({required this.onExploreTap, required this.tt});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      margin: EdgeInsets.all(AppSpacing.xs),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalettes.primaryLight, AppPalettes.primary2Light],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(IconsaxPlusLinear.flash, size: 12.sp, color: Colors.white),
                SizedBox(width: 4.w),
                Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Check out what neighbors are organizing within 5 km near you today!',
            style: tt.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.35,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<NearbyDiscoveryBloc, NearbyDiscoveryState>(
            builder: (context, state) {
              final avatars = state.neighbors.take(3).toList();

              return Row(
                children: [
                  ...avatars.map((n) {
                    final profile = n['profile'] ?? <String, dynamic>{};
                    final name = profile['displayName'] ?? 'Neighbor';
                    final avatarUrl = profile['avatarUrl'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Avatar(name: name, size: 28, imageUrl: avatarUrl),
                    );
                  }),
                  const Spacer(),
                  FilledButton(
                    onPressed: onExploreTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: cs.primary,
                      shape: const StadiumBorder(),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Explore Feed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onExploreTap;

  const _QuickActions({required this.onExploreTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final items = [
      ('Feed', IconsaxPlusLinear.flash, onExploreTap),
      (
        'Society',
        IconsaxPlusLinear.home_1,
        () => context.push(AppRoutes.societyFeed)
      ),
      (
        'Business',
        IconsaxPlusLinear.shop,
        () => context.push(AppRoutes.businessPromotions)
      ),
      (
        'Discovery',
        IconsaxPlusLinear.location,
        () => context.push(AppRoutes.nearbyDiscovery)
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: context.theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ).paddingSymmetric(horizontal: 16),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items
              .map(
                (e) => Column(
                  children: [
                    GestureDetector(
                      onTap: e.$3,
                      child: CircleAvatar(
                        backgroundColor: cs.primary.withValues(alpha: 0.1),
                        foregroundColor: cs.primary,
                        radius: 26,
                        child: Icon(e.$2, size: 24),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(e.$1,
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
              .toList(),
        ).paddingSymmetric(horizontal: 16),
      ],
    );
  }
}

class _TrendingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Trending Activities',
              style: context.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ).paddingSymmetric(horizontal: 16),
            const Spacer(),
            TextButton(
              onPressed: () {
                context.push(AppRoutes.localityFeed);
              },
              child: const Text('See All'),
            )
          ],
        ),
        const SizedBox(height: 10),
        BlocBuilder<PostsBloc, PostsState>(
          builder: (context, state) {
            if (state.isLoading && state.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.posts.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  'No activities nearby. Be the first to post!',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              );
            }

            final trendingPosts = state.posts.take(2).toList();
            return Column(
              children: trendingPosts.map((post) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: ActivityCard(post: post),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/* ================= PROFILE SETTINGS TAB ================= */

class _ProfileSettingsTab extends StatelessWidget {
  const _ProfileSettingsTab();

  String _formatRole(String role) {
    if (role == 'BusinessOwner') return 'Local Business Owner';
    if (role == 'SocietyAdmin') return 'Society Representative';
    return 'Resident';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final user = context.select((SessionBloc bloc) => bloc.state.user);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Avatar(
                name: user?.name ?? 'You',
                size: 90.w,
                imageUrl: user?.photoUrl),
            SizedBox(height: 16.h),
            Text(
              user?.name ?? 'Resident',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Text(
              user?.email ?? 'resident@neighborhood.com',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100.r),
              ),
              child: Text(
                _formatRole(user?.role ?? 'User'),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
            SizedBox(height: 32.h),

            // Profile Actions Card
            Material(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24.r),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _profileItem(
                    icon: IconsaxPlusLinear.profile_2user,
                    title: 'Personal Info',
                    cs: cs,
                    onTap: () => context.push(AppRoutes.editProfile),
                  ),
                  Divider(
                      color: cs.outlineVariant.withValues(alpha: 0.15),
                      height: 1),
                  _profileItem(
                    icon: IconsaxPlusLinear.shop,
                    title: 'Upgrade / Select Role',
                    cs: cs,
                    onTap: () {
                      context.push(AppRoutes.roleSelection);
                    },
                  ),
                  Divider(
                      color: cs.outlineVariant.withValues(alpha: 0.15),
                      height: 1),
                  _profileItem(
                    icon: IconsaxPlusLinear.notification,
                    title: 'Notification Settings',
                    cs: cs,
                    onTap: () => context.push(AppRoutes.notification),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Sign Out Button
            AppButton(
              label: 'Sign Out',
              variant: ButtonVariant.outline,
              onPressed: () {
                // Dispatch disconnect to clean socket.io connections
                context.read<ChatBloc>().add(const DisconnectChatRequested());
                context.read<SessionBloc>().add(const SessionLogoutRequested());
              },
              isFullWidth: true,
            ),
          ],
        ),
      ).paddingAll(AppSpacing.sm.w),
    );
  }

  Widget _profileItem({
    required IconData icon,
    required String title,
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface)),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 14.sp, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

/* ================= SHARED AVATAR ================= */

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final bool ring;
  final String? imageUrl;

  const Avatar({
    super.key,
    required this.name,
    this.size = 40,
    this.ring = false,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ring
            ? Border.all(
                color: cs.primary,
                width: 2,
              )
            : null,
      ),
      child: ClipOval(
        child: _buildContent(cs),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.toLowerCase().contains('.svg') ||
          imageUrl!.contains('dicebear.com/')) {
        return SvgPicture.network(
          imageUrl!,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _initials(cs),
        );
      }
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initials(cs),
      );
    }
    return _initials(cs);
  }

  Widget _initials(ColorScheme cs) {
    final initials = _getInitials(name);

    return Container(
      color: cs.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
          color: cs.primary,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return '?';

    final parts = cleanName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
