import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final token = ref.watch(authTokenProvider);
  return ApiService(token: token);
});

class ApiService {
  final String? token;
  late final Dio _dio;

  ApiService({this.token}) {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/api/v1',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: headers,
    ));
  }

  // --- Admin APIs ---
  Future<List<dynamic>> getPendingCompanies() async {
    final res = await _dio.get('/admin/companies/pending');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> approveCompany(int companyId) async {
    final res = await _dio.post('/admin/companies/$companyId/approve');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> rejectCompany(int companyId) async {
    final res = await _dio.post('/admin/companies/$companyId/reject');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<List<dynamic>> getAllUsers() async {
    final res = await _dio.get('/admin/users');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> toggleUserStatus(int userId) async {
    final res = await _dio.post('/admin/users/$userId/toggle-status');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> getAdminMetrics() async {
    final res = await _dio.get('/admin/dashboard/metrics');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> getEnvironmentalPrediction({String? query}) async {
    final res = await _dio.get('/admin/ai/environmental-prediction', queryParameters: {
      if (query != null && query.isNotEmpty) 'query': query,
    });
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> generateEnvironmentalPrediction({String? query}) async {
    final res = await _dio.post('/admin/ai/environmental-prediction/generate', data: {
      if (query != null && query.isNotEmpty) 'query': query,
    });
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> getGeminiConfig() async {
    final res = await _dio.get('/admin/ai/gemini-config');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> saveGeminiConfig(String apiKey) async {
    final res = await _dio.post('/admin/ai/gemini-config', data: {
      'apiKey': apiKey,
    });
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> updateEconomicsRule(String key, String value) async {
    final res = await _dio.post('/admin/config/economics', data: {
      'key': key,
      'value': value,
    });
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<List<dynamic>> getAuditLogs() async {
    final res = await _dio.get('/admin/audit-logs');
    return (res.data as List<dynamic>?) ?? [];
  }

  // --- Company APIs ---
  Future<Map<String, dynamic>> getCompanyDashboard() async {
    final res = await _dio.get('/company/dashboard');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<List<dynamic>> getAssignedBooths() async {
    final res = await _dio.get('/company/booths');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> getPickupRequests({String? status}) async {
    final res = await _dio.get('/company/pickup-requests', queryParameters: {
      if (status != null) 'status': status,
    });
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> acceptPickup(int pickupId) async {
    final res = await _dio.post('/company/pickup-requests/$pickupId/accept');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> assignVehicle(int pickupId, int vehicleId) async {
    final res = await _dio.post('/company/pickup-requests/$pickupId/assign-vehicle', data: {
      'vehicleId': vehicleId,
    });
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> dispatchBoothCollection(int boothId) async {
    final res = await _dio.post('/company/booths/$boothId/dispatch');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<List<dynamic>> getVehicles() async {
    final res = await _dio.get('/company/vehicles');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> getCollections() async {
    final res = await _dio.get('/company/collections');
    return (res.data as List<dynamic>?) ?? [];
  }

  // --- User APIs ---
  Future<Map<String, dynamic>> getUserDashboard() async {
    final res = await _dio.get('/me/dashboard');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<List<dynamic>> getCoupons() async {
    final res = await _dio.get('/coupons');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> redeemCoupon(int couponId) async {
    final res = await _dio.post('/coupons/$couponId/redeem');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> withdrawToBkash(int tokens, String bkashNumber) async {
    final res = await _dio.post('/me/withdraw', data: {
      'tokens': tokens,
      'bkashNumber': bkashNumber,
    });
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> createDepositSession(int boothId, String qrToken) async {
    final res = await _dio.post('/deposit-sessions', data: {
      'boothId': boothId.toString(),
      'qrToken': qrToken,
    });
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> generateBoothQr(int boothId) async {
    final res = await _dio.post('/booths/$boothId/qr');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> submitDepositWeight(int boothId, String sessionId, double weightKg) async {
    final res = await _dio.post('/booths/$boothId/deposit-sessions/$sessionId/weight', data: {
      'weightKg': weightKg,
      'plasticType': 'PET 100% Sorted',
    });
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<List<dynamic>> getUserTransactions() async {
    final res = await _dio.get('/me/transactions');
    return (res.data as List<dynamic>?) ?? [];
  }
}
