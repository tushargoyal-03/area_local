import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:area_connect/src/features/home/presentation/screens/new_group_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _tabs = [
    (label: 'Personal', type: 'direct'),
    (label: 'Groups', type: 'group'),
    (label: 'Events', type: 'event'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadConversations();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _loadConversations(tabIndex: _tabController.index);
  }

  void _loadConversations({int? tabIndex, String? search}) {
    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';
    final idx = tabIndex ?? _tabController.index;
    context.read<ChatBloc>().add(
          LoadConversationsRequested(
            currentUserId: currentUserId,
            typeFilter: _tabs[idx].type,
            search: search ?? _searchQuery,
          ),
        );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _loadConversations(search: value);
  }

  void _openNewGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewGroupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          if (_tabController.index == 1)
            IconButton(
              tooltip: 'New Group',
              onPressed: _openNewGroup,
              icon: Icon(IconsaxPlusLinear.add_circle, color: cs.primary),
            ),
          IconButton(
            onPressed: _loadConversations,
            icon: Icon(IconsaxPlusLinear.refresh, color: cs.onSurface),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100.h),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: Icon(IconsaxPlusLinear.search_normal,
                        size: 18.sp),
                    filled: true,
                    fillColor: cs.surfaceContainerHigh,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: _tabs
                    .map((t) => Tab(text: t.label))
                    .toList(),
                indicatorColor: cs.primary,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((_) => BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state.isConversationsLoading &&
                        state.conversations.isEmpty) {
                      return _buildSkeletonLoader();
                    }

                    if (state.conversations.isEmpty) {
                      return AppEmptyState(
                        icon: IconsaxPlusLinear.message,
                        title: 'No conversations yet',
                        subtitle: _tabController.index == 0
                            ? 'Select "I\'m Available" on posts to start a chat'
                            : _tabController.index == 1
                                ? 'Tap + to create a group chat'
                                : 'No event chats yet',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _loadConversations(),
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs),
                        itemCount: state.conversations.length,
                        separatorBuilder: (_, __) => Divider(
                          color: cs.outlineVariant.withValues(alpha: 0.2),
                          height: 1.h,
                        ),
                        itemBuilder: (context, index) =>
                            _ConversationTile(
                          conv: state.conversations[index],
                        ),
                      ),
                    );
                  },
                ))
            .toList(),
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
                    Container(
                        height: 12.h,
                        width: double.infinity,
                        color: Colors.grey),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final AppConversation conv;
  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return ListTile(
      onTap: () {
        context
            .read<ChatBloc>()
            .add(MarkMessagesAsReadRequested(chatId: conv.id));
        context.push(
          '/chat-room',
          extra: {
            'chatId': conv.id,
            'recipientName': conv.displayName,
            'recipientId': conv.recipientId,
            'conversationType': conv.type.name,
          },
        );
      },
      leading: Badge(
        isLabelVisible:
            conv.type == ConversationType.direct && conv.isRecipientOnline,
        child: Avatar(
          name: conv.displayName,
          size: 42,
          imageUrl: conv.displayAvatar,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      title: Text(
        conv.displayName,
        overflow: TextOverflow.ellipsis,
        style: tt.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 15.sp,
        ),
      ),
      subtitle: Text(
        conv.lastMessagePreview ?? conv.lastMessageText ?? 'No messages yet',
        overflow: TextOverflow.ellipsis,
        style: tt.bodyMedium?.copyWith(
          color: conv.unreadCount > 0 ? cs.onSurface : cs.onSurfaceVariant,
          fontWeight:
              conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          fontSize: 13.sp,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conv.lastMessageTime ?? DateTime.now()),
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Badge(
            isLabelVisible: conv.unreadCount > 0,
            label: Text(conv.unreadCount.toString()),
          ),
        ],
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
