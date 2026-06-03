import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import '../providers/society_feed_bloc.dart';

/// Screen used by a SocietyAdmin to register a brand-new society.
///
/// On success, the [SocietyFeedBloc] switches to the freshly created society
/// and loads its (empty) feed, so the admin lands straight in their society hub.
class CreateSocietyScreen extends StatefulWidget {
  const CreateSocietyScreen({super.key});

  @override
  State<CreateSocietyScreen> createState() => _CreateSocietyScreenState();
}

class _CreateSocietyScreenState extends State<CreateSocietyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  List<double>? _coordinates; // [lng, lat]
  String? _capturedAddress;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    // Try to prefill location immediately for convenience.
    _useCurrentLocation(silent: true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    setState(() => _isLocating = true);

    final posRes = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;

    await posRes.fold(
      (failure) async {
        if (!silent) {
          showGlobalToast(
            message: 'Could not get location: ${failure.message}',
            status: 'error',
          );
        }
      },
      (position) async {
        _coordinates = [position.longitude, position.latitude];
        _capturedAddress =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
        if (mounted) setState(() {});

        // Reverse geocode to pre-fill address/city fields.
        final addrRes = await LocationService.instance
            .getAddressFromCoordinates(position.latitude, position.longitude);
        if (!mounted) return;
        addrRes.fold(
          (_) {},
          (address) {
            final parts = address.split(',');
            if (_addressCtrl.text.isEmpty) {
              _addressCtrl.text = address;
            }
            if (_cityCtrl.text.isEmpty && parts.length >= 2) {
              _cityCtrl.text = parts.last.trim();
            }
            if (mounted) {
              setState(() {
                _capturedAddress = address;
              });
            }
          },
        );

        if (!silent) {
          showGlobalToast(message: 'Location captured', status: 'success');
        }
      },
    );

    if (mounted) setState(() => _isLocating = false);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_coordinates == null) {
      showGlobalToast(
        message: 'Please capture the society location first',
        status: 'error',
      );
      return;
    }

    context.read<SocietyFeedBloc>().add(
          CreateSocietyRequested(
            name: _nameCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            coordinates: _coordinates!,
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            onSuccess: () {
              if (mounted) context.pop();
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final isCreating =
        context.select((SocietyFeedBloc b) => b.state.isCreatingSociety);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AppTopBar(title: 'Create Society', centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xs.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.lg.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D6E), Color(0xFF4CAF96)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(IconsaxPlusBold.home_1,
                          color: Colors.white, size: 30.w),
                      SizedBox(height: 10.h),
                      Text(
                        'Register your society',
                        style: tt.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Residents nearby can discover and request to join. You become its admin.',
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),

                _label('Society Name'),
                SizedBox(height: AppSpacing.sm.h),
                AppTextField(
                  controller: _nameCtrl,
                  hint: 'e.g. Vaishali Heights, Tower B',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Society name is required';
                    }
                    if (v.trim().length < 3) return 'Name is too short';
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.lg.h),

                _label('Description (optional)'),
                SizedBox(height: AppSpacing.sm.h),
                AppTextField(
                  controller: _descCtrl,
                  hint: 'A short note about your society…',
                  maxLines: 3,
                ),
                SizedBox(height: AppSpacing.lg.h),

                _label('Address'),
                SizedBox(height: AppSpacing.sm.h),
                AppTextField(
                  controller: _addressCtrl,
                  hint: 'Street / building address',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Address is required'
                      : null,
                ),
                SizedBox(height: AppSpacing.lg.h),

                _label('City'),
                SizedBox(height: AppSpacing.sm.h),
                AppTextField(
                  controller: _cityCtrl,
                  hint: 'e.g. Jaipur',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'City is required'
                      : null,
                ),
                SizedBox(height: AppSpacing.lg.h),

                // Location capture
                _label('Society Location'),
                SizedBox(height: AppSpacing.sm.h),
                Container(
                  padding: EdgeInsets.all(AppSpacing.md.w),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      if (_coordinates != null)
                        Icon(IconsaxPlusBold.location,
                            color: cs.primary, size: 20.w)
                      else
                        Icon(IconsaxPlusLinear.location,
                            color: cs.onSurfaceVariant, size: 20.w),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _coordinates != null
                              ? (_capturedAddress ??
                                  'Location captured (${_coordinates![1].toStringAsFixed(4)}, ${_coordinates![0].toStringAsFixed(4)})')
                              : 'No location captured yet',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (_isLocating)
                        SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        TextButton(
                          onPressed: () => _useCurrentLocation(),
                          child:
                              Text(_coordinates != null ? 'Update' : 'Capture'),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.xl.h),

                AppButton(
                  label: 'Create Society',
                  isLoading: isCreating,
                  onPressed: isCreating ? null : _submit,
                  isFullWidth: true,
                ),
                SizedBox(height: AppSpacing.lg.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    final cs = context.theme.colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11.sp,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
