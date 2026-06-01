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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<BusinessBloc>().add(LoadMyPromotions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Promotion'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: nameCtrl, hint: 'Business Name'),
              SizedBox(height: 12.h),
              AppTextField(controller: titleCtrl, hint: 'Title (e.g. 20% Off)'),
              SizedBox(height: 12.h),
              AppTextField(controller: descCtrl, hint: 'Description'),
              SizedBox(height: 12.h),
              AppTextField(
                  controller: discountCtrl, hint: 'Discount Code (Optional)'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && titleCtrl.text.isNotEmpty) {
                context.read<BusinessBloc>().add(CreatePromotionRequested(
                      businessName: nameCtrl.text,
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      discountCode:
                          discountCtrl.text.isEmpty ? null : discountCtrl.text,
                      coordinates: const [77.5946, 12.9716],
                    ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final isOwner = context
        .select((SessionBloc b) => b.state.user?.role == 'BusinessOwner');

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Business Promotions',
        centerTitle: true,
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (isOwner)
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Nearby'),
                  Tab(text: 'My Promotions'),
                ],
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
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
          padding: EdgeInsets.all(AppSpacing.lg.w),
          itemCount: state.nearbyPromotions.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md.h),
          itemBuilder: (context, index) {
            final promo =
                state.nearbyPromotions[index] as Map<String, dynamic>;
            final promoId = promo['_id']?.toString() ?? '';
            // Track impression as item becomes visible
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _trackImpression(promoId);
            });
            return _PromoCard(
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
          padding: EdgeInsets.all(AppSpacing.lg.w),
          itemCount: state.myPromotions.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md.h),
          itemBuilder: (context, index) {
            final promo =
                state.myPromotions[index] as Map<String, dynamic>;
            final promoId = promo['_id']?.toString() ?? '';
            return _PromoCard(
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
      (failure) =>
          showGlobalToast(message: failure.message, status: 'error'),
      (analytics) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Promotion Analytics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnalyticRow(
                    icon: Icons.visibility_outlined,
                    label: 'Impressions',
                    value: analytics['impressionsCount']?.toString() ?? '0'),
                SizedBox(height: 12.h),
                _AnalyticRow(
                    icon: Icons.touch_app_outlined,
                    label: 'Clicks',
                    value: analytics['clicksCount']?.toString() ?? '0'),
                SizedBox(height: 12.h),
                _AnalyticRow(
                    icon: Icons.bookmark_outline,
                    label: 'Saves',
                    value: analytics['savesCount']?.toString() ?? '0'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close')),
            ],
          ),
        );
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  final Map<String, dynamic> promo;
  final bool showAnalytics;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onAnalytics;

  const _PromoCard({
    required this.promo,
    required this.showAnalytics,
    this.onTap,
    this.onSave,
    this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                style:
                    tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Text(promo['description'] ?? '',
                style: tt.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            if (promo['discountCode'] != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Code: ${promo['discountCode']}',
                  style: tt.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                if (!showAnalytics && onSave != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.bookmark_outline, size: 16),
                      label: const Text('Save'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                if (showAnalytics && onAnalytics != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAnalytics,
                      icon: const Icon(Icons.bar_chart_outlined, size: 16),
                      label: const Text('Analytics'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AnalyticRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(label, style: tt.bodyMedium),
        ),
        Text(
          value,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
