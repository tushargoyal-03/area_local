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
  
  // To keep it simple, we'll store tags as a single comma-separated string 
  // or manage them as a list. For now, simple text controller.
  late TextEditingController _lookingForController; 

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _lookingForController = TextEditingController();
    
    // Load current profile
    context.read<UserProfileBloc>().add(LoadMyProfile());
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _lookingForController.dispose();
    super.dispose();
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state.myProfile != null && _displayNameController.text.isEmpty) {
          _displayNameController.text = state.myProfile!['displayName'] ?? '';
          if (state.myProfile!['lookingFor'] != null) {
             _lookingForController.text = (state.myProfile!['lookingFor'] as List).join(', ');
          }
        }

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
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50.r,
                            backgroundColor: cs.surfaceContainerHigh,
                            backgroundImage: state.myProfile?['avatarUrl'] != null 
                                ? NetworkImage(state.myProfile!['avatarUrl'])
                                : null,
                            child: state.myProfile?['avatarUrl'] == null 
                                ? Icon(Icons.person, size: 50.r, color: cs.onSurfaceVariant)
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
                              child: Icon(Icons.camera_alt, color: cs.onPrimary, size: 16.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl.h),
                    Text('Display Name', style: tt.labelLarge),
                    SizedBox(height: AppSpacing.sm.h),
                    AppTextField(
                      controller: _displayNameController,
                      hint: 'Enter your name',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Name is required';
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
