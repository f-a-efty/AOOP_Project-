import 'package:dio/dio.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:8080/api/v1';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'username': phone,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<String?> sendOtp(String phone) async {
    final response = await _dio.post('/auth/otp/send', data: {
      'phoneNumber': phone,
      'purpose': 'REGISTER',
    });
    return response.data['testCode'] as String?;
  }

  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String otpCode,
  }) async {
    final response = await _dio.post('/auth/register/user', data: {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'password': password,
      'confirmPassword': confirmPassword,
      'otpCode': otpCode,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerCompany({
    required String companyName,
    required String registrationNumber,
    required String contactEmail,
    required String contactPhone,
    required String companyAddress,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _dio.post('/auth/register/company', data: {
      'companyName': companyName,
      'registrationNumber': registrationNumber,
      'permitInfo': '',
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'contactPersonName': companyName,
      'contactPersonPhone': contactPhone,
      'contactPersonEmail': contactEmail,
      'companyAddress': companyAddress,
      'region': 'Dhaka',
      'password': password,
      'confirmPassword': confirmPassword,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchUserDashboard(String? token) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
    final response = await _dio.get('/me/dashboard', options: options);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> manualDeposit(
    String? token, {
    required double weightKg,
    String plasticType = 'PET/Mix',
    int? boothId,
  }) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
    final response = await _dio.post(
      '/me/deposit/manual',
      data: {
        'weightKg': weightKg,
        'plasticType': plasticType,
        if (boothId != null) 'boothId': boothId,
      },
      options: options,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchTransactions(String? token) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
    final response = await _dio.get('/me/transactions', options: options);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> withdrawToBkash(
    String? token, {
    required int tokens,
    required String bkashNumber,
  }) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
    final response = await _dio.post(
      '/me/withdraw',
      data: {
        'tokens': tokens,
        'bkashNumber': bkashNumber,
      },
      options: options,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchCoupons(String? token) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
    final response = await _dio.get('/coupons', options: options);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> redeemCoupon(String? token, int couponId) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
    final response =
        await _dio.post('/coupons/$couponId/redeem', options: options);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchLeaderboard(String? token) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
    final response = await _dio.get('/leaderboard', options: options);
    return response.data as List<dynamic>;
  }
}
