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
    print('🔄 [RatingRepository] rateDriverOrOwner() called');
    print('🔍 [RatingRepository] driverId: $driverId, ownerId: $ownerId, orderId: $orderId, rating: $rating');
    
    try {
      print('🔐 [RatingRepository] Setting auth header...');
      await ApiClient.setAuthHeader();
      
      final data = {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
        if (driverId != null) 'driver_id': driverId,
        if (ownerId != null) 'owner_id': ownerId,
        if (orderId != null) 'order_id': orderId,
      };
      
      print('📤 [RatingRepository] POST → /client-rate');
      print('📤 [RatingRepository] Data: $data');
      
      final res = await ApiClient.dio.post(
        '/client-rate',
        data: data,
      );

      print('✅ [RatingRepository] Rating submitted successfully');
      print('📥 [RatingRepository] Response: ${res.data}');
      
      return {
        'success': true,
        'data': res.data,
        'message': res.data['message'] ?? 'تم إرسال التقييم بنجاح'
      };
    } on DioException catch (e) {
      print('❌ [RatingRepository] Dio error in rateDriverOrOwner: ${e.message}');
      print('🔍 [RatingRepository] Dio error type: ${e.type}');
      print('🔍 [RatingRepository] Dio response: ${e.response?.data}');
      return _handleDioError(e);
    } catch (e, stack) {
      print('❌ [RatingRepository] General error in rateDriverOrOwner: $e');
      print('🔍 [RatingRepository] Stack trace: $stack');
      return {
        'success': false, 
        'message': 'حدث خطأ أثناء إرسال التقييم: $e'
      };
    }
  }

  /// ✅ Get last delivered order for rating
  Future<Map<String, dynamic>> getLastOrderForRating() async {
    print('🔄 [RatingRepository] getLastOrderForRating() called');
    try {
      print('🔐 [RatingRepository] Setting auth header...');
      await ApiClient.setAuthHeader();
      
      print('📤 [RatingRepository] GET → /client/last-order');
      final res = await ApiClient.dio.get('/client/last-order');

      print('✅ [RatingRepository] Last order loaded successfully');
      print('📥 [RatingRepository] Response: ${res.data}');
      
      return {
        'success': true,
        'data': res.data,
      };
    } on DioException catch (e) {
      print('❌ [RatingRepository] Dio error in getLastOrderForRating: ${e.message}');
      print('🔍 [RatingRepository] Dio error type: ${e.type}');
      print('🔍 [RatingRepository] Dio response: ${e.response?.data}');
      return _handleDioError(e);
    } catch (e, stack) {
      print('❌ [RatingRepository] General error in getLastOrderForRating: $e');
      print('🔍 [RatingRepository] Stack trace: $stack');
      return {
        'success': false, 
        'message': 'حدث خطأ أثناء جلب آخر طلب: $e'
      };
    }
  }

  /// ✅ Mark order as skipped (not rated)
  Future<Map<String, dynamic>> markOrderAsSkipped(int orderId) async {
    print('🔄 [RatingRepository] markOrderAsSkipped() called for orderId: $orderId');
    try {
      print('🔐 [RatingRepository] Setting auth header...');
      await ApiClient.setAuthHeader();
      
      print('📤 [RatingRepository] PUT → /client/mark-as-skipped/$orderId');
      final res = await ApiClient.dio.put('/client/mark-as-skipped/$orderId');

      print('✅ [RatingRepository] Order marked as skipped successfully');
      print('📥 [RatingRepository] Response: ${res.data}');
      
      return {
        'success': true,
        'data': res.data,
        'message': res.data['message'] ?? 'تم تخطي التقييم بنجاح'
      };
    } on DioException catch (e) {
      print('❌ [RatingRepository] Dio error in markOrderAsSkipped: ${e.message}');
      print('🔍 [RatingRepository] Dio error type: ${e.type}');
      print('🔍 [RatingRepository] Dio response: ${e.response?.data}');
      return _handleDioError(e);
    } catch (e, stack) {
      print('❌ [RatingRepository] General error in markOrderAsSkipped: $e');
      print('🔍 [RatingRepository] Stack trace: $stack');
      return {
        'success': false, 
        'message': 'حدث خطأ أثناء تخطي التقييم: $e'
      };
    }
  }

  /// 🧩 دالة مساعدة لمعالجة أخطاء Dio
  Map<String, dynamic> _handleDioError(DioException e) {
    print('🔧 [RatingRepository] Handling Dio error: ${e.type}');
    
    if (e.response != null) {
      final data = e.response?.data;
      print('🔧 [RatingRepository] Dio response error: $data');
      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ من السيرفر',
        'errors': data['errors'] ?? {},
        'statusCode': e.response?.statusCode,
      };
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      print('🔧 [RatingRepository] Timeout error');
      return {'success': false, 'message': '⏱ انتهى وقت الاتصال بالسيرفر'};
    } else if (e.type == DioExceptionType.connectionError) {
      print('🔧 [RatingRepository] Connection error');
      return {'success': false, 'message': '⚠️ لا يوجد اتصال بالشبكة'};
    } else {
      print('🔧 [RatingRepository] Other Dio error: ${e.message}');
      return {'success': false, 'message': 'خطأ غير متوقع: ${e.message}'};
    }
  }
}