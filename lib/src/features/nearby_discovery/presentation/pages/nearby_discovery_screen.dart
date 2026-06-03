import 'dart:math' as math;

import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import '../providers/nearby_discovery_bloc.dart';
import 'package:area_connect/src/features/business/presentation/providers/business_bloc.dart';
import 'package:area_connect/src/features/nearby_discovery/presentation/widgets/society_discover_list.dart';

class NearbyDiscoveryScreen extends StatefulWidget {
  const NearbyDiscoveryScreen({super.key});

  @override
  State<NearbyDiscoveryScreen> createState() => _NearbyDiscoveryScreenState();
}

class _NearbyDiscoveryScreenState extends State<NearbyDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _tabs = [
    'People',
    'Activities',
    'Business',
    'Events',
    'Society'
  ];
  int _activeTabIndex = 0;
  late TabController _tabController;

  /// Map center, defaults to the New Delhi fallback location.
  LatLng _center = const LatLng(28.6139, 77.2090);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadNeighbors();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.index != _activeTabIndex) {
      setState(() {
        _activeTabIndex = _tabController.index;
      });
    }
  }

  Future<void> _loadNeighbors() async {
    // GPS is used only to center the map — API calls use backend-stored location
    final locationRes = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;
    locationRes.fold(
      (failure) => setState(() => _center = const LatLng(28.6139, 77.2090)),
      (position) => setState(
          () => _center = LatLng(position.latitude, position.longitude)),
    );

    context.read<NearbyDiscoveryBloc>().add(const LoadNearbyNeighbors());
    context.read<PostsBloc>().add(const LoadNearbyPostsRequested());
    context.read<BusinessBloc>().add(const LoadNearbyPromotions());
  }

  /// Recenters the map camera on the current [_center].
  void _centerOnMe() {
    _mapController.move(_center, _mapController.camera.zoom);
  }

  /// Builds all markers for the map: the current user ("you are here") plus
  /// each nearby neighbor.
  ///
  /// The backend's `users/nearby` payload only carries `distanceInKm` (no
  /// coordinates), so neighbors are placed around [_center] at their reported
  /// distance using an evenly distributed bearing. If a neighbor ever does
  /// carry real coordinates, those are used instead.
  List<Marker> _buildMarkers(NearbyDiscoveryState state) {
    final markers = <Marker>[
      // Current user marker.
      Marker(
        point: _center,
        width: 44,
        height: 44,
        child: _MeMarker(color: context.theme.colorScheme.primary),
      ),
    ];

    final neighbors = state.neighbors;
    for (var i = 0; i < neighbors.length; i++) {
      final neighbor = neighbors[i];
      final point = _resolveNeighborPoint(neighbor, i, neighbors.length);
      if (point == null) continue;

      final name =
          (neighbor is Map ? neighbor['displayName'] : null) ?? 'Neighbor';
      final avatarUrl =
          neighbor is Map ? neighbor['avatarUrl'] as String? : null;

      markers.add(
        Marker(
          point: point,
          width: 46,
          height: 46,
          child: _NeighborMarker(
            name: name.toString(),
            imageUrl: avatarUrl,
          ),
        ),
      );
    }
    return markers;
  }

  /// Resolves a neighbor's map position.
  ///
  /// Prefers real coordinates when present; otherwise distributes the neighbor
  /// around [_center] at its `distanceInKm` using an evenly spaced bearing.
  LatLng? _resolveNeighborPoint(dynamic neighbor, int index, int total) {
    final real = _parseCoordinates(neighbor);
    if (real != null) return real;

    if (neighbor is! Map) return null;

    final distanceRaw = neighbor['distanceInKm'];
    final distanceKm = distanceRaw is num ? distanceRaw.toDouble() : 0.0;
    if (!distanceKm.isFinite) return null;

    // Spread neighbors evenly around a circle; nudge a zero distance outward a
    // little so co-located neighbors don't all stack on the user pin.
    final effectiveKm = distanceKm <= 0 ? 0.15 : distanceKm;
    final bearing = total <= 0 ? 0.0 : (2 * math.pi * index) / total;

    return _offset(_center, effectiveKm, bearing);
  }

  /// Returns a [LatLng] offset from [origin] by [distanceKm] along [bearingRad].
  LatLng _offset(LatLng origin, double distanceKm, double bearingRad) {
    const earthRadiusKm = 6371.0;
    final angular = distanceKm / earthRadiusKm;
    final lat1 = origin.latitudeInRad;
    final lng1 = origin.longitudeInRad;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angular) +
          math.cos(lat1) * math.sin(angular) * math.cos(bearingRad),
    );
    final lng2 = lng1 +
        math.atan2(
          math.sin(bearingRad) * math.sin(angular) * math.cos(lat1),
          math.cos(angular) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(_radToDeg(lat2), _radToDeg(lng2));
  }

  double _radToDeg(double rad) => rad * 180.0 / math.pi;

  /// Defensively extracts a [LatLng] from a neighbor map, or null if absent.
  LatLng? _parseCoordinates(dynamic neighbor) {
    if (neighbor is! Map) return null;

    double? toFinite(dynamic value) {
      final n = value is num ? value.toDouble() : null;
      if (n == null || !n.isFinite) return null;
      return n;
    }

    // Shape 1: location.coordinates == [lng, lat]
    final location = neighbor['location'];
    if (location is Map) {
      final coordinates = location['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        final lng = toFinite(coordinates[0]);
        final lat = toFinite(coordinates[1]);
        if (lng != null && lat != null) return LatLng(lat, lng);
      }
    }

    // Shape 2: top-level lng/lat
    final lng = toFinite(neighbor['lng']);
    final lat = toFinite(neighbor['lat']);
    if (lng != null && lat != null) return LatLng(lat, lng);

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      appBar: AppTopBar(
        title: '',
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
          ],
        ),
        bottom: AppCapsuleTabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) {
            IconData icon;
            if (tab == 'People') {
              icon = IconsaxPlusLinear.profile_2user;
            } else if (tab == 'Activities') {
              icon = IconsaxPlusLinear.flash;
            } else if (tab == 'Business') {
              icon = IconsaxPlusLinear.shop;
            } else if (tab == 'Events') {
              icon = IconsaxPlusLinear.calendar;
            } else if (tab == 'Society') {
              icon = IconsaxPlusLinear.home_1;
            } else {
              icon = IconsaxPlusLinear.element_3;
            }

            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(tab),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          /// Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.xs.w),
              children: [
                /// Map / Discovery Card
                SizedBox(
                  height: 160.h,
                  child: Stack(
                    children: [
                      BlocBuilder<NearbyDiscoveryBloc, NearbyDiscoveryState>(
                        builder: (context, state) {
                          return AppMap(
                            center: _center,
                            controller: _mapController,
                            markers: _buildMarkers(state),
                            height: 160.h,
                          );
                        },
                      ),

                      /// Center Button
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: ElevatedButton.icon(
                          onPressed: _centerOnMe,
                          icon:
                              const Icon(IconsaxPlusLinear.location, size: 14),
                          label: const Text(
                            'Center on me',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 14.h),

                /// People List via Bloc
                if (_activeTabIndex == 0) _buildPeopleList(cs, tt),

                if (_activeTabIndex == 1) _buildActivitiesList(cs, tt),

                if (_activeTabIndex == 2) _buildBusinessList(cs, tt),

                if (_activeTabIndex == 3) _buildEventsList(cs, tt),

                if (_activeTabIndex == 4) _buildSocietyList(cs, tt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleList(ColorScheme cs, TextTheme tt) {
    return BlocBuilder<NearbyDiscoveryBloc, NearbyDiscoveryState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) return Center(child: Text(state.error!));
        if (state.neighbors.isEmpty) {
          return const Center(child: Text('No neighbors found nearby.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(IconsaxPlusLinear.trend_up,
                    size: 16.sp, color: cs.primary),
                SizedBox(width: 6.w),
                Text('${state.neighbors.length} active nearby right now',
                    style:
                        tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 14.h),
            ...List.generate(state.neighbors.length, (i) {
              final item = state.neighbors[i];
              if (item is! Map) {
                return const SizedBox.shrink();
              }
              final neighbor = Map<String, dynamic>.from(item);
              final name = neighbor['displayName']?.toString() ?? 'Neighbor';
              final dist = neighbor['distanceInKm'] ?? 0.0;

              String interest = 'connecting';
              final lookingFor = neighbor['lookingFor'];
              if (lookingFor is List && lookingFor.isNotEmpty) {
                interest = lookingFor
                    .map((e) => e?.toString() ?? '')
                    .where((e) => e.isNotEmpty)
                    .join(', ');
                if (interest.isEmpty) {
                  interest = 'connecting';
                }
              }

              return _NearbyCard(
                userId: neighbor['userId']?.toString() ?? '',
                name: name,
                distance:
                    dist is num ? dist.toStringAsFixed(1) : dist.toString(),
                interest: interest,
                cs: cs,
                tt: tt,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildActivitiesList(ColorScheme cs, TextTheme tt) {
    return BlocBuilder<PostsBloc, PostsState>(
      builder: (context, state) {
        if (state.isLoading && state.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.posts.isEmpty) {
          return const Center(child: Text('No nearby activities found.'));
        }

        return Column(
          children: state.posts.map((post) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: ActivityCard(post: post),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBusinessList(ColorScheme cs, TextTheme tt) {
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, state) {
        if (state.isLoadingNearby) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.nearbyPromotions.isEmpty) {
          return const Center(child: Text('No nearby business promotions.'));
        }

        return Column(
          children: state.nearbyPromotions.map((promo) {
            if (promo is! Map) return const SizedBox.shrink();
            promo = Map<String, dynamic>.from(promo);
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(AppSpacing.md.w),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16.r),
                border:
                    Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promo['businessName'] ?? 'Business',
                      style: tt.labelSmall?.copyWith(color: cs.primary)),
                  SizedBox(height: 4.h),
                  Text(promo['title'] ?? 'Promotion',
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Text(promo['description'] ?? '',
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEventsList(ColorScheme cs, TextTheme tt) {
    return BlocBuilder<PostsBloc, PostsState>(
      builder: (context, state) {
        if (state.isLoading && state.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Events are nearby activities with a scheduled event time, soonest first.
        final events = state.posts.where((p) => p.eventTime != null).toList()
          ..sort((a, b) => a.eventTime!.compareTo(b.eventTime!));

        if (events.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 24.h),
            child: Center(
              child: Text('No upcoming events nearby.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(IconsaxPlusLinear.calendar,
                    size: 16.sp, color: cs.primary),
                SizedBox(width: 6.w),
                Text('${events.length} upcoming nearby',
                    style:
                        tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 14.h),
            ...events.map((post) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: ActivityCard(post: post),
                )),
          ],
        );
      },
    );
  }

  Widget _buildSocietyList(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Discover verified societies nearby + request to join.
        SocietyDiscoverList(
          lat: _center.latitude,
          lng: _center.longitude,
        ),
        SizedBox(height: 20.h),
        Divider(color: cs.outlineVariant.withValues(alpha: 0.3)),
        SizedBox(height: 12.h),
        Text('My societies',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: 12.h),
        _buildMySocietiesList(cs, tt),
      ],
    );
  }

  Widget _buildMySocietiesList(ColorScheme cs, TextTheme tt) {
    return FutureBuilder(
      future: SocietiesService.instance.getMySocieties(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final societies = snapshot.data?.fold<List<dynamic>>(
              (_) => <dynamic>[],
              (list) => list,
            ) ??
            <dynamic>[];

        if (societies.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
            child: Column(
              children: [
                Text("You haven't joined any societies yet.",
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                SizedBox(height: 12.h),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.societyFeed),
                  icon: const Icon(IconsaxPlusLinear.arrow_right_3, size: 16),
                  label: const Text('Open Society Hub'),
                ),
              ],
            ),
          ).center;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: societies.map((raw) {
            final society =
                raw is Map<String, dynamic> ? raw : <String, dynamic>{};
            final name = society['name']?.toString() ?? 'Society';
            final address = society['address']?.toString() ??
                society['city']?.toString() ??
                '';
            final isVerified = society['isVerified'] == true;

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20.r),
                border:
                    Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                leading: CircleAvatar(
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Icon(IconsaxPlusLinear.home_1, color: cs.primary),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          style: tt.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isVerified) ...[
                      SizedBox(width: 6.w),
                      Icon(Icons.verified, size: 16.w, color: cs.primary),
                    ],
                  ],
                ),
                subtitle: address.isEmpty
                    ? null
                    : Text(address,
                        style:
                            tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant),
                onTap: () => context.push(AppRoutes.societyFeed),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final String userId;
  final String name;
  final String distance;
  final String interest;
  final ColorScheme cs;
  final TextTheme tt;

  const _NearbyCard({
    required this.userId,
    required this.name,
    required this.distance,
    required this.interest,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Avatar(name: name, size: 48),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      IconsaxPlusLinear.map,
                      size: 12.sp,
                      color: cs.onSurfaceVariant,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        '$distance km · Looking for $interest',
                        style: tt.bodySmall?.copyWith(
                          fontSize: 11.sp,
                          color: cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<NearbyDiscoveryBloc>().add(SayHiToNeighbor(userId));
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 8.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            child: Text(
              'Say hi',
              style: TextStyle(fontSize: 11.sp),
            ),
          ),
        ],
      ),
    );
  }
}

/// "You are here" marker for the current user.
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

/// Marker representing a nearby neighbor, showing their avatar.
class _NeighborMarker extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _NeighborMarker({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cs.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Avatar(name: name, size: 42, imageUrl: imageUrl),
    );
  }
}
