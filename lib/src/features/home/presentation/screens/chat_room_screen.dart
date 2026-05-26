import 'dart:async';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String recipientName;
  final String recipientId;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.recipientName,
    required this.recipientId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';
    
    // Load chat room messages
    context.read<ChatBloc>().add(
      LoadMessagesRequested(chatId: widget.chatId, currentUserId: currentUserId),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.medium,
        curve: Curves.easeOut,
      );
    }
  }

  void _onTextChanged(String text) {
    if (!_isTyping && text.trim().isNotEmpty) {
      _isTyping = true;
      context.read<ChatBloc>().add(SendTypingStatusRequested(chatId: widget.chatId, isTyping: true));
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatBloc>().add(SendTypingStatusRequested(chatId: widget.chatId, isTyping: false));
      }
    });
  }

  void _handleSend() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';

    // Cancel typing
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      context.read<ChatBloc>().add(SendTypingStatusRequested(chatId: widget.chatId, isTyping: false));
    }

    context.read<ChatBloc>().add(
      SendMessageRequested(chatId: widget.chatId, text: text, currentUserId: currentUserId),
    );

    _msgController.clear();
    
    // Scroll down shortly after emit
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.activeRoomMessages.isNotEmpty) {
          // Trigger scroll on new message arrival
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        }
      },
      builder: (context, state) {
        // Compute recipient presence from list
        final conversation = state.conversations.firstWhere(
          (c) => c.id == widget.chatId,
          orElse: () => AppConversation(
            id: widget.chatId,
            participants: const <String>[],
            recipientName: widget.recipientName,
            recipientId: widget.recipientId,
          ),
        );
        final isOnline = conversation.isRecipientOnline;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                // Mark messages read on leave
                context.read<ChatBloc>().add(MarkMessagesAsReadRequested(chatId: widget.chatId));
                Navigator.pop(context);
              },
            ),
            title: Row(
              children: [
                Avatar(name: widget.recipientName, size: 38.w, imageUrl: conversation.recipientAvatar),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipientName,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10.sp),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: state.isMessagesLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        itemCount: state.activeRoomMessages.length,
                        itemBuilder: (context, index) {
                          final msg = state.activeRoomMessages[index];
                          final isMe = msg.isMe;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.only(
                                bottom: 8.h,
                                left: isMe ? 48.w : 0,
                                right: isMe ? 0 : 48.w,
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? cs.primary
                                    : cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16.r),
                                  topRight: Radius.circular(16.r),
                                  bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(4.r),
                                  bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(16.r),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: isMe ? cs.onPrimary : cs.onSurface,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatMsgTime(msg.createdAt),
                                        style: TextStyle(
                                          color: (isMe ? cs.onPrimary : cs.onSurfaceVariant)
                                              .withValues(alpha: 0.70),
                                          fontSize: 9.sp,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        SizedBox(width: 4.w),
                                        Icon(
                                          msg.readBy.contains(widget.recipientId)
                                              ? Icons.done_all_rounded
                                              : Icons.done_rounded,
                                          size: 12.sp,
                                          color: msg.readBy.contains(widget.recipientId)
                                              ? Colors.blue
                                              : cs.onPrimary.withValues(alpha: 0.7),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Partner Typing Indication
              if (state.isPartnerTyping)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Row(
                      spacing: 4.w,
                      children: [
                        Text(
                          '${widget.recipientName} is typing',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11.sp, fontStyle: FontStyle.italic),
                        ),
                        _buildTypingDots(cs),
                      ],
                    ),
                  ),
                ),

              // Input Bottom Sheet bar
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  border: Border(
                    top: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                      width: 1.h,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: TextField(
                          controller: _msgController,
                          onChanged: _onTextChanged,
                          onSubmitted: (_) => _handleSend(),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13.5.sp),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: _handleSend,
                      child: Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconsaxPlusBold.send_1,
                          color: cs.onPrimary,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingDots(ColorScheme cs) {
    return SizedBox(
      width: 16.w,
      height: 6.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(
             begin: const Offset(1, 1),
             end: const Offset(1.6, 1.6),
             duration: const Duration(milliseconds: 300),
             delay: Duration(milliseconds: index * 100),
           );
        }),
      ),
    );
  }

  String _formatMsgTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}
