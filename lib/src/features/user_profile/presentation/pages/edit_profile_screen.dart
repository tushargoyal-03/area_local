import 'dart:io';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import '../providers/user_profile_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _lookingForController;
  String? _pendingAvatarUrl;
  File? _localAvatarFile;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _lookingForController = TextEditingController();
    context.read<UserProfileBloc>().add(LoadMyProfile());
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _lookingForController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _localAvatarFile = File(picked.path);
    });
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final tags = _lookingForController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      context.read<UserProfileBloc>().add(UpdateProfileRequested(
            displayName: _displayNameController.text.trim(),
            avatarFile: _localAvatarFile,
            lookingFor: tags.isNotEmpty ? tags : null,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return BlocConsumer<UserProfileBloc, UserProfileState>(
      listener: (context, state) {
        if (state.updateSuccess) {
          if (mounted) Navigator.pop(context);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.myProfile == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        Map<String, dynamic>? profileData;
        if (state.myProfile != null) {
          if (state.myProfile!['profile'] is Map) {
            profileData =
                Map<String, dynamic>.from(state.myProfile!['profile'] as Map);
          } else {
            profileData = state.myProfile;
          }
        }

        if (profileData != null && _displayNameController.text.isEmpty) {
          _displayNameController.text = profileData['displayName'] ?? '';
          if (profileData['lookingFor'] != null) {
            _lookingForController.text =
                (profileData['lookingFor'] as List).join(', ');
          }
        }

        final displayedAvatar =
            _pendingAvatarUrl ?? profileData?['avatarUrl']?.toString();

        return Scaffold(
          appBar: const AppTopBar(
            title: 'Edit Profile',
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50.r,
                              backgroundColor: cs.surfaceContainerHigh,
                              backgroundImage: _localAvatarFile != null
                                  ? FileImage(_localAvatarFile!)
                                      as ImageProvider
                                  : (displayedAvatar != null
                                      ? NetworkImage(displayedAvatar)
                                      : null),
                              child: _localAvatarFile == null &&
                                      displayedAvatar == null
                                  ? Icon(Icons.person,
                                      size: 50.r, color: cs.onSurfaceVariant)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.camera_alt,
                                    color: cs.onPrimary, size: 16.r),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_localAvatarFile != null)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            'New photo selected',
                            style: tt.bodySmall?.copyWith(color: cs.primary),
                          ),
                        ),
                      ),
                    SizedBox(height: AppSpacing.xl.h),
                    Text('Display Name', style: tt.labelLarge),
                    SizedBox(height: AppSpacing.sm.h),
                    AppTextField(
                      controller: _displayNameController,
                      hint: 'Enter your name',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    Text('Looking For (comma separated)', style: tt.labelLarge),
                    SizedBox(height: AppSpacing.sm.h),
                    AppTextField(
                      controller: _lookingForController,
                      hint: 'e.g. Tennis, Coding, Networking',
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    AppButton(
                      label: 'Save Changes',
                      isLoading: state.isUpdating,
                      onPressed: _onSave,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
