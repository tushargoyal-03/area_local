import 'package:area_connect/src/features/comment/presentation/pages/comment.dart';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return _HomeDashboardView(
      cs: cs,
      tt: tt,
      onSearchTap: () {},
      onBellTap: () {
        context.push(AppRoutes.notification);
      },
      onExploreTap: () {},
    );
  }
}

/* ================= UI ONLY ================= */

class _HomeDashboardView extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;

  final VoidCallback onSearchTap;
  final VoidCallback onBellTap;
  final VoidCallback onExploreTap;

  const _HomeDashboardView({
    required this.cs,
    required this.tt,
    required this.onSearchTap,
    required this.onBellTap,
    required this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
                cs: cs, tt: tt, onSearchTap: onSearchTap, onBellTap: onBellTap),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _HeroCard(onExploreTap: onExploreTap, tt: tt),
                    const SizedBox(height: 20),
                    _QuickActions(),
                    const SizedBox(height: 20),
                    _TrendingSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: const BottomNav(active: "home"),
    );
  }
}

class _TopBar extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onSearchTap;
  final VoidCallback onBellTap;

  const _TopBar({
    required this.cs,
    required this.tt,
    required this.onSearchTap,
    required this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Avatar(name: 'You', size: 40, ring: true),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 Vaishali Nagar, Jaipur',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('Hi, Aanya 👋',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            onPressed: onSearchTap,
            icon: const Icon(IconsaxPlusLinear.search_favorite),
          ),
          IconButton(
            onPressed: onBellTap,
            icon: const Icon(IconsaxPlusLinear.notification),
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
    final tt = context.theme.textTheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.purple, Colors.pink]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.xl)),
              label: Text(
                'Today',
                style: tt.bodyMedium?.copyWith(color: Colors.black),
              )),
          const SizedBox(height: 10),
          const Text(
            '12 neighbors are looking for activity partners near you',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Avatar(name: 'Riya', size: 28),
              const Avatar(name: 'Karan', size: 28),
              const Avatar(name: 'Meera', size: 28),
              const Spacer(),
              FilledButton(
                onPressed: onExploreTap,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.xl)),
                ),
                child: const Text('Explore'),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Activity', IconsaxPlusLinear.flash),
      ('Society', IconsaxPlusLinear.home_1),
      ('Offers', IconsaxPlusLinear.star),
      ('Nearby', IconsaxPlusLinear.location),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: context.theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.theme.colorScheme.onSurface),
        ).paddingSymmetric(horizontal: 16),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items
              .map(
                (e) => Column(
                  children: [
                    GestureDetector(
                        onTap: () {
                          if (e.$1 == 'Nearby') {
                            context.push(AppRoutes.nearbyDiscovery);
                          } else if (e.$1 == 'Activity') {
                            context.push(AppRoutes.activity);
                          } else if (e.$1 == 'Offers') {
                            // context.push(AppRoutes.offers);
                          } else if (e.$1 == 'Society') {
                            context.push(AppRoutes.societyFeed);
                          }
                        },
                        child: CircleAvatar(child: Icon(e.$2))),
                    const SizedBox(height: 5),
                    Text(e.$1, style: const TextStyle(fontSize: 11)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Trending Activities',
              style: context.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.theme.colorScheme.onSurface),
            ).paddingSymmetric(horizontal: 16),
            const Spacer(),
            TextButton(
                onPressed: () {
                  context.push(AppRoutes.localityFeed);
                },
                child: const Text('See All'))
          ],
        ),
        const SizedBox(height: 10),
        const ActivityCard(),
        const SizedBox(height: 10),
        const ActivityCard(
          who: 'Meera',
          title: 'Morning yoga in Central Park, 6:30 AM',
          tag: 'Wellness',
        ),
      ],
    );
  }
}

class ActivityCard extends StatelessWidget {
  final String who;
  final String title;
  final String tag;

  const ActivityCard({
    super.key,
    this.who = 'Riya Sharma',
    this.title = 'Need a pickleball partner 6PM - 8PM',
    this.tag = 'Sports',
  });

  @override
  Widget build(BuildContext context) {
    final tt = context.theme.textTheme;

    return InkWell(
      onTap: () {
        context.push(AppRoutes.activity);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: context.theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 5)
            ],
            border: Border.all(
                color: context.theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(name: who, size: 40),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(who,
                        style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: Colors.black))),
                Chip(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.xl)),
                    label: Text(tag,
                        style: tt.bodySmall?.copyWith(color: Colors.black))),
              ],
            ),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(IconsaxPlusLinear.heart, size: 18),
                const SizedBox(width: 5),
                const Text('24'),
                SizedBox(width: AppSpacing.md),
                InkWell(
                    onTap: () {
                      context.showAppBottomSheet<void>(
                        builder: (context) => const CommentsSheetScreen(),
                      );
                    },
                    child: const Icon(IconsaxPlusLinear.sms, size: 18)),
                const SizedBox(width: 5),
                const Text('24'),
                const Spacer(),
                FilledButton(
                    style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.xl))),
                    onPressed: () {},
                    child: const Text("I'm Available"))
              ],
            )
          ],
        ),
      ),
    );
  }
}

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
    // If image exists → show network image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initials(cs),
      );
    }

    // fallback → initials
    return _initials(cs);
  }

  Widget _initials(ColorScheme cs) {
    final initials = _getInitials(name);

    return Container(
      color: cs.surface.withValues(alpha: 0.50),
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
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
