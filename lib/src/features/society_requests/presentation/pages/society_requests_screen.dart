import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:area_connect/src/features/society_requests/presentation/providers/society_requests_bloc.dart';
import 'package:area_connect/src/features/society_requests/domain/entities/society_join_request.dart';

class SocietyRequestsScreen extends StatelessWidget {
  final String societyId;
  const SocietyRequestsScreen({super.key, required this.societyId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SocietyRequestsBloc()..add(LoadSocietyRequests(societyId: societyId)),
      child: const _SocietyRequestsView(),
    );
  }
}

class _SocietyRequestsView extends StatelessWidget {
  const _SocietyRequestsView();

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      appBar: const AppTopBar(title: 'Join Requests'),
      body: BlocBuilder<SocietyRequestsBloc, SocietyRequestsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }
          if (state.requests.isEmpty) {
            return Center(
              child: Text(
                'No join requests found.',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.md.w),
            itemCount: state.requests.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm.h),
            itemBuilder: (context, index) {
              final request = state.requests[index];
              return _RequestItemCard(request: request, cs: cs, tt: tt);
            },
          );
        },
      ),
    );
  }
}

class _RequestItemCard extends StatelessWidget {
  final SocietyJoinRequest request;
  final ColorScheme cs;
  final TextTheme tt;

  const _RequestItemCard({
    required this.request,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = request.status.toUpperCase() == 'PENDING';
    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: request.avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(request.avatarUrl)
                      : null,
                  child: request.avatarUrl.isEmpty
                      ? Icon(IconsaxPlusLinear.user,
                          color: cs.onPrimaryContainer)
                      : null,
                ),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.displayName,
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        DateTime.tryParse(request.createdAt)
                                ?.toLocal()
                                .toString()
                                .split('.')
                                .first ??
                            request.createdAt,
                        style:
                            tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(request.status, cs, tt),
              ],
            ),
            if (request.message.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sm.h),
              Text(
                request.message,
                style: tt.bodyMedium,
              ),
            ],
            if (isPending) ...[
              SizedBox(height: AppSpacing.md.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      final socId =
                          GoRouterState.of(context).pathParameters['id'] ?? '';
                      context.read<SocietyRequestsBloc>().add(
                          RejectSocietyRequest(
                              societyId: socId, requestId: request.id));
                    },
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    child: const Text('Reject'),
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  ElevatedButton(
                    onPressed: () {
                      final socId =
                          GoRouterState.of(context).pathParameters['id'] ?? '';
                      context.read<SocietyRequestsBloc>().add(
                          ApproveSocietyRequest(
                              societyId: socId, requestId: request.id));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme cs, TextTheme tt) {
    Color bgColor;
    Color textColor;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        bgColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green[800]!;
        break;
      case 'REJECTED':
        bgColor = cs.errorContainer;
        textColor = cs.onErrorContainer;
        break;
      default:
        bgColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange[800]!;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        status.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
