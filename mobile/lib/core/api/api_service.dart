import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';

String get defaultApiBaseUrl {
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:8080/api/v1';
  }
  return 'http://localhost:8080/api/v1';
}

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
      baseUrl: defaultApiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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

  Future<List<dynamic>> getAdminActivity({int limit = 15}) async {
    final res = await _dio.get('/admin/dashboard/activity', queryParameters: {'limit': limit});
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> getAdminAnalytics({int days = 30}) async {
    final res = await _dio.get('/admin/reports/analytics', queryParameters: {'days': days});
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<List<dynamic>> getActiveCompanies() async {
    final res = await _dio.get('/admin/companies/active');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> getAdminCampaigns() async {
    final res = await _dio.get('/admin/campaigns');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> saveAdminCampaign(Map<String, dynamic> body, {int? campaignId}) async {
    final res = campaignId == null
        ? await _dio.post('/admin/campaigns', data: body)
        : await _dio.put('/admin/campaigns/$campaignId', data: body);
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<void> archiveAdminCampaign(int campaignId) async {
    await _dio.delete('/admin/campaigns/$campaignId');
  }

  Future<List<dynamic>> getAdminCoupons() async {
    final res = await _dio.get('/admin/coupons');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> saveAdminCoupon(Map<String, dynamic> body, {int? couponId}) async {
    final res = couponId == null
        ? await _dio.post('/admin/coupons', data: body)
        : await _dio.put('/admin/coupons/$couponId', data: body);
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<void> archiveAdminCoupon(int couponId) async {
    await _dio.delete('/admin/coupons/$couponId');
  }

  Future<List<dynamic>> getLoyaltyLevels() async {
    final res = await _dio.get('/admin/loyalty-levels');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<void> updateLoyaltyLevel(String level, Map<String, dynamic> body) async {
    await _dio.put('/admin/loyalty-levels/${Uri.encodeComponent(level)}', data: body);
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

  Future<Map<String, dynamic>> completePickup(int pickupId, {String? plasticGrade}) async {
    final res = await _dio.post('/company/pickup-requests/$pickupId/complete', data: {
      if (plasticGrade != null) 'plasticGrade': plasticGrade,
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

  Future<List<dynamic>> getCompanyAlerts() async {
    final res = await _dio.get('/company/alerts');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> markCompanyAlertRead(int alertId) async {
    final res = await _dio.post('/company/alerts/$alertId/read');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> createCompanyVehicle(Map<String, dynamic> body) async {
    final res = await _dio.post('/company/vehicles', data: body);
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> requestCompanyPickup(int boothId) async {
    final res = await _dio.post('/company/booths/$boothId/pickup-requests');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  // --- User APIs ---
  Future<Map<String, dynamic>> getUserDashboard() async {
    final res = await _dio.get('/me/dashboard');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<List<dynamic>> getLeaderboard() async {
    final res = await _dio.get('/leaderboard');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> getBooths() async {
    final res = await _dio.get('/booths');
    return (res.data as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> getPublicEconomics() async {
    final res = await _dio.get('/economics');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> manualDeposit({
    required double weightKg,
    String plasticType = 'PET/Mix',
    int? boothId,
  }) async {
    final res = await _dio.post('/me/deposit/manual', data: {
      'weightKg': weightKg,
      'plasticType': plasticType,
      if (boothId != null) 'boothId': boothId,
    });
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

  Future<Map<String, dynamic>> getCitizenAdvice() async {
    final res = await _dio.get('/me/ai/advice');
    return (res.data as Map<String, dynamic>?) ?? {};
  }
}
