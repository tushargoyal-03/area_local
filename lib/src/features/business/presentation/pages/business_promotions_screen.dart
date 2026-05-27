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
                // Hardcoded coordinates for demo, should ideally use location service
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

class _NearbyPromotionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

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
            final promo = state.nearbyPromotions[index];
            return _buildPromoCard(promo, cs, tt);
          },
        );
      },
    );
  }
}

class _MyPromotionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

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
            final promo = state.myPromotions[index];
            return _buildPromoCard(promo, cs, tt);
          },
        );
      },
    );
  }
}

Widget _buildPromoCard(
    Map<String, dynamic> promo, ColorScheme cs, TextTheme tt) {
  return Container(
    padding: EdgeInsets.all(AppSpacing.md.w),
    decoration: BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(promo['businessName'] ?? 'Business',
            style: tt.labelSmall?.copyWith(color: cs.primary)),
        SizedBox(height: 4.h),
        Text(promo['title'] ?? 'Promotion',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        Text(promo['description'] ?? '',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        if (promo['discountCode'] != null) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'Code: ${promo['discountCode']}',
              style: tt.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
            ),
          )
        ]
      ],
    ),
  );
}
