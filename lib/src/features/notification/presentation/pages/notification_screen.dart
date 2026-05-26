import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<String> _tabs = [
    'All',
    'Activity',
    'Society',
    'Business',
    'System'
  ];
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const LoadNotifications(type: 'All'));
  }

  void _onTabTapped(int index) {
    setState(() => _activeTabIndex = index);
    final type = _tabs[index];
    context.read<NotificationBloc>().add(LoadNotifications(type: type));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Notifications',
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              context
                  .read<NotificationBloc>()
                  .add(MarkAllNotificationsAsRead());
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
            height: 38.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onTabTapped(index),
                  child: _TabChip(
                    label: _tabs[index],
                    active: _activeTabIndex == index,
                    cs: cs,
                    tt: tt,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 8.h),

          /// List
          Expanded(
            child: BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null) {
                  return Center(child: Text(state.error!));
                }

                if (state.notifications.isEmpty) {
                  return const Center(child: Text('No notifications yet.'));
                }

                return ListView.builder(
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    final it = state.notifications[index];

                    return GestureDetector(
                      onTap: () {
                        if (!it.isRead) {
                          context
                              .read<NotificationBloc>()
                              .add(MarkNotificationAsRead(it.id));
                        }
                      },
                      child: _NotificationItem(
                        title: it.title.isNotEmpty ? it.title : it.type,
                        text: it.message,
                        type: it.type,
                        time: _formatTime(it.createdAt),
                        isNew: !it.isRead,
                        cs: cs,
                        tt: tt,
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

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays == 1) return 'Yest';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String text;
  final String type;
  final String time;
  final bool isNew;
  final ColorScheme cs;
  final TextTheme tt;

  const _NotificationItem({
    required this.title,
    required this.text,
    required this.type,
    required this.time,
    required this.isNew,
    required this.cs,
    required this.tt,
  });

  IconData _getIconForType() {
    switch (type) {
      case 'POST_INTEREST':
        return IconsaxPlusBold.heart;
      case 'COMMENT':
        return IconsaxPlusBold.message;
      default:
        return IconsaxPlusBold.notification;
    }
  }

  Color _getColorForType(ColorScheme cs) {
    switch (type) {
      case 'POST_INTEREST':
        return Colors.pink;
      case 'COMMENT':
        return Colors.blue;
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getColorForType(cs);

    return Container(
      color: isNew ? cs.primary.withValues(alpha: 0.06) : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
            ),
            child: Icon(
              _getIconForType(),
              color: iconColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  text,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 6.h),
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
      margin: EdgeInsets.symmetric(vertical: 2.h).copyWith(right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: active
            ? cs.primary.withValues(alpha: 0.12)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        label,
        style: tt.labelMedium?.copyWith(
          fontSize: 12.sp,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? cs.primary : cs.onSurfaceVariant,
        ),
      ).center,
    );
  }
}
