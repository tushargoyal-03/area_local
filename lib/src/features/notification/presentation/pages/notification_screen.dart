import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'k': 'like',
        'who': 'Riya Sharma',
        't': 'liked your activity post',
        'time': '2m',
        'new': true,
      },
      {
        'k': 'join',
        'who': 'Karan Singh',
        't': 'is interested in your pickleball activity',
        'time': '8m',
        'new': true,
      },
      {
        'k': 'comment',
        'who': 'Meera Patel',
        't': 'commented: "Joining! Bringing my friend too 🎾"',
        'time': '22m',
        'new': true,
      },
      {
        'k': 'society',
        'who': 'Greenwood Heights',
        't': 'New notice: Water tank cleaning Saturday',
        'time': '1h',
        'new': false,
      },
      {
        'k': 'offer',
        'who': 'Boho Cafe',
        't': 'posted a new offer near you: 20% off coffee',
        'time': '3h',
        'new': false,
      },
      {
        'k': 'system',
        'who': 'Area Connect',
        't': 'Your join request was approved 🎉',
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
            child: const Text(
              'Mark all read',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// Tabs
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _TabChip('All', true),
                _TabChip('Activity', false),
                _TabChip('Society', false),
                _TabChip('Business', false),
                _TabChip('System', false),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// List
          Expanded(
            child: ListView.builder(
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.grey,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// NOTIFICATION ITEM
/// ===============================
class _NotificationItem extends StatelessWidget {
  final String who;
  final String text;
  final String time;
  final bool isNew;

  const _NotificationItem({
    required this.who,
    required this.text,
    required this.time,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isNew ? Colors.blue.withValues(alpha: 0.06) : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            child: Text(who[0]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: '$who ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: text),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isNew)
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ===============================
/// TAB CHIP
/// ===============================
class _TabChip extends StatelessWidget {
  final String label;
  final bool active;

  const _TabChip(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: active
            ? Colors.blue.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? Colors.blue : Colors.black87,
        ),
      ),
    );
  }
}
