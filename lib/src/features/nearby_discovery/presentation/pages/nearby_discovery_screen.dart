import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class NearbyDiscoveryScreen extends StatelessWidget {
  const NearbyDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final people = ['Riya Sharma', 'Karan Singh', 'Meera Patel', 'Dev Arora'];
    final interests = ['pickleball', 'gym buddy', 'yoga', 'cycling'];

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
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: [
                _ChipItem(label: 'People', active: true, cs: cs, tt: tt),
                _ChipItem(label: 'Activities', active: false, cs: cs, tt: tt),
                _ChipItem(label: 'Business', active: false, cs: cs, tt: tt),
                _ChipItem(label: 'Events', active: false, cs: cs, tt: tt),
                _ChipItem(label: 'Society', active: false, cs: cs, tt: tt),
              ],
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
                      ...[
                        {'left': 0.34, 'top': 0.22, 'name': 'Riya'},
                        {'left': 0.60, 'top': 0.45, 'name': 'K'},
                        {'left': 0.25, 'top': 0.60, 'name': 'M'},
                        {'left': 0.75, 'top': 0.70, 'name': 'D'},
                      ].map(
                        (p) => Positioned(
                          left: MediaQuery.of(context).size.width *
                              (p['left'] as double) *
                              0.85,
                          top: 160.h * (p['top'] as double),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 8,
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (p['name'] as String)[0],
                                    style: tt.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cs.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// Center Button
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(IconsaxPlusLinear.location, size: 14),
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

                /// Active count
                Row(
                  children: [
                    Icon(
                      IconsaxPlusLinear.trend_up,
                      size: 16.sp,
                      color: cs.primary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '14 active nearby right now',
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 14.h),

                /// People List
                ...List.generate(people.length, (i) {
                  return _NearbyCard(
                    name: people[i],
                    index: i,
                    interest: interests[i],
                    cs: cs,
                    tt: tt,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final String name;
  final int index;
  final String interest;
  final ColorScheme cs;
  final TextTheme tt;

  const _NearbyCard({
    required this.name,
    required this.index,
    required this.interest,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final distance = (0.2 + index * 0.3).toStringAsFixed(1);

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
            onPressed: () {},
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
