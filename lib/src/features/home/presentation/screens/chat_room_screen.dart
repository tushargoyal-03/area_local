import 'dart:async';
import 'dart:io';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String recipientName;
  final String recipientId;
  final String? conversationType;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.recipientName,
    required this.recipientId,
    this.conversationType,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();

  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isRecording = false;
  late String? _recordingPath;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  AppChatMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _recordingPath = null;
    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';
    context.read<ChatBloc>().add(
          LoadMessagesRequested(
              chatId: widget.chatId, currentUserId: currentUserId),
        );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppDurations.medium,
        curve: Curves.easeOut,
      );
    }
  }

  void _onTextChanged(String text) {
    if (!_isTyping && text.trim().isNotEmpty) {
      _isTyping = true;
      context.read<ChatBloc>().add(
          SendTypingStatusRequested(chatId: widget.chatId, isTyping: true));
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatBloc>().add(
            SendTypingStatusRequested(chatId: widget.chatId, isTyping: false));
      }
    });
  }

  void _handleSend() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';

    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      context.read<ChatBloc>().add(
          SendTypingStatusRequested(chatId: widget.chatId, isTyping: false));
    }

    context.read<ChatBloc>().add(
          SendTextMessageRequested(
            chatId: widget.chatId,
            text: text,
            currentUserId: currentUserId,
            replyToId: _replyingTo?.id,
          ),
        );

    _msgController.clear();
    setState(() => _replyingTo = null);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _AttachmentSheet(
        onPickImage: () {
          Navigator.pop(context);
          _pickMedia(ImageSource.gallery, 'image');
        },
        onTakePhoto: () {
          Navigator.pop(context);
          _pickMedia(ImageSource.camera, 'image');
        },
        onPickVideo: () {
          Navigator.pop(context);
          _pickVideo(ImageSource.gallery);
        },
        onRecordVideo: () {
          Navigator.pop(context);
          _pickVideo(ImageSource.camera);
        },
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, String mediaType) async {
    final status = await Permission.photos.request();
    if (status.isDenied) {
      showGlobalToast(message: 'Photo permission denied', status: 'error');
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    if (!mounted) return;

    final file = File(picked.path);
    final mimeType = picked.mimeType ?? 'image/jpeg';
    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';

    context.read<ChatBloc>().add(
          SendMediaMessageRequested(
            chatId: widget.chatId,
            currentUserId: currentUserId,
            file: file,
            messageType: mediaType,
            mimeType: mimeType,
          ),
        );
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: source);
    if (picked == null) return;

    if (!mounted) return;

    final file = File(picked.path);
    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';

    context.read<ChatBloc>().add(
          SendMediaMessageRequested(
            chatId: widget.chatId,
            currentUserId: currentUserId,
            file: file,
            messageType: 'video',
            mimeType: 'video/mp4',
          ),
        );
  }

  Future<void> _startVoiceRecording() async {
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      showGlobalToast(message: 'Microphone permission denied', status: 'error');
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _recordingPath!,
    );

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopVoiceRecording() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path == null) return;

    if (!mounted) return;

    final file = File(path);
    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';

    context.read<ChatBloc>().add(
          SendMediaMessageRequested(
            chatId: widget.chatId,
            currentUserId: currentUserId,
            file: file,
            messageType: 'voice',
            mimeType: 'audio/aac',
            durationSeconds: _recordingSeconds,
          ),
        );
  }

  void _cancelVoiceRecording() async {
    _recordingTimer?.cancel();
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
    });
  }

  void _showMessageMenu(AppChatMessage msg) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              ListTile(
                leading: Icon(Icons.reply_rounded, color: cs.primary),
                title: Text('Reply', style: tt.bodyMedium),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _replyingTo = msg);
                },
              ),
              if (msg.type == MessageType.text && msg.text.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.copy_rounded, color: cs.onSurface),
                  title: Text('Copy', style: tt.bodyMedium),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: msg.text));
                    showGlobalToast(message: 'Copied', status: 'success');
                  },
                ),
              if (msg.isMe && !msg.isOptimistic)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                  title: Text('Delete',
                      style: tt.bodyMedium?.copyWith(color: cs.error)),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    context.read<ChatBloc>().add(DeleteMessageRequested(
                        messageId: msg.id, conversationId: widget.chatId));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGroupInfo(BuildContext context, ChatState state) {
    final conversation = state.conversations.firstWhere(
      (c) => c.id == widget.chatId,
      orElse: () => AppConversation(
        id: widget.chatId,
        participants: const [],
        recipientName: widget.recipientName,
        recipientId: widget.recipientId,
      ),
    );
    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';

    context.push('/group-info', extra: {
      'conversationId': widget.chatId,
      'groupName': widget.recipientName,
      'groupImageUrl': conversation.displayAvatar,
      'members': conversation.memberProfiles,
      'currentUserId': currentUserId,
      'isAdmin': conversation.admins.contains(currentUserId),
    });
  }

  void _showUserMenu() {
    if (widget.recipientId.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _UserMenuSheet(
        recipientName: widget.recipientName,
        recipientId: widget.recipientId,
        conversationId: widget.chatId,
        onBlock: () {
          Navigator.pop(context);
          _showBlockDialog();
        },
        onReport: () {
          Navigator.pop(context);
          _showReportDialog();
        },
      ),
    );
  }

  void _showBlockDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => _BlockDialog(
        recipientName: widget.recipientName,
        onConfirm: () {
          context
              .read<ChatBloc>()
              .add(BlockUserRequested(targetUserId: widget.recipientId));
          Navigator.of(context).pop(); // dialog
          Navigator.of(context).pop(); // chat room
        },
      ),
    );
  }

  void _showReportDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => _ReportDialog(
        recipientName: widget.recipientName,
        onSubmit: (reason, details) {
          context.read<ChatBloc>().add(
                ReportUserRequested(
                  targetUserId: widget.recipientId,
                  reason: reason,
                  details: details,
                  conversationId: widget.chatId,
                ),
              );
          Navigator.of(context).pop();
          showGlobalToast(message: 'Report submitted', status: 'success');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final isGroup = widget.conversationType == 'group';

    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.activeRoomMessages.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        }
        if (state.errorMessage != null) {
          showGlobalToast(message: state.errorMessage!, status: 'error');
        }
      },
      builder: (context, state) {
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
          appBar: AppTopBar(
            title: '',
            titleWidget: Row(
              children: [
                Avatar(
                    name: widget.recipientName,
                    size: 36.w,
                    imageUrl: conversation.displayAvatar),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipientName,
                        overflow: TextOverflow.ellipsis,
                        style:
                            tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (!isGroup)
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
                              style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant, fontSize: 10.sp),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (isGroup)
                IconButton(
                  icon: Icon(IconsaxPlusLinear.people, color: cs.onSurface),
                  onPressed: () => _navigateToGroupInfo(context, state),
                )
              else if (widget.recipientId.isNotEmpty)
                IconButton(
                  icon: Icon(IconsaxPlusLinear.more, color: cs.onSurface),
                  onPressed: _showUserMenu,
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: state.isMessagesLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        itemCount: state.activeRoomMessages.length,
                        itemBuilder: (context, index) {
                          final msg = state.activeRoomMessages[index];
                          final prevMsg =
                              index < state.activeRoomMessages.length - 1
                                  ? state.activeRoomMessages[index + 1]
                                  : null;

                          final showDateSep = prevMsg == null ||
                              !_sameDay(msg.createdAt, prevMsg.createdAt);

                          return Column(
                            children: [
                              if (showDateSep)
                                _DateSeparator(date: msg.createdAt),
                              GestureDetector(
                                onLongPress: msg.type == MessageType.system
                                    ? null
                                    : () => _showMessageMenu(msg),
                                child: _MessageBubble(
                                  msg: msg,
                                  recipientId: widget.recipientId,
                                  cs: cs,
                                  tt: tt,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // Typing indicator
              if (state.isPartnerTyping)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Row(
                      spacing: 4.w,
                      children: [
                        Text(
                          '${widget.recipientName} is typing',
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 11.sp,
                              fontStyle: FontStyle.italic),
                        ),
                        _TypingDots(cs: cs),
                      ],
                    ),
                  ),
                ),

              // Reply preview bar
              if (_replyingTo != null)
                _ReplyPreviewBar(
                  msg: _replyingTo!,
                  cs: cs,
                  tt: tt,
                  onDismiss: () => setState(() => _replyingTo = null),
                ),

              // Media upload progress
              if (state.isSendingMedia)
                LinearProgressIndicator(color: cs.primary, minHeight: 2.h),

              // Voice recording bar
              if (_isRecording)
                _RecordingBar(
                  seconds: _recordingSeconds,
                  onCancel: _cancelVoiceRecording,
                  onStop: _stopVoiceRecording,
                  cs: cs,
                  tt: tt,
                ),

              // Input bar
              if (!_isRecording)
                Container(
                  padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 24.h),
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Attachment button
                      IconButton(
                        onPressed: _showAttachmentSheet,
                        icon: Icon(IconsaxPlusLinear.add_circle,
                            color: cs.primary, size: 24.sp),
                      ),

                      // Text input
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: TextField(
                            controller: _msgController,
                            onChanged: _onTextChanged,
                            onSubmitted: (_) => _handleSend(),
                            maxLines: 5,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                  fontSize: 13.5.sp),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      // Send or mic button
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _msgController,
                        builder: (_, value, __) {
                          final hasText = value.text.trim().isNotEmpty;
                          return GestureDetector(
                            onTap: hasText ? _handleSend : null,
                            onLongPressStart:
                                hasText ? null : (_) => _startVoiceRecording(),
                            onLongPressEnd:
                                hasText ? null : (_) => _stopVoiceRecording(),
                            child: Container(
                              width: 44.w,
                              height: 44.w,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                hasText
                                    ? IconsaxPlusBold.send_1
                                    : IconsaxPlusLinear.microphone,
                                color: cs.onPrimary,
                                size: 20.sp,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 4.w),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final AppChatMessage msg;
  final String recipientId;
  final ColorScheme cs;
  final TextTheme tt;

  const _MessageBubble({
    required this.msg,
    required this.recipientId,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMe;

    Widget content;
    switch (msg.type) {
      case MessageType.image:
        content = _ImageBubble(msg: msg, cs: cs);
      case MessageType.video:
        content = _VideoBubble(msg: msg, cs: cs, tt: tt);
      case MessageType.voice:
        content = _VoiceBubble(msg: msg, cs: cs, tt: tt, isMe: isMe);
      case MessageType.system:
        return Center(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(msg.text,
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, fontSize: 11.sp)),
          ),
        );
      default:
        content = _TextContent(msg: msg, cs: cs, tt: tt, isMe: isMe);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 6.h,
          left: isMe ? 48.w : 0,
          right: isMe ? 0 : 48.w,
        ),
        decoration: BoxDecoration(
          color: isMe ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(4.r),
            bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(16.r),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  final AppChatMessage msg;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isMe;

  const _TextContent(
      {required this.msg,
      required this.cs,
      required this.tt,
      required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.replyToId != null && msg.replyToPreview != null)
            _ReplyQuote(
                senderName: msg.replyToSenderName ?? 'User',
                preview: msg.replyToPreview!,
                isMe: isMe,
                cs: cs,
                tt: tt),
          Text(
            msg.text,
            style: TextStyle(
                color: isMe ? cs.onPrimary : cs.onSurface, fontSize: 14.sp),
          ),
          SizedBox(height: 4.h),
          _TimeAndStatus(msg: msg, cs: cs, isMe: isMe),
        ],
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final AppChatMessage msg;
  final ColorScheme cs;

  const _ImageBubble({required this.msg, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: msg.mediaUrl!,
            width: 220.w,
            height: 200.h,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                _PlaceholderMedia(icon: IconsaxPlusLinear.image, cs: cs),
          )
        else
          _PlaceholderMedia(icon: IconsaxPlusLinear.image, cs: cs),
        Positioned(
          bottom: 6.h,
          right: 8.w,
          child: _TimeAndStatus(
              msg: msg, cs: cs, isMe: msg.isMe, textColor: Colors.white),
        ),
      ],
    );
  }
}

class _VideoBubble extends StatelessWidget {
  final AppChatMessage msg;
  final ColorScheme cs;
  final TextTheme tt;

  const _VideoBubble({required this.msg, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (msg.thumbnailUrl != null && msg.thumbnailUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: msg.thumbnailUrl!,
            width: 220.w,
            height: 200.h,
            fit: BoxFit.cover,
          )
        else
          _PlaceholderMedia(icon: IconsaxPlusLinear.video_play, cs: cs),
        Container(
          width: 48.w,
          height: 48.w,
          decoration: const BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child:
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28.sp),
        ),
        Positioned(
          bottom: 6.h,
          right: 8.w,
          child: _TimeAndStatus(
              msg: msg, cs: cs, isMe: msg.isMe, textColor: Colors.white),
        ),
      ],
    );
  }
}

class _VoiceBubble extends StatefulWidget {
  final AppChatMessage msg;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isMe;

  const _VoiceBubble(
      {required this.msg,
      required this.cs,
      required this.tt,
      required this.isMe});

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else if (widget.msg.mediaUrl != null && widget.msg.mediaUrl!.isNotEmpty) {
      setState(() => _isPlaying = true);
      await _player.play(UrlSource(widget.msg.mediaUrl!));
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final isMe = widget.isMe;
    final durationLabel = widget.msg.durationSeconds != null
        ? '${widget.msg.durationSeconds}s'
        : '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color:
                    isMe ? Colors.white24 : cs.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: isMe ? cs.onPrimary : cs.primary,
                size: 20.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎙 Voice message',
                style: TextStyle(
                    color: isMe ? cs.onPrimary : cs.onSurface, fontSize: 13.sp),
              ),
              if (durationLabel.isNotEmpty)
                Text(
                  durationLabel,
                  style: TextStyle(
                      color: (isMe ? cs.onPrimary : cs.onSurfaceVariant)
                          .withValues(alpha: 0.7),
                      fontSize: 11.sp),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          _TimeAndStatus(msg: widget.msg, cs: cs, isMe: isMe),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _TimeAndStatus extends StatelessWidget {
  final AppChatMessage msg;
  final ColorScheme cs;
  final bool isMe;
  final Color? textColor;

  const _TimeAndStatus(
      {required this.msg,
      required this.cs,
      required this.isMe,
      this.textColor});

  @override
  Widget build(BuildContext context) {
    final color = textColor ??
        (isMe ? cs.onPrimary : cs.onSurfaceVariant).withValues(alpha: 0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatMsgTime(msg.createdAt),
          style: TextStyle(color: color, fontSize: 9.sp),
        ),
        if (isMe) ...[
          SizedBox(width: 4.w),
          Icon(
            msg.isOptimistic ? Icons.done_rounded : Icons.done_all_rounded,
            size: 13.sp,
            color: msg.readBy.length > 1
                ? const Color(0xFF34B7F1)
                : (textColor ?? Colors.white60),
          ),
        ],
      ],
    );
  }

  String _formatMsgTime(DateTime time) {
    final h =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

class _PlaceholderMedia extends StatelessWidget {
  final IconData icon;
  final ColorScheme cs;

  const _PlaceholderMedia({required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      height: 150.h,
      color: cs.surfaceContainerHigh,
      child: Center(child: Icon(icon, size: 40.sp, color: cs.onSurfaceVariant)),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  final String senderName;
  final String preview;
  final bool isMe;
  final ColorScheme cs;
  final TextTheme tt;

  const _ReplyQuote({
    required this.senderName,
    required this.preview,
    required this.isMe,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? Colors.white.withValues(alpha: 0.2)
        : cs.primary.withValues(alpha: 0.1);
    final borderColor = isMe ? Colors.white54 : cs.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border(left: BorderSide(color: borderColor, width: 3.w)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: TextStyle(
              color: isMe ? cs.onPrimary : cs.primary,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp,
            ),
          ),
          Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  (isMe ? cs.onPrimary : cs.onSurface).withValues(alpha: 0.75),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyPreviewBar extends StatelessWidget {
  final AppChatMessage msg;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onDismiss;

  const _ReplyPreviewBar({
    required this.msg,
    required this.cs,
    required this.tt,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final preview = msg.type == MessageType.text
        ? (msg.text.length > 60 ? '${msg.text.substring(0, 60)}…' : msg.text)
        : msg.type.preview;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
          left: BorderSide(color: cs.primary, width: 3.w),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${msg.isMe ? 'yourself' : 'message'}',
                  style: tt.bodySmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.bold),
                ),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18.sp, color: cs.onSurfaceVariant),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(label,
            style: tt.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant, fontSize: 11.sp)),
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  final ColorScheme cs;
  const _TypingDots({required this.cs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16.w,
      height: 6.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return Container(
            width: 4.w,
            height: 4.w,
            decoration:
                BoxDecoration(color: cs.primary, shape: BoxShape.circle),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
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
}

class _RecordingBar extends StatelessWidget {
  final int seconds;
  final VoidCallback onCancel;
  final VoidCallback onStop;
  final ColorScheme cs;
  final TextTheme tt;

  const _RecordingBar({
    required this.seconds,
    required this.onCancel,
    required this.onStop,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        border: Border(
          top: BorderSide(color: cs.error.withValues(alpha: 0.3), width: 1.h),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.mic, color: cs.error, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            'Recording... ${_formatDuration(seconds)}',
            style: tt.bodyMedium?.copyWith(
                color: cs.onErrorContainer, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: onCancel,
            child:
                Text('Cancel', style: tt.bodySmall?.copyWith(color: cs.error)),
          ),
          ElevatedButton.icon(
            onPressed: onStop,
            icon: Icon(Icons.stop_rounded, size: 16.sp),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Bottom Sheets ────────────────────────────────────────────────────────────

class _AttachmentSheet extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickVideo;
  final VoidCallback onRecordVideo;

  const _AttachmentSheet({
    required this.onPickImage,
    required this.onTakePhoto,
    required this.onPickVideo,
    required this.onRecordVideo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Text('Share Media',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            _AttachOption(
              icon: IconsaxPlusLinear.gallery,
              label: 'Photo from Gallery',
              color: cs.primary,
              onTap: onPickImage,
            ),
            _AttachOption(
              icon: IconsaxPlusLinear.camera,
              label: 'Take Photo',
              color: cs.secondary,
              onTap: onTakePhoto,
            ),
            _AttachOption(
              icon: IconsaxPlusLinear.video,
              label: 'Video from Gallery',
              color: Colors.orange,
              onTap: onPickVideo,
            ),
            _AttachOption(
              icon: IconsaxPlusLinear.record,
              label: 'Record Video',
              color: Colors.red,
              onTap: onRecordVideo,
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = context.theme.textTheme;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
      title: Text(label, style: tt.bodyMedium),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _UserMenuSheet extends StatelessWidget {
  final String recipientName;
  final String recipientId;
  final String conversationId;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const _UserMenuSheet({
    required this.recipientName,
    required this.recipientId,
    required this.conversationId,
    required this.onBlock,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(name: recipientName, size: 48),
            SizedBox(height: 8.h),
            Text(recipientName,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            ListTile(
              onTap: onReport,
              leading: Icon(IconsaxPlusLinear.flag, color: cs.error),
              title: Text('Report User',
                  style: tt.bodyMedium?.copyWith(color: cs.error)),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              onTap: onBlock,
              leading: Icon(Icons.block_rounded, color: cs.error),
              title: Text('Block User',
                  style: tt.bodyMedium?.copyWith(color: cs.error)),
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

// ─── Dialogs ──────────────────────────────────────────────────────────────────

class _BlockDialog extends StatelessWidget {
  final String recipientName;
  final VoidCallback onConfirm;

  const _BlockDialog({required this.recipientName, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return AlertDialog(
      title: Text('Block $recipientName?',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      content: Text(
        '$recipientName will no longer be able to send you messages.',
        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: cs.error),
          child:
              Text('Block', style: tt.bodyMedium?.copyWith(color: cs.onError)),
        ),
      ],
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final String recipientName;
  final void Function(String reason, String? details) onSubmit;

  const _ReportDialog({required this.recipientName, required this.onSubmit});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _reasons = [
    ('HARASSMENT_OR_BULLYING', 'Harassment or bullying'),
    ('INAPPROPRIATE_CONTENT', 'Inappropriate content'),
    ('SPAM_OR_SCAM', 'Spam or scam'),
    ('IMPERSONATION', 'Impersonation'),
    ('OTHER', 'Other'),
  ];

  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return AlertDialog(
      title: Text('Report ${widget.recipientName}',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._reasons.map(
              (r) => RadioListTile<String>(
                value: r.$1,
                // ignore: deprecated_member_use
                groupValue: _selectedReason,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _selectedReason = v),
                title: Text(r.$2, style: tt.bodyMedium),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Additional details (optional)',
                hintStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                contentPadding: EdgeInsets.all(10.w),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null
              ? null
              : () => widget.onSubmit(
                    _selectedReason!,
                    _detailsController.text.trim().isEmpty
                        ? null
                        : _detailsController.text.trim(),
                  ),
          style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
          child: Text('Submit',
              style: tt.bodyMedium?.copyWith(color: cs.onPrimary)),
        ),
      ],
    );
  }
}
