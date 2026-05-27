import 'dart:async';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import '../providers/user_profile_bloc.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<UserProfileBloc>().add(ResetSearch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        context
            .read<UserProfileBloc>()
            .add(SearchUsersRequested(query: query.trim()));
      } else {
        context.read<UserProfileBloc>().add(ResetSearch());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Search Neighbors',
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg.w),
              child: AppTextField(
                controller: _searchController,
                hint: 'Search by name...',
                prefixIcon: Icon(IconsaxPlusLinear.search_normal,
                    color: cs.onSurfaceVariant),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: BlocBuilder<UserProfileBloc, UserProfileState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.error != null) {
                    return Center(child: Text(state.error!));
                  }

                  if (_searchController.text.trim().isEmpty) {
                    return Center(
                      child: Text('Type to search for neighbors',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    );
                  }

                  if (state.searchResults.isEmpty) {
                    return Center(
                      child: Text('No users found',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                    itemCount: state.searchResults.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: AppSpacing.sm.h),
                    itemBuilder: (context, index) {
                      final user = state.searchResults[index];
                      final name =
                          user['displayName'] ?? user['name'] ?? 'Neighbor';
                      final avatar = user['avatarUrl'];
                      final userId = user['_id'] ?? user['userId'];

                      return InkWell(
                        onTap: () {
                          if (userId != null) {
                            context.push(
                                '${AppRoutes.viewProfile}/${userId.toString()}');
                          }
                        },
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24.r,
                                backgroundColor: cs.surfaceContainerHigh,
                                backgroundImage: avatar != null
                                    ? NetworkImage(avatar)
                                    : null,
                                child: avatar == null
                                    ? Icon(Icons.person,
                                        color: cs.onSurfaceVariant)
                                    : null,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  name,
                                  style: tt.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 16.r, color: cs.onSurfaceVariant),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
