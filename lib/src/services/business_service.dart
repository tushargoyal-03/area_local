import 'package:area_connect/src/imports/imports.dart';

class BusinessService {
  BusinessService._();
  static final BusinessService instance = BusinessService._();

  FutureEither<List<dynamic>> getNearbyPromotions({
    required double lng,
    required double lat,
    double radiusInKm = 5,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await DioService.instance.get(
      'business/promotions/nearby',
      queryParameters: {
        'lng': lng,
        'lat': lat,
        'radiusInKm': radiusInKm,
        'page': page,
        'limit': limit,
      },
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['promotions'] as List<dynamic>;
      } catch (e) {
        throw Exception('Failed to load nearby promotions: $e');
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
  }) async {
    final Map<String, dynamic> data = {
      'businessName': businessName,
      'title': title,
      'description': description,
      'coordinates': coordinates,
    };
    if (discountCode != null) data['discountCode'] = discountCode;
    if (expiryDate != null) data['expiryDate'] = expiryDate;

    final result = await DioService.instance.post(
      'business/promotions',
      data: data,
    );

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['data'] as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to create promotion: $e');
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

    return result.map((response) {
      try {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['promotions'] as List<dynamic>;
      } catch (e) {
        throw Exception('Failed to load my promotions: $e');
      }
    });
  }
}
