import 'package:dio/dio.dart';
import 'package:food_app/core/api_client.dart';

class RatingRepository {
  /// ✅ Rate delivery driver or owner
  Future<Map<String, dynamic>> rateDriverOrOwner({
    required int? driverId,
    required int? ownerId,
    required int? orderId,
    required int rating,
    String? comment,
  }) async {
    
    try {
      await ApiClient.setAuthHeader();
      
      final data = {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
        if (driverId != null) 'driver_id': driverId,
        if (ownerId != null) 'owner_id': ownerId,
        if (orderId != null) 'order_id': orderId,
      };
      
      
      final res = await ApiClient.dio.post(
        '/client-rate',
        data: data,
      );
      
      return {
        'success': true,
        'data': res.data,
        'message': res.data['message'] ?? 'تم إرسال التقييم بنجاح'
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e, stack) {
      return {
        'success': false, 
        'message': 'حدث خطأ أثناء إرسال التقييم: $e'
      };
    }
  }

  /// ✅ Get last delivered order for rating
  Future<Map<String, dynamic>> getLastOrderForRating() async {
    try {
      await ApiClient.setAuthHeader();
      
      final res = await ApiClient.dio.get('/client/last-order');
      
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e, stack) {
      return {
        'success': false, 
        'message': 'حدث خطأ أثناء جلب آخر طلب: $e'
      };
    }
  }

  /// ✅ Mark order as skipped (not rated)
  Future<Map<String, dynamic>> markOrderAsSkipped(int orderId) async {
    try {
      await ApiClient.setAuthHeader();
          final res = await ApiClient.dio.put('/client/mark-as-skipped/$orderId');
      
      return {
        'success': true,
        'data': res.data,
        'message': res.data['message'] ?? 'تم تخطي التقييم بنجاح'
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e, stack) {
      return {
        'success': false, 
        'message': 'حدث خطأ أثناء تخطي التقييم: $e'
      };
    }
  }

  /// 🧩 دالة مساعدة لمعالجة أخطاء Dio
  Map<String, dynamic> _handleDioError(DioException e) {
    
    if (e.response != null) {
      final data = e.response?.data;
      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ من السيرفر',
        'errors': data['errors'] ?? {},
        'statusCode': e.response?.statusCode,
      };
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return {'success': false, 'message': '⏱ انتهى وقت الاتصال بالسيرفر'};
    } else if (e.type == DioExceptionType.connectionError) {
      return {'success': false, 'message': '⚠️ لا يوجد اتصال بالشبكة'};
    } else {
      return {'success': false, 'message': 'خطأ غير متوقع: ${e.message}'};
    }
  }
}