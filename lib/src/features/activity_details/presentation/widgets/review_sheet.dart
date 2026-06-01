import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class ReviewSheet extends StatefulWidget {
  final String postId;
  final String targetUserId;
  final String targetUserName;

  const ReviewSheet({
    super.key,
    required this.postId,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _selectedRating = 0;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedRating == 0) {
      showGlobalToast(message: 'Please select a rating', status: 'error');
      return;
    }
    context.read<PostsBloc>().add(SubmitReviewRequested(
          postId: widget.postId,
          targetUserId: widget.targetUserId,
          rating: _selectedRating,
          comment: _commentCtrl.text.trim().isEmpty
              ? null
              : _commentCtrl.text.trim(),
          onSuccess: () => Navigator.pop(context),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24.w,
        20.h,
        24.w,
        MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
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
            'Rate ${widget.targetUserName}',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            'How was your experience with this person?',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = star),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Icon(
                    _selectedRating >= star
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _selectedRating >= star
                        ? const Color(0xFFFFC107)
                        : cs.outlineVariant,
                    size: 36.w,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 20.h),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a comment (optional)…',
              hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              filled: true,
              fillColor: cs.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          BlocBuilder<PostsBloc, PostsState>(
            builder: (context, state) => SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: state.isSubmittingAction ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: const StadiumBorder(),
                ),
                child: state.isSubmittingAction
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Review',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
