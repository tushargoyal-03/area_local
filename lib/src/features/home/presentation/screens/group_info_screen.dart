import 'dart:io';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class GroupInfoScreen extends StatelessWidget {
  final String conversationId;
  final String groupName;
  final String? groupImageUrl;
  final List<Map<String, dynamic>> members;
  final String currentUserId;
  final bool isAdmin;

  const GroupInfoScreen({
    super.key,
    required this.conversationId,
    required this.groupName,
    this.groupImageUrl,
    required this.members,
    required this.currentUserId,
    required this.isAdmin,
  });

  Future<void> _pickGroupImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (context.mounted) {
      context.read<ChatBloc>().add(
            UpdateGroupImageRequested(
              conversationId: conversationId,
              imageFile: File(picked.path),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final conversation = state.conversations.firstWhere(
          (c) => c.id == conversationId,
          orElse: () => AppConversation(
            id: conversationId,
            type: ConversationType.group,
            participants:
                members.map((m) => m['userId']?.toString() ?? '').toList(),
            recipientName: groupName,
            recipientId: '',
            imageUrl: groupImageUrl,
            memberProfiles: members,
          ),
        );
        final currentGroupImageUrl = conversation.imageUrl;
        final currentGroupName = conversation.title ?? groupName;
        final currentMembers = conversation.memberProfiles;

        return Scaffold(
          appBar: AppTopBar(
            title: 'Group Info',
            actions: [
              if (isAdmin)
                TextButton(
                  onPressed: () => _confirmDeleteGroup(context),
                  child: Text(
                    'Delete Group',
                    style: tt.bodySmall?.copyWith(color: cs.error),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Group header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24.h),
                color: cs.surfaceContainerLow,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Avatar(
                          name: currentGroupName,
                          size: 72,
                          imageUrl: currentGroupImageUrl,
                        ),
                        if (isAdmin)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _pickGroupImage(context),
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: cs.onPrimary,
                                  size: 14.r,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      currentGroupName,
                      style:
                          tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${currentMembers.length} members',
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              Divider(
                  height: 1.h, color: cs.outlineVariant.withValues(alpha: 0.3)),

              // Members list
              Expanded(
                child: ListView.builder(
                  itemCount: currentMembers.length,
                  itemBuilder: (context, index) {
                    final member = currentMembers[index];
                    final uid = member['userId']?.toString() ?? '';
                    final name = member['displayName']?.toString() ?? 'User';
                    final avatar = member['avatarUrl']?.toString();
                    final isCurrentUser = uid == currentUserId;
                    final memberIsAdmin = member['isAdmin'] as bool? ?? false;

                    return ListTile(
                      leading: Avatar(name: name, size: 44, imageUrl: avatar),
                      title: Text(
                        isCurrentUser ? '$name (You)' : name,
                        style:
                            tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (memberIsAdmin)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'Admin',
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onPrimaryContainer,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (isAdmin && !isCurrentUser) ...[
                            SizedBox(width: 8.w),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline,
                                  color: cs.error, size: 20.sp),
                              onPressed: () =>
                                  _confirmRemoveMember(context, uid, name),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Action buttons
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLeaveGroup(context),
                    icon: Icon(Icons.exit_to_app_rounded, color: cs.error),
                    label: Text(
                      'Leave Group',
                      style: tt.bodyMedium?.copyWith(color: cs.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.error),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmRemoveMember(BuildContext context, String userId, String name) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove $name?',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        content: Text('$name will be removed from this group.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ChatBloc>().add(RemoveMemberRequested(
                  conversationId: conversationId, targetUserId: userId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: Text('Remove',
                style: tt.bodyMedium?.copyWith(color: cs.onError)),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Leave Group?',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        content: Text('You will no longer receive messages from this group.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<ChatBloc>()
                  .add(LeaveGroupRequested(conversationId: conversationId));
              Navigator.of(context).pop(); // group info
              Navigator.of(context).pop(); // chat room
            },
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: Text('Leave',
                style: tt.bodyMedium?.copyWith(color: cs.onError)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Group?',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        content: Text(
            'This will permanently delete the group and all messages for everyone.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<ChatBloc>()
                  .add(DeleteGroupRequested(conversationId: conversationId));
              Navigator.of(context).pop(); // group info
              Navigator.of(context).pop(); // chat room
            },
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: Text('Delete',
                style: tt.bodyMedium?.copyWith(color: cs.onError)),
          ),
        ],
      ),
    );
  }
}
