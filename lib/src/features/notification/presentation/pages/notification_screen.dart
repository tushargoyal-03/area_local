import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final items = [
      {
        'who': 'Riya Sharma',
        't': 'liked your activity post',
        'time': '2m',
        'new': true,
      },
      {
        'who': 'Karan Singh',
        't': 'is interested in your pickleball activity',
        'time': '8m',
        'new': true,
      },
      {
        'who': 'Meera Patel',
        't': 'commented: "Joining! Bringing my friend too"',
        'time': '22m',
        'new': true,
      },
      {
        'who': 'Greenwood Heights',
        't': 'New notice: Water tank cleaning Saturday',
        'time': '1h',
        'new': false,
      },
      {
        'who': 'Boho Cafe',
        't': 'posted a new offer near you: 20% off coffee',
        'time': '3h',
        'new': false,
      },
      {
        'who': 'Area Connect',
        't': 'Your join request was approved',
        'time': 'Yest',
        'new': false,
      },
    ];

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
            onPressed: () {},
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
            child: ListView.builder(
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Text(
                      'NEW',
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

                return _NotificationItem(
                  who: it['who'] as String,
                  text: it['t'] as String,
                  time: it['time'] as String,
                  isNew: it['new'] as bool? ?? false,
                  cs: cs,
                  tt: tt,
                );
              },
            ),
          ),
        ],
      ),
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
