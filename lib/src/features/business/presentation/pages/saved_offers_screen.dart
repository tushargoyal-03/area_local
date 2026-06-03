import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:area_connect/src/features/business/presentation/providers/business_bloc.dart';

class SavedOffersScreen extends StatefulWidget {
  const SavedOffersScreen({super.key});

  @override
  State<SavedOffersScreen> createState() => _SavedOffersScreenState();
}

class _SavedOffersScreenState extends State<SavedOffersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BusinessBloc>().add(LoadSavedPromotions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Saved Offers'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: BlocBuilder<BusinessBloc, BusinessState>(
        builder: (context, state) {
          if (state.isLoadingSaved && state.savedPromotions.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (state.error != null && state.savedPromotions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(state.error!,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<BusinessBloc>().add(LoadSavedPromotions()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.savedPromotions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No saved offers yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Offers you save will appear here',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BusinessBloc>().add(LoadSavedPromotions());
            },
            color: Theme.of(context).colorScheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.savedPromotions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final promo =
                    state.savedPromotions[index] as Map<String, dynamic>;
                return PromoCard(
                  promo: promo,
                  showAnalytics: false,
                  onTap: () {
                    // You can navigate to details if you want
                  },
                  onSave: () async {
                    // Because they are in the saved list, tapping save again unsaves it
                    // The promo object here contains `_id` or `id` based on backend lookup mapping
                    // In BusinessRepository, we map `_id: $promotion._id`
                    final promoId =
                        promo['_id']?.toString() ?? promo['id']?.toString();
                    if (promoId != null) {
                      final result = await BusinessService.instance
                          .toggleSavePromotion(promoId);
                      result.fold(
                          (l) => showGlobalToast(
                              message: l.message, status: 'error'), (r) {
                        showGlobalToast(
                            message: 'Offer removed from saved',
                            status: 'success');
                        context.read<BusinessBloc>().add(LoadSavedPromotions());
                      });
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
