import 'dart:io';
import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:area_connect/src/features/create_activity/presentation/widgets/custom_calendar.dart';
import '../providers/business_bloc.dart';

/// Full-screen form for creating a business promotion.
class CreatePromotionScreen extends StatefulWidget {
  const CreatePromotionScreen({super.key});

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill business name from session if available.
    final user = context.read<SessionBloc>().state.user;
    if (user?.name != null) _nameCtrl.text = user!.name ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result =
        await MediaService.instance.pickImage(source: ImageSource.gallery);
    result.fold(
      (failure) => showGlobalToast(
          message: 'Failed to pick image: ${failure.message}', status: 'error'),
      (file) {
        if (file != null) setState(() => _selectedImages.add(file));
      },
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    // Upload images
    final List<String> mediaUrls = [];
    for (final img in _selectedImages) {
      final uploadRes = await PostsService.instance.uploadImage(img);
      uploadRes.fold(
        (failure) {
          showGlobalToast(
              message: 'Image upload failed: ${failure.message}',
              status: 'error');
        },
        (data) {
          // Backend returns { mediaUrl: '...', key: '...' }
          final url = data['mediaUrl']?.toString() ?? data['url']?.toString();
          if (url != null && url.isNotEmpty) mediaUrls.add(url);
        },
      );
    }

    // Get live location
    final locationRes = await LocationService.instance.getCurrentPosition();
    final coordinates = locationRes.fold(
      (_) => const [77.5946, 12.9716],
      (pos) => [pos.longitude, pos.latitude],
    );

    if (!mounted) return;

    context.read<BusinessBloc>().add(CreatePromotionRequested(
          businessName: _nameCtrl.text.trim(),
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          discountCode: _discountCtrl.text.trim().isEmpty
              ? null
              : _discountCtrl.text.trim(),
          coordinates: coordinates,
          expiryDate: _expiryDate.toUtc().toIso8601String(),
          mediaUrls: mediaUrls,
        ));

    setState(() => _isSubmitting = false);

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'New Promotion', centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Name
              AppTextField(
                controller: _nameCtrl,
                label: 'Business Name',
                prefixIcon: const Icon(IconsaxPlusLinear.shop),
                validator: (v) =>
                    Validators.required(v, fieldName: 'Business name'),
              ),
              SizedBox(height: AppSpacing.lg),

              // Title
              AppTextField(
                controller: _titleCtrl,
                label: 'Promotion Title',
                hint: 'e.g. 20% Off All Items',
                prefixIcon: const Icon(IconsaxPlusLinear.tag),
                validator: (v) => Validators.required(v, fieldName: 'Title'),
              ),
              SizedBox(height: AppSpacing.lg),

              // Description
              AppTextField(
                controller: _descCtrl,
                label: 'Description',
                hint: 'Describe your promotion...',
                maxLines: 3,
                validator: (v) =>
                    Validators.required(v, fieldName: 'Description'),
              ),
              SizedBox(height: AppSpacing.lg),

              // Discount Code
              AppTextField(
                controller: _discountCtrl,
                label: 'Discount Code (Optional)',
                hint: 'e.g. SAVE20',
                prefixIcon: const Icon(IconsaxPlusLinear.ticket_discount),
              ),
              SizedBox(height: AppSpacing.lg),

              // Expiry Date picker
              _label('EXPIRY DATE'),
              SizedBox(height: AppSpacing.sm.h),
              CustomCalendarWidget(
                initialDate: _expiryDate,
                onDateSelected: (date) {
                  setState(() => _expiryDate = date);
                },
              ),
              SizedBox(height: AppSpacing.lg.h),

              // Images section
              _label('PHOTOS'),
              SizedBox(height: AppSpacing.sm.h),
              if (_selectedImages.isNotEmpty) ...[
                SizedBox(
                  height: 100.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    separatorBuilder: (_, __) => SizedBox(width: 10.w),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.file(
                            _selectedImages[i],
                            width: 100.w,
                            height: 100.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedImages.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
                                  size: 14.w, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(IconsaxPlusLinear.gallery, size: 18),
                label:
                    Text(_selectedImages.isEmpty ? 'Add Photos' : 'Add More'),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: AppSpacing.xxl.h),

              // Submit
              AppButton(
                label: 'Publish Promotion',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
                isFullWidth: true,
              ),
              SizedBox(height: AppSpacing.lg.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.sp,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: context.theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
