import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final items = state.notifications;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Notifications'),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () {
                  context.read<NotificationBloc>().add(const MarkAllAsReadRequested());
                },
                child: Text(
                  'Mark all read',
                  style: tt.bodySmall?.copyWith(
                    fontSize: 12.5.sp,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              /// Tabs
              SizedBox(
                height: 44.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    _TabChip(label: 'All', active: true, cs: cs, tt: tt),
                    _TabChip(label: 'Activity', active: false, cs: cs, tt: tt),
                    _TabChip(label: 'Society', active: false, cs: cs, tt: tt),
                    _TabChip(label: 'Business', active: false, cs: cs, tt: tt),
                    _TabChip(label: 'System', active: false, cs: cs, tt: tt),
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              /// List
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              IconsaxPlusLinear.notification,
                              size: 48.sp,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'No new notifications',
                              style: tt.titleSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              child: Text(
                                'RECENT',
                                style: tt.labelSmall?.copyWith(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            );
                          }

                          final it = items[index - 1];

                          return GestureDetector(
                            onTap: () {
                              context.read<NotificationBloc>().add(ToggleReadStatusRequested(it.id));
                              
                              if (it.type == NotificationType.chat && it.relatedId != null) {
                                context.push(
                                  AppRoutes.chatRoom,
                                  extra: {
                                    'chatId': it.relatedId!,
                                    'recipientName': it.senderName,
                                    'recipientId': it.senderId,
                                  },
                                );
                              } else if (it.relatedId != null && it.relatedId!.isNotEmpty) {
                                context.push(AppRoutes.localityFeed);
                              }
                            },
                            child: _NotificationItem(
                              who: it.senderName,
                              text: it.message,
                              time: _formatTimeAgo(it.timestamp),
                              isNew: !it.isRead,
                              cs: cs,
                              tt: tt,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String who;
  final String text;
  final String time;
  final bool isNew;
  final ColorScheme cs;
  final TextTheme tt;

  const _NotificationItem({
    required this.who,
    required this.text,
    required this.time,
    required this.isNew,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isNew ? cs.primary.withValues(alpha: 0.06) : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(name: who, size: 42),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: '$who ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: text),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  time,
                  style: tt.bodySmall?.copyWith(
                    fontSize: 10.5.sp,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isNew)
            Container(
              margin: EdgeInsets.only(top: 6.h),
              width: 8.w,
              height: 8.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppPalettes.primaryLight, AppPalettes.primary2Light],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final ColorScheme cs;
  final TextTheme tt;

  const _TabChip({
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
