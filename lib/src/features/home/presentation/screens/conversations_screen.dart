import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load conversations list on initialization
    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';
    context.read<ChatBloc>().add(LoadConversationsRequested(currentUserId: currentUserId));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          'Messages',
          style: tt.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';
              context.read<ChatBloc>().add(LoadConversationsRequested(currentUserId: currentUserId));
            },
            icon: Icon(IconsaxPlusLinear.refresh, color: cs.onSurface),
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.isConversationsLoading && state.conversations.isEmpty) {
            return _buildSkeletonLoader();
          }

          if (state.conversations.isEmpty) {
            return const AppEmptyState(
              icon: IconsaxPlusLinear.message,
              title: 'No conversations yet',
              subtitle: 'Select "I\'m Available" on neighborhood posts to initiate chats with residents!',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';
              context.read<ChatBloc>().add(LoadConversationsRequested(currentUserId: currentUserId));
            },
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w, vertical: AppSpacing.md.h),
              itemCount: state.conversations.length,
              separatorBuilder: (_, __) => Divider(
                color: cs.outlineVariant.withValues(alpha: 0.2),
                height: 1.h,
              ),
              itemBuilder: (context, index) {
                final conv = state.conversations[index];

                return InkWell(
                  onTap: () {
                    // Reset unread count locally
                    context.read<ChatBloc>().add(MarkMessagesAsReadRequested(chatId: conv.id));
                    
                    context.push(
                      '/chat-room',
                      extra: {
                        'chatId': conv.id,
                        'recipientName': conv.recipientName,
                        'recipientId': conv.recipientId,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Avatar(name: conv.recipientName, size: 54.w, imageUrl: conv.recipientAvatar),
                            if (conv.isRecipientOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14.w,
                                  height: 14.w,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cs.surface,
                                      width: 2.w,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      conv.recipientName,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                  ),
                                  if (conv.lastMessageTime != null)
                                    Text(
                                      _formatTime(conv.lastMessageTime!),
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conv.lastMessageText ?? 'No messages yet',
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.bodyMedium?.copyWith(
                                        color: conv.unreadCount > 0 ? cs.onSurface : cs.onSurfaceVariant,
                                        fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),
                                  if (conv.unreadCount > 0)
                                    Container(
                                      margin: EdgeInsets.only(left: 8.w),
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius: BorderRadius.circular(100.r),
                                      ),
                                      child: Text(
                                        conv.unreadCount.toString(),
                                        style: TextStyle(
                                          color: cs.onPrimary,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        itemCount: 6,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) {
          return Row(
            children: [
              Container(
                width: 54.w,
                height: 54.w,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16.h, width: 120.w, color: Colors.grey),
                    SizedBox(height: 8.h),
                    Container(height: 12.h, width: double.infinity, color: Colors.grey),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}
