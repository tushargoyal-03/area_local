import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import '../providers/business_bloc.dart';

class BusinessPromotionsScreen extends StatefulWidget {
  const BusinessPromotionsScreen({super.key});

  @override
  State<BusinessPromotionsScreen> createState() =>
      _BusinessPromotionsScreenState();
}

class _BusinessPromotionsScreenState extends State<BusinessPromotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTab) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    context.read<BusinessBloc>().add(const LoadNearbyPromotions());
    context.read<BusinessBloc>().add(LoadMyPromotions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context
        .select((SessionBloc b) => b.state.user?.role == 'BusinessOwner');

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Business Promotions',
        centerTitle: true,
      ),
      floatingActionButton: (isOwner && _currentTab == 1)
          ? FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: () => context.push(AppRoutes.createPromotion),
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (isOwner)
              AppCapsuleTabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Nearby'),
                  Tab(text: 'My Promotions'),
                ],
              ),
            Expanded(
              child: isOwner
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _NearbyPromotionsList(),
                        _MyPromotionsList(),
                      ],
                    )
                  : _NearbyPromotionsList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyPromotionsList extends StatefulWidget {
  @override
  State<_NearbyPromotionsList> createState() => _NearbyPromotionsListState();
}

class _NearbyPromotionsListState extends State<_NearbyPromotionsList> {
  final Set<String> _tracked = {};

  void _trackImpression(String promoId) {
    if (_tracked.contains(promoId)) return;
    _tracked.add(promoId);
    BusinessService.instance.trackEvent(promoId, 'IMPRESSION');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, state) {
        if (state.isLoadingNearby) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.nearbyPromotions.isEmpty) {
          return Center(child: Text(state.error!));
        }
        if (state.nearbyPromotions.isEmpty) {
          return const Center(child: Text('No nearby promotions'));
        }

        return ListView.separated(
          padding: EdgeInsets.all(AppSpacing.xs.w),
          itemCount: state.nearbyPromotions.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md.h),
          itemBuilder: (context, index) {
            final promo = state.nearbyPromotions[index] as Map<String, dynamic>;
            final promoId = promo['_id']?.toString() ?? '';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _trackImpression(promoId);
            });
            return PromoCard(
              promo: promo,
              showAnalytics: false,
              onTap: () =>
                  BusinessService.instance.trackEvent(promoId, 'CLICK'),
              onSave: () {
                BusinessService.instance.trackEvent(promoId, 'SAVE');
                showGlobalToast(message: 'Promotion saved!', status: 'success');
              },
            );
          },
        );
      },
    );
  }
}

class _MyPromotionsList extends StatefulWidget {
  @override
  State<_MyPromotionsList> createState() => _MyPromotionsListState();
}

class _MyPromotionsListState extends State<_MyPromotionsList> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessBloc, BusinessState>(
      builder: (context, state) {
        if (state.isLoadingMine) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.myPromotions.isEmpty) {
          return Center(child: Text(state.error!));
        }
        if (state.myPromotions.isEmpty) {
          return const Center(child: Text('You have no active promotions'));
        }

        return ListView.separated(
          padding: EdgeInsets.all(AppSpacing.xs.w),
          itemCount: state.myPromotions.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md.h),
          itemBuilder: (context, index) {
            final promo = state.myPromotions[index] as Map<String, dynamic>;
            final promoId = promo['_id']?.toString() ?? '';
            return PromoCard(
              promo: promo,
              showAnalytics: true,
              onAnalytics: () => _showAnalyticsDialog(context, promoId),
            );
          },
        );
      },
    );
  }

  Future<void> _showAnalyticsDialog(
      BuildContext context, String promoId) async {
    final result = await BusinessService.instance.getAnalytics(promoId);
    if (!context.mounted) return;

    result.fold(
      (failure) => showGlobalToast(message: failure.message, status: 'error'),
      (analytics) {
        showDialog<void>(
          context: context,
          builder: (ctx) {
            final cs = Theme.of(ctx).colorScheme;
            final tt = Theme.of(ctx).textTheme;
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bar_chart_rounded,
                          size: 36, color: cs.primary),
                    ),
                    SizedBox(height: 16.h),
                    Text('Analytics Dashboard',
                        style: tt.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8.h),
                    Text('Live performance metrics for your offer',
                        style:
                            tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center),
                    SizedBox(height: 32.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatCard(
                            icon: Icons.visibility_rounded,
                            label: 'Views',
                            value: analytics['impressionsCount']?.toString() ??
                                '0',
                            color: Colors.blue),
                        _StatCard(
                            icon: Icons.touch_app_rounded,
                            label: 'Clicks',
                            value: analytics['clicksCount']?.toString() ?? '0',
                            color: Colors.orange),
                        _StatCard(
                            icon: Icons.bookmark_rounded,
                            label: 'Saves',
                            value: analytics['savesCount']?.toString() ?? '0',
                            color: Colors.green),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r)),
                        ),
                        child: const Text('Close'),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = context.theme.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(height: 12.h),
        Text(value,
            style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: context.theme.colorScheme.onSurface)),
        Text(label,
            style: tt.bodySmall
                ?.copyWith(color: context.theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
