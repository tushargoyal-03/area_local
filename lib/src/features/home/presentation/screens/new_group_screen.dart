import 'dart:io';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _selectedIds = {};
  final Map<String, Map<String, dynamic>> _selectedUsers = {};
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _groupImageUrl = '';
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    final result = await UsersService.instance.searchUsers(
      query: query.trim(),
      limit: 20,
    );

    result.fold(
      (_) => setState(() => _isSearching = false),
      (list) {
        setState(() {
          _isSearching = false;
          _searchResults = List<Map<String, dynamic>>.from(list);
        });
      },
    );
  }

  void _toggleUser(Map<String, dynamic> user) {
    final id = user['userId']?.toString() ?? '';
    if (id.isEmpty) return;

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectedUsers.remove(id);
      } else {
        _selectedIds.add(id);
        _selectedUsers[id] = user;
      }
    });
  }

  void _createGroup() {
    if (_selectedIds.isEmpty) {
      showGlobalToast(message: 'Select at least one member', status: 'error');
      return;
    }

    final currentUserId = context.read<SessionBloc>().state.user?.id ?? '';

    context.read<ChatBloc>().add(
          CreateGroupRequested(
            currentUserId: currentUserId,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            imageUrl: _groupImageUrl.isEmpty ? null : _groupImageUrl,
            participantIds: _selectedIds.toList(),
            onSuccess: (chatId, groupTitle) {
              if (mounted) {
                Navigator.of(context).pop(); // close new group screen
                context.push(
                  '/chat-room',
                  extra: {
                    'chatId': chatId,
                    'recipientName':
                        groupTitle.isEmpty ? 'New Group' : groupTitle,
                    'recipientId': '',
                    'conversationType': 'group',
                  },
                );
              }
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      appBar: AppTopBar(
        title: 'New Group Chat',
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) => TextButton(
              onPressed: state.isConversationsLoading ? null : _createGroup,
              child: Text(
                _selectedIds.isEmpty
                    ? 'Select Members'
                    : 'Create Group (${_selectedIds.length})',
                style: tt.bodyMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group image + name
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isUploadingImage ? null : _pickGroupImage,
                  child: CircleAvatar(
                    radius: 30.r,
                    backgroundColor: cs.surfaceContainerHigh,
                    backgroundImage:
                        _groupImageUrl.isNotEmpty && !_isUploadingImage
                            ? NetworkImage(_groupImageUrl)
                            : null,
                    child: _isUploadingImage
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                        : _groupImageUrl.isEmpty
                            ? Icon(IconsaxPlusLinear.camera,
                                size: 24.sp, color: cs.onSurfaceVariant)
                            : null,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Group name (optional)',
                      hintStyle:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected members chips
          if (_selectedUsers.isNotEmpty) ...[
            SizedBox(
              height: 52.h,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (_, i) {
                  final user = _selectedUsers.values.elementAt(i);
                  final id = user['userId']?.toString() ?? '';
                  final name = user['displayName']?.toString() ?? 'User';
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Chip(
                      label: Text(name, style: tt.bodySmall),
                      avatar: Avatar(name: name, size: 22),
                      deleteIcon: Icon(Icons.close, size: 14.sp),
                      onDeleted: () => setState(() {
                        _selectedIds.remove(id);
                        _selectedUsers.remove(id);
                      }),
                    ),
                  );
                },
              ),
            ),
            Divider(
                height: 1.h, color: cs.outlineVariant.withValues(alpha: 0.2)),
          ],

          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search connections...',
                prefixIcon: Icon(IconsaxPlusLinear.search_normal, size: 18.sp),
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

          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Search for people to add'
                              : 'No results',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (_, i) {
                          final user = _searchResults[i];
                          final id = user['userId']?.toString() ?? '';
                          final name =
                              user['displayName']?.toString() ?? 'User';
                          final avatar = user['avatarUrl']?.toString();
                          final isSelected = _selectedIds.contains(id);

                          return ListTile(
                            onTap: () => _toggleUser(user),
                            leading: Avatar(
                              name: name,
                              size: 40,
                              imageUrl: avatar,
                            ),
                            title: Text(name,
                                style: tt.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: cs.primary)
                                : Icon(
                                    Icons.radio_button_unchecked,
                                    color: cs.onSurfaceVariant,
                                  ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickGroupImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    final result = await PostsService.instance.uploadImage(File(picked.path));

    result.fold(
      (failure) {
        setState(() => _isUploadingImage = false);
        showGlobalToast(
            message: 'Failed to upload group image: ${failure.message}',
            status: 'error');
      },
      (data) {
        setState(() {
          _isUploadingImage = false;
          _groupImageUrl =
              data['mediaUrl']?.toString() ?? data['url']?.toString() ?? '';
        });
        showGlobalToast(
            message: 'Group image uploaded successfully!', status: 'success');
      },
    );
  }
}
