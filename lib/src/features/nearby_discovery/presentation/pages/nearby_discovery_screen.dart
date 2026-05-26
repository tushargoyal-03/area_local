import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import '../providers/nearby_discovery_bloc.dart';

class NearbyDiscoveryScreen extends StatefulWidget {
  const NearbyDiscoveryScreen({super.key});

  @override
  State<NearbyDiscoveryScreen> createState() => _NearbyDiscoveryScreenState();
}

class _NearbyDiscoveryScreenState extends State<NearbyDiscoveryScreen> {
  final List<String> _tabs = [
    'People',
    'Activities',
    'Business',
    'Events',
    'Society'
  ];
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadNeighbors();
  }

  Future<void> _loadNeighbors() async {
    final locationRes = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;
    locationRes.fold(
      (failure) {
        // Fallback to New Delhi coordinates if Geolocator fails/permission denied
        context.read<NearbyDiscoveryBloc>().add(
              const LoadNearbyNeighbors(lng: 77.2090, lat: 28.6139),
            );
      },
      (position) {
        context.read<NearbyDiscoveryBloc>().add(
              LoadNearbyNeighbors(
                lng: position.longitude,
                lat: position.latitude,
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Text(
              'Vaishali Nagar · 2 km radius',
              style: tt.bodySmall?.copyWith(
                fontSize: 11.sp,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12.w),
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              IconsaxPlusLinear.filter,
              size: 18.sp,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// Filter Chips
          SizedBox(
            height: 44.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => _activeTabIndex = index),
                  child: _ChipItem(
                    label: _tabs[index],
                    active: _activeTabIndex == index,
                    cs: cs,
                    tt: tt,
                  ),
                );
              },
            ),
          ),

          /// Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
              children: [
                /// Map / Discovery Card
                Container(
                  height: 160.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.r),
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.2),
                        AppPalettes.primary2Light.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [

                      /// Center Button
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: ElevatedButton.icon(
                          onPressed: () {},
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

                SizedBox(height: 14.h),

                /// People List via Bloc
                BlocBuilder<NearbyDiscoveryBloc, NearbyDiscoveryState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.error != null) {
                      return Center(child: Text(state.error!));
                    }
                    if (state.neighbors.isEmpty) {
                      return const Center(
                          child: Text('No neighbors found nearby.'));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              IconsaxPlusLinear.trend_up,
                              size: 16.sp,
                              color: cs.primary,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${state.neighbors.length} active nearby right now',
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        ...List.generate(state.neighbors.length, (i) {
                          final neighbor = state.neighbors[i];
                          final profile =
                              neighbor['profile'] ?? <String, dynamic>{};
                          final name = profile['displayName'] ?? 'Neighbor';
                          final dist = neighbor['distanceInMeters'] ?? 0.0;

                          // Defaulting to general interest if parsing fails
                          String interest = 'connecting';
                          if (profile['lookingFor'] != null &&
                              (profile['lookingFor'] as List).isNotEmpty) {
                            interest = profile['lookingFor'].join(', ');
                          }

                          return _NearbyCard(
                            userId: neighbor['userId'] ?? '',
                            name: name,
                            distance: (dist / 1000.0).toStringAsFixed(1),
                            interest: interest,
                            cs: cs,
                            tt: tt,
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
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

class _ChipItem extends StatelessWidget {
  final String label;
  final bool active;
  final ColorScheme cs;
  final TextTheme tt;

  const _ChipItem({
    required this.label,
    required this.active,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: active
            ? cs.primary.withValues(alpha: 0.12)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: tt.labelMedium?.copyWith(
          fontSize: 12.sp,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? cs.primary : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
