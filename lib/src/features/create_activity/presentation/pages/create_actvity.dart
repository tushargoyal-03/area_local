import 'dart:convert';
import 'dart:io';
import 'package:area_connect/src/imports/imports.dart';
import 'package:area_connect/src/features/create_activity/presentation/widgets/custom_calendar.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  List<String> categories = [
    'Society',
    'Sports',
    'Events',
    'Help',
    'Hobbies',
    'General',
  ];

  int selectedIndex = 0;

  // Dynamic Options States
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0); // 6:00 PM
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0); // 8:00 PM
  String _locationName = 'JLN Sports Club';
  int _capacityCount = 2;

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImageFromCamera() async {
    final result =
        await MediaService.instance.pickImage(source: ImageSource.camera);
    result.fold(
      (failure) {
        showGlobalToast(
          message: 'Failed to take photo: ${failure.message}',
          status: 'error',
        );
      },
      (image) {
        if (image != null && mounted) {
          setState(() {
            _selectedImage = image;
          });
          showGlobalToast(
            message: 'Photo captured successfully!',
            status: 'success',
          );
        }
      },
    );
  }

  Future<void> _shareImage() async {
    if (_selectedImage == null) return;
    final shareRes = await ShareService.instance.shareFiles(
      [_selectedImage!.path],
      text: 'Sharing my activity photo!',
    );
    shareRes.fold(
      (failure) {
        showGlobalToast(
          message: 'Failed to share photo: ${failure.message}',
          status: 'error',
        );
      },
      (result) {
        // Shared successfully
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _formatDateDisplay(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isTomorrow = date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;

    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final weekdayStr = weekdays[date.weekday % 7];
    final monthStr = months[date.month - 1];

    if (isToday) return 'Today, $monthStr ${date.day}';
    if (isTomorrow) return 'Tomorrow, $monthStr ${date.day}';
    return '$weekdayStr, $monthStr ${date.day}';
  }

  String _formatTimeDisplay(TimeOfDay start, TimeOfDay end) {
    String formatTimeOfDay(TimeOfDay tod) {
      final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
      final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
      final minuteStr = tod.minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $period';
    }

    return '${formatTimeOfDay(start)} – ${formatTimeOfDay(end)}';
  }

  Widget _buildTimePickerColumn(
    String label,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged,
  ) {
    final cs = context.theme.colorScheme;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 120.h,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: false,
              initialDateTime: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                time.hour,
                time.minute,
              ),
              onDateTimeChanged: (newTime) {
                onChanged(TimeOfDay.fromDateTime(newTime));
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectLocation() async {
    final controller = TextEditingController(text: _locationName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: const Text('Activity Location/Venue'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'e.g. JLN Sports Club, V.N.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100.r)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _locationName = result);
    }
  }

  Future<void> _selectCapacity() async {
    int localCount = _capacityCount;
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        final cs = context.theme.colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r)),
              title: Text(
                'Required People Limit',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: localCount > 1
                        ? () => setDialogState(() => localCount--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(width: 20.w),
                  Text(
                    '$localCount',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  IconButton.filledTonal(
                    onPressed: localCount < 100
                        ? () => setDialogState(() => localCount++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, localCount),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.r)),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null && mounted) {
      setState(() => _capacityCount = result);
    }
  }

  String _mapToBackendCategory(String uiCategory) {
    if (uiCategory == 'Events') return 'Meetup';
    if (uiCategory == 'Help') return 'Request';
    if (uiCategory == 'Hobbies') return 'Need';
    return uiCategory;
  }

  Future<void> _handlePost() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final contentText = _contentController.text.trim();
    final uiCategory = categories[selectedIndex];
    final backendCategory = _mapToBackendCategory(uiCategory);

    // Dynamic metadata serialization in JSON format inside 'content' field
    final content = jsonEncode({
      'description': contentText,
      'date': _formatDateDisplay(_selectedDate),
      'time': _formatTimeDisplay(_startTime, _endTime),
      'location': _locationName,
      'capacity':
          '$_capacityCount ${_capacityCount == 1 ? 'person' : 'people'}',
    });

    // Validate start time is in the future
    final now = DateTime.now();
    final eventTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    if (eventTime.isBefore(now)) {
      showGlobalToast(
        message: 'Event start time must be in the future',
        status: 'error',
      );
      return;
    }

    // Validate end time is after start time
    if (_startTime.hour == _endTime.hour &&
        _startTime.minute == _endTime.minute) {
      showGlobalToast(
        message: 'End time must be after start time',
        status: 'error',
      );
      return;
    }

    final user = context.read<SessionBloc>().state.user;
    final fallbackCoordinates = user?.coordinates ?? const [77.5946, 12.9716];

    final locationRes = await LocationService.instance.getCurrentPosition();

    final coordinates = locationRes.fold(
      (failure) => fallbackCoordinates,
      (position) => [position.longitude, position.latitude],
    );

    if (mounted) {
      context.read<PostsBloc>().add(
            CreatePostRequested(
              currentUser: user,
              category: backendCategory,
              title: title,
              content: content,
              coordinates: coordinates,
              image: _selectedImage,
              maxParticipants: _capacityCount,
              eventTime: eventTime,
              onSuccess: (newPost) {
                if (mounted) {
                  context.pop();
                }
              },
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final isCreating =
        context.select((PostsBloc bloc) => bloc.state.isCreating);

    return Scaffold(
      appBar: AppTopBar(
        title: categories[selectedIndex] == 'Advertisement'
            ? 'New Advertisement'
            : 'New activity',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpacing.xs.w, AppSpacing.xs.h,
              AppSpacing.xs.w, AppSpacing.xs.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      categories.length,
                      (index) {
                        final selected = selectedIndex == index;
                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: GestureDetector(
                            onTap: () => setState(() => selectedIndex = index),
                            child: AnimatedContainer(
                              duration: AppDurations.fast,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: selected
                                    ? cs.primary
                                    : cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(100.r),
                                border: Border.all(
                                  color: selected
                                      ? cs.primary
                                      : cs.outlineVariant
                                          .withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                categories[index],
                                style: tt.labelLarge?.copyWith(
                                  color: selected
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.lg.h),

                // Title section
                _SectionLabel(categories[selectedIndex] == 'Advertisement'
                    ? 'Business / Shop Name'
                    : 'Title'),
                SizedBox(height: AppSpacing.sm.h),
                TextFormField(
                  controller: _titleController,
                  enabled: !isCreating,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: categories[selectedIndex] == 'Advertisement'
                        ? "e.g. Priya's Cozy Cafe..."
                        : 'Need a pickleball partner...',
                    hintStyle: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: 2,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (v.trim().length > 80) return 'Title is too long';
                    return null;
                  },
                ),

                SizedBox(height: AppSpacing.lg.h),

                // Description section
                _SectionLabel(categories[selectedIndex] == 'Advertisement'
                    ? 'Advertisement Description'
                    : 'Description'),
                SizedBox(height: AppSpacing.sm.h),
                TextFormField(
                  controller: _contentController,
                  enabled: !isCreating,
                  maxLines: 5,
                  style: tt.bodyMedium,
                  decoration: InputDecoration(
                    hintText: categories[selectedIndex] == 'Advertisement'
                        ? 'Describe your shop, special discount deals, active promo code, products or store hours...'
                        : 'Describe details, skill level, date/time, and exact location...',
                    hintStyle: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppSpacing.lg.h),

                // Date Picker Inline
                const _SectionLabel('Select Date'),
                SizedBox(height: AppSpacing.sm.h),
                CustomCalendarWidget(
                  initialDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() => _selectedDate = date);
                  },
                ),
                SizedBox(height: AppSpacing.lg.h),

                // Time Picker Inline
                const _SectionLabel('Select Time'),
                SizedBox(height: AppSpacing.sm.h),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(24.r),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimePickerColumn('Start Time', _startTime, (time) {
                        setState(() => _startTime = time);
                      }),
                      Container(
                        width: 1,
                        height: 60.h,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      _buildTimePickerColumn('End Time', _endTime, (time) {
                        setState(() => _endTime = time);
                      }),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),

                // Dynamic options labels
                _SectionLabel(categories[selectedIndex] == 'Advertisement'
                    ? 'Promotion Location & Capacity'
                    : 'Activity Location & Capacity'),
                SizedBox(height: AppSpacing.sm.h),

                // Location and Capacity
                Row(
                  children: [
                    Expanded(
                      child: _FormRow(
                        icon: IconsaxPlusLinear.map,
                        label: _locationName,
                        onTap: _selectLocation,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _FormRow(
                        icon: IconsaxPlusLinear.user,
                        label:
                            '$_capacityCount ${_capacityCount == 1 ? 'person' : 'people'}',
                        onTap: _selectCapacity,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.lg.h),

                // Photo upload
                GestureDetector(
                  onTap: _selectedImage == null ? _pickImageFromCamera : null,
                  child: Container(
                    height: 110.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImage != null
                        ? Stack(
                            children: [
                              Positioned.fill(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8.h,
                                right: 8.w,
                                child: Row(
                                  children: [
                                    // Share button
                                    GestureDetector(
                                      onTap: _shareImage,
                                      child: Container(
                                        padding: EdgeInsets.all(8.r),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.share_rounded,
                                          size: 16.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    // Delete/Remove button
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImage = null;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(8.r),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          IconsaxPlusLinear.trash,
                                          size: 16.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconsaxPlusLinear.camera,
                                size: 28.sp,
                                color: cs.onSurfaceVariant,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                categories[selectedIndex] == 'Advertisement'
                                    ? 'Add business cover banner (Highly recommended)'
                                    : 'Add a photo (optional)',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: AppSpacing.xl.h),

                // Post button
                AppButton(
                  label: categories[selectedIndex] == 'Advertisement'
                      ? 'Publish Advertisement'
                      : 'Post Activity',
                  isLoading: isCreating,
                  onPressed: isCreating ? null : _handlePost,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ─── Section Label ─────────────────────────────────────────────────── */

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
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

/* ─── Form Row ──────────────────────────────────────────────────────── */

class _FormRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FormRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17.sp,
                color: cs.primary,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ).paddingSymmetric(
              horizontal: AppSpacing.xs.w, vertical: AppSpacing.xs.h),
        ),
      ),
    );
  }
}
