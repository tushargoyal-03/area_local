import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class CommentsSheetScreen extends StatelessWidget {
  const CommentsSheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final comments = [
      {
        'name': 'Karan Singh',
        'text': "I'm down! See you at 6.",
        'time': '2m',
        'likes': 4,
      },
      {
        'name': 'Meera Patel',
        'text': "Are paddles provided? I'm a beginner.",
        'time': '5m',
        'likes': 1,
      },
      {
        'name': 'Dev Arora',
        'text': "What's the address exactly?",
        'time': '12m',
        'likes': 0,
      },
      {
        'name': 'Aanya R.',
        'text': 'Joining! Bringing my friend too 🎾',
        'time': '18m',
        'likes': 9,
      },
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        height: mediaQuery.size.height * 0.78,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, -4),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Column(
          children: [
            /// Drag Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            /// Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '28 comments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        IconsaxPlusLinear.close_square,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Comments List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  final likes = comment['likes'] as int;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(
                        comment['name'] as String,
                        36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Bubble
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.08),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment['text'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// Footer
                            Row(
                              children: [
                                Text(
                                  comment['time'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Reply',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (likes > 0) ...[
                                  const SizedBox(width: 16),
                                  Row(
                                    children: [
                                      const Icon(
                                        IconsaxPlusLinear.heart,
                                        size: 12,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        likes.toString(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            /// Comment Input
            Container(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                24,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _buildAvatar('You', 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add a comment…',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    child: const Icon(
                      IconsaxPlusLinear.smileys,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, double size) {
    return CircleAvatar(
      radius: size / 2,
      child: Text(
        name[0],
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
