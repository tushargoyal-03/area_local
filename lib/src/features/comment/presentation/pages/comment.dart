import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class CommentsSheetScreen extends StatefulWidget {
  final String postId;
  const CommentsSheetScreen({super.key, required this.postId});

  @override
  State<CommentsSheetScreen> createState() => _CommentsSheetScreenState();
}

class _CommentsSheetScreenState extends State<CommentsSheetScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _commentsList = [];
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final result = await PostsService.instance.getComments(widget.postId);
    result.fold(
      (failure) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        showGlobalToast(message: failure.message, status: 'error');
      },
      (list) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _commentsList.clear();
            _commentsList.addAll(list.map((item) {
              final comment = item as Map<String, dynamic>;
              final author = comment['author'] as Map<String, dynamic>?;
              return {
                'name': author?['displayName']?.toString() ?? 'Neighbor',
                'text': comment['content']?.toString() ?? '',
                'time': _formatTime(comment['createdAt']?.toString()),
                'likes': 0,
              };
            }));
          });
        }
      },
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'Just now';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'Just now';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    context.read<PostsBloc>().add(
          AddCommentRequested(
            postId: widget.postId,
            content: text,
            onSuccess: () {
              if (mounted) {
                setState(() {
                  _isSubmitting = false;
                  _commentsList.add({
                    'name': 'You',
                    'text': text,
                    'time': 'Just now',
                    'likes': 0,
                  });
                  _commentController.clear();
                });
              }
            },
            onFailure: () {
              if (mounted) {
                setState(() {
                  _isSubmitting = false;
                });
              }
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        height: mediaQuery.size.height * 0.78,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            /// Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_commentsList.length} comments',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconsaxPlusLinear.close_square,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Comments List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _commentsList.isEmpty
                      ? Center(
                          child: Text(
                            'No comments yet. Start the conversation!',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          itemCount: _commentsList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            final comment = _commentsList[index];
                            final likes = comment['likes'] as int;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Avatar(
                                    name: comment['name'] as String, size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      /// Bubble
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerLow,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(20),
                                            bottomLeft: Radius.circular(20),
                                            bottomRight: Radius.circular(20),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment['name'] as String,
                                              style: tt.labelMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              comment['text'] as String,
                                              style: tt.bodySmall
                                                  ?.copyWith(height: 1.4),
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
                                            style: tt.bodySmall?.copyWith(
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Reply',
                                            style: tt.bodySmall?.copyWith(
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant,
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
                                                  style: tt.bodySmall?.copyWith(
                                                    fontSize: 11,
                                                    color: cs.onSurfaceVariant,
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

            /// Comment Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Avatar(name: 'You', size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _commentController,
                        onSubmitted: (_) => _handleSubmit(),
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          border: InputBorder.none,
                          hintStyle: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _handleSubmit,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [
                            AppPalettes.primaryLight,
                            AppPalettes.primary2Light,
                          ],
                        ),
                      ),
                      child: _isSubmitting
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(
                              IconsaxPlusLinear.send_1,
                              color: Colors.white,
                              size: 20,
                            ),
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
}
