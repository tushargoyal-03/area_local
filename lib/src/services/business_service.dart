import 'package:area_connect/src/imports/imports.dart';

class BusinessService {
  BusinessService._();
  static final BusinessService instance = BusinessService._();

  FutureEither<List<dynamic>> getNearbyPromotions({
    double? lng,
    double? lat,
    double? radiusInKm,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> queryParameters = {'page': page, 'limit': limit};
    if (lng != null) queryParameters['lng'] = lng;
    if (lat != null) queryParameters['lat'] = lat;
    if (radiusInKm != null) queryParameters['radiusInKm'] = radiusInKm;

    final result = await DioService.instance.get(
      'business/promotions/nearby',
      queryParameters: queryParameters,
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['promotions'] as List<dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to load nearby promotions: $e'));
      }
    });
  }

  FutureEither<Map<String, dynamic>> createPromotion({
    required String businessName,
    required String title,
    required String description,
    required List<double> coordinates,
    String? discountCode,
    String? expiryDate,
    List<String> mediaUrls = const [],
  }) async {
    final Map<String, dynamic> data = {
      'businessName': businessName,
      'title': title,
      'description': description,
      'coordinates': coordinates,
    };
    if (discountCode != null) data['discountCode'] = discountCode;
    if (expiryDate != null) data['expiryDate'] = expiryDate;
    if (mediaUrls.isNotEmpty) data['mediaUrls'] = mediaUrls;

    final result = await DioService.instance.post(
      'business/promotions',
      data: data,
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['data'] as Map<String, dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to create promotion: $e'));
      }
    });
  }

  FutureEither<List<dynamic>> getMyPromotions({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await DioService.instance.get(
      'business/promotions/mine',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    return result.flatMap((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return right(responseData['promotions'] as List<dynamic>);
      } catch (e) {
        return left(ServerFailure('Failed to load my promotions: $e'));
      }
    });
  }

  /// Track IMPRESSION, CLICK, or SAVE event on a promotion.
  FutureEither<void> trackEvent(String promotionId, String event) async {
    final result = await DioService.instance.post(
      'business/promotions/$promotionId/track',
      data: {'event': event},
    );
    return result.map((_) {});
  }

  /// Get analytics for a promotion (owner or SuperAdmin only).
  FutureEither<Map<String, dynamic>> getAnalytics(String promotionId) async {
    final result = await DioService.instance.get(
      'business/promotions/$promotionId/analytics',
    );
    return result.flatMap((response) {
      try {
        final data = response.data as Map<String, dynamic>;
        return right(data['data'] as Map<String, dynamic>? ?? data);
      } catch (e) {
        return left(ServerFailure('Failed to load analytics: $e'));
      }
    });
  }

  /// Get saved promotions for the current user.
  FutureEither<List<dynamic>> getSavedPromotions({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await DioService.instance.get(
      'business/promotions/saved',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['promotions'] as List<dynamic>;
      } catch (e) {
        throw Exception('Failed to load saved promotions: $e');
      }
    });
  }

  /// Toggle save status for a promotion.
  FutureEither<Map<String, dynamic>> toggleSavePromotion(
      String promotionId) async {
    final result = await DioService.instance.post(
      'business/promotions/$promotionId/save',
    );
    return result.map((response) {
      final data = response.data as Map<String, dynamic>;
      return data['data'] as Map<String, dynamic>? ?? data;
    });
  }
}
