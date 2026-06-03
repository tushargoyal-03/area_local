import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

/// Lets a resident discover verified societies near them and send a request to
/// join. Sending a request is what creates the PENDING entries that a
/// SocietyAdmin later approves/rejects on the Join Requests screen.
class SocietyDiscoverList extends StatefulWidget {
  final double lat;
  final double lng;

  const SocietyDiscoverList({
    super.key,
    required this.lat,
    required this.lng,
  });

  @override
  State<SocietyDiscoverList> createState() => _SocietyDiscoverListState();
}

class _SocietyDiscoverListState extends State<SocietyDiscoverList> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _societies = [];

  /// Local tracking of societies the user just requested to join this session,
  /// so the button flips to "Requested" without needing a full reload.
  final Set<String> _requested = {};
  final Set<String> _submitting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await SocietiesService.instance.getNearbySocieties(
      lng: widget.lng,
      lat: widget.lat,
    );

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _error = failure.message;
      }),
      (list) => setState(() {
        _isLoading = false;
        _societies =
            list.whereType<Map<String, dynamic>>().toList(growable: false);
      }),
    );
  }

  Future<void> _requestJoin(String societyId) async {
    setState(() => _submitting.add(societyId));

    final result =
        await SocietiesService.instance.requestToJoin(societyId: societyId);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _submitting.remove(societyId));
        showGlobalToast(message: failure.message, status: 'error');
      },
      (_) {
        setState(() {
          _submitting.remove(societyId);
          _requested.add(societyId);
        });
        showGlobalToast(
            message: 'Join request sent. The society admin will review it.',
            status: 'success');
      },
    );
  }

  /// Reads the membership/request status the backend may attach to a society.
  String _statusFor(Map<String, dynamic> society, String societyId) {
    if (society['isMember'] == true ||
        (society['membershipStatus']?.toString().toUpperCase() == 'ACTIVE')) {
      return 'MEMBER';
    }
    final reqStatus = (society['joinRequestStatus'] ??
            society['requestStatus'] ??
            society['myRequestStatus'])
        ?.toString()
        .toUpperCase();
    if (reqStatus == 'PENDING' || _requested.contains(societyId)) {
      return 'REQUESTED';
    }
    if (reqStatus == 'APPROVED') return 'MEMBER';
    return 'NONE';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: Column(
          children: [
            Icon(IconsaxPlusLinear.warning_2,
                size: 40.w, color: cs.onSurfaceVariant),
            SizedBox(height: 12.h),
            Text(_error!,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            SizedBox(height: 12.h),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_societies.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: Column(
          children: [
            Icon(IconsaxPlusLinear.home_1,
                size: 44.w, color: cs.onSurfaceVariant),
            SizedBox(height: 12.h),
            Text('No societies found nearby.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            SizedBox(height: 6.h),
            Text('Try again from a different location.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ).center;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(IconsaxPlusLinear.home_1, size: 16.sp, color: cs.primary),
            SizedBox(width: 6.w),
            Text('${_societies.length} societies near you',
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 14.h),
        ..._societies.map((society) {
          final id = (society['_id'] ?? society['id'] ?? '').toString();
          final name = society['name']?.toString() ?? 'Society';
          final address = society['address']?.toString() ??
              society['city']?.toString() ??
              '';
          final isVerified = society['isVerified'] == true;
          final status = _statusFor(society, id);

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20.r),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Icon(IconsaxPlusLinear.home_1, color: cs.primary),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(name,
                                style: tt.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (isVerified) ...[
                            SizedBox(width: 6.w),
                            Icon(Icons.verified, size: 14.w, color: cs.primary),
                          ],
                        ],
                      ),
                      if (address.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(address,
                            style: tt.bodySmall?.copyWith(
                                fontSize: 11.sp, color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                _buildAction(id, status, cs, tt),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAction(
      String societyId, String status, ColorScheme cs, TextTheme tt) {
    if (_submitting.contains(societyId)) {
      return SizedBox(
        width: 18.w,
        height: 18.w,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (status) {
      case 'MEMBER':
        return _Badge(label: 'Member', color: const Color(0xFF2E7D32), tt: tt);
      case 'REQUESTED':
        return _Badge(label: 'Requested', color: Colors.orange, tt: tt);
      default:
        return ElevatedButton(
          onPressed: societyId.isEmpty ? null : () => _requestJoin(societyId),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)),
          ),
          child: Text('Join', style: TextStyle(fontSize: 11.sp)),
        );
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final TextTheme tt;

  const _Badge({required this.label, required this.color, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10.sp,
        ),
      ),
    );
  }
}
