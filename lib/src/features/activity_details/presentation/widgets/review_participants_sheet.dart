import 'package:area_connect/src/features/activity_details/presentation/widgets/review_sheet.dart';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

/// Bottom sheet that lists the ACCEPTED participants of an activity so the
/// author can pick exactly who to review. Selecting a participant opens the
/// [ReviewSheet] pre-filled with that participant's real id and name.
class ReviewParticipantsSheet extends StatefulWidget {
  final String postId;

  const ReviewParticipantsSheet({super.key, required this.postId});

  @override
  State<ReviewParticipantsSheet> createState() =>
      _ReviewParticipantsSheetState();
}

class _ReviewParticipantsSheetState extends State<ReviewParticipantsSheet> {
  @override
  void initState() {
    super.initState();
    // Ensure the latest interested/accepted users are loaded.
    context
        .read<PostsBloc>()
        .add(LoadInterestedUsersRequested(postId: widget.postId));
  }

  ({String id, String name, String? avatar}) _extract(
      Map<String, dynamic> raw) {
    final user = raw['user'] as Map<String, dynamic>? ?? raw;
    final id = raw['userId']?.toString() ?? user['_id']?.toString() ?? '';
    final name = user['displayName']?.toString() ??
        user['name']?.toString() ??
        'Participant';
    final avatar = user['avatarUrl']?.toString();
    return (id: id, name: name, avatar: avatar);
  }

  void _openReviewSheet(String userId, String userName) {
    Navigator.pop(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PostsBloc>(),
        child: ReviewSheet(
          postId: widget.postId,
          targetUserId: userId,
          targetUserName: userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.7.sh),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Rate Participants',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            'Pick a participant you joined this activity with.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: 16.h),
          Flexible(
            child: BlocBuilder<PostsBloc, PostsState>(
              builder: (context, state) {
                if (state.isLoadingInterestedUsers) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final accepted = state.interestedUsers
                    .whereType<Map<String, dynamic>>()
                    .where((u) => (u['status']?.toString() ?? '') == 'ACCEPTED')
                    .toList();

                if (accepted.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconsaxPlusLinear.people,
                            size: 44.w, color: cs.onSurfaceVariant),
                        SizedBox(height: 12.h),
                        Text(
                          'No accepted participants to review yet.',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: accepted.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final info = _extract(accepted[index]);
                    return Material(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: info.id.isEmpty
                            ? null
                            : () => _openReviewSheet(info.id, info.name),
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Row(
                            children: [
                              Avatar(
                                  name: info.name,
                                  size: 44,
                                  imageUrl: info.avatar),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  info.name,
                                  style: tt.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(Icons.star_outline_rounded,
                                  color: const Color(0xFFFFC107), size: 22.w),
                            ],
                          ),
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
    );
  }
}
