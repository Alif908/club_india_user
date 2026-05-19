import 'dart:convert';
import 'dart:developer' as dev;
import 'package:club_india_user/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────

const String _baseUrl = 'https://coinapi.bestagencyindia.com/api';
const String _tokenKey = 'user_token';

// ─────────────────────────────────────────────────────────────
// EXCEPTION
// ─────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => '❌ ApiException [$statusCode]: $message';
}

// ─────────────────────────────────────────────────────────────
// USER API SERVICE
// ─────────────────────────────────────────────────────────────

class UserApiService {
  // ── Token helpers ──────────────────────────────────────────

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    dev.log('💾 [Auth] Token saved', name: 'UserApiService');
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    dev.log('🚪 [Auth] Logged out — token cleared', name: 'UserApiService');
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Request helper ─────────────────────────────────────────

  static Future<dynamic> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (requiresAuth) {
      final token = await _getToken();
      if (token == null) {
        throw ApiException(
          statusCode: 401,
          message: 'No token found. Please login again.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    dev.log(
      '\n📤 [$method] $endpoint\n   Body: ${body != null ? jsonEncode(body) : "none"}',
      name: 'UserApiService',
    );

    http.Response response;

    try {
      switch (method) {
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 15));
          break;
        case 'GET':
        default:
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      dev.log('🔴 [Network Error] $endpoint → $e', name: 'UserApiService');
      throw ApiException(
        statusCode: 0,
        message: 'Network error. Check your connection.',
      );
    }

    dev.log(
      '\n📥 [$method] $endpoint\n   Status: ${response.statusCode}\n   Body: ${response.body}',
      name: 'UserApiService',
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map
          ? decoded['message'] ?? 'Something went wrong'
          : 'Something went wrong';
      throw ApiException(statusCode: response.statusCode, message: msg);
    }

    return decoded;
  }

  // ────────────────────────────────────────────────────────────
  // AUTH
  // ────────────────────────────────────────────────────────────

  /// POST /api/user/send-otp
  /// Returns full Map so login page can read res['otp'] during dev
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    dev.log('🔑 [sendOtp] phone: $phone', name: 'UserApiService');

    final data = await _request(
      method: 'POST',
      endpoint: '/user/send-otp',
      body: {'phone': phone},
    );

    dev.log(
      '✅ [sendOtp] Success. OTP (dev only): ${data['otp']}',
      name: 'UserApiService',
    );

    // Returns: { message: "OTP sent successfully", otp: "123456" }
    return Map<String, dynamic>.from(data);
  }

  /// POST /api/user/verify-otp
  static Future<({String token, UserModel user})> verifyOtp({
    required String phone,
    required String otp,
    String? name,
    String? email,
    String? state,
    String? district,
    String? city,
    double? latitude,
    double? longitude,
  }) async {
    dev.log('✅ [verifyOtp] phone: $phone', name: 'UserApiService');

    final data = await _request(
      method: 'POST',
      endpoint: '/user/verify-otp',
      body: {
        'phone': phone,
        'otp': otp,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (state != null) 'state': state,
        if (district != null) 'district': district,
        if (city != null) 'city': city,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );

    final token = data['token'] as String;
    await _saveToken(token);

    final user = UserModel.fromJson(data['user']);
    dev.log(
      '🎟️ [verifyOtp] Login success. User id: ${user.id}',
      name: 'UserApiService',
    );

    return (token: token, user: user);
  }

  // ────────────────────────────────────────────────────────────
  // HOME
  // ────────────────────────────────────────────────────────────

  /// GET /api/user/home
  static Future<HomeResponseModel> getHome() async {
    dev.log('🏠 [getHome] Fetching home data...', name: 'UserApiService');

    final data = await _request(
      method: 'GET',
      endpoint: '/user/home',
      requiresAuth: true,
    );

    final result = HomeResponseModel.fromJson(data);
    dev.log(
      '✅ [getHome] stores: ${result.nearbyStores.length}, offers: ${result.offers.length}',
      name: 'UserApiService',
    );

    return result;
  }

  // ────────────────────────────────────────────────────────────
  // PROFILE
  // ────────────────────────────────────────────────────────────

  /// GET /api/user/profile
  static Future<UserModel> getProfile() async {
    dev.log('👤 [getProfile] Fetching profile...', name: 'UserApiService');

    final data = await _request(
      method: 'GET',
      endpoint: '/user/profile',
      requiresAuth: true,
    );

    final user = UserModel.fromJson(data);
    dev.log('✅ [getProfile] User id: ${user.id}', name: 'UserApiService');

    return user;
  }

  // ────────────────────────────────────────────────────────────
  // TRANSACTION HISTORY
  // ────────────────────────────────────────────────────────────

  /// GET /api/user/history
  static Future<List<TransactionModel>> getHistory() async {
    dev.log('📜 [getHistory] Fetching transactions...', name: 'UserApiService');

    final data = await _request(
      method: 'GET',
      endpoint: '/user/history',
      requiresAuth: true,
    );

    final transactions = (data as List)
        .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
        .toList();

    dev.log(
      '✅ [getHistory] count: ${transactions.length}',
      name: 'UserApiService',
    );

    return transactions;
  }

  // ────────────────────────────────────────────────────────────
  // WITHDRAW POINTS
  // ────────────────────────────────────────────────────────────

  /// POST /api/user/withdraw
  static Future<({double withdrawnPoints, double remainingBalance})>
  withdrawPoints(double points) async {
    dev.log('💸 [withdrawPoints] points: $points', name: 'UserApiService');

    if (points <= 0) {
      throw ApiException(
        statusCode: 400,
        message: 'Enter a valid points amount',
      );
    }

    final data = await _request(
      method: 'POST',
      endpoint: '/user/withdraw',
      body: {'points': points},
      requiresAuth: true,
    );

    dev.log(
      '✅ [withdrawPoints] withdrawn: ${data['withdrawn_points']}, remaining: ${data['remaining_balance']}',
      name: 'UserApiService',
    );

    return (
      withdrawnPoints:
          double.tryParse(data['withdrawn_points'].toString()) ?? 0.0,
      remainingBalance:
          double.tryParse(data['remaining_balance'].toString()) ?? 0.0,
    );
  }

  // ────────────────────────────────────────────────────────────
  // LOCATION (public — no auth needed)
  // ────────────────────────────────────────────────────────────

  /// GET /api/public/states
  static Future<List<String>> getStates() async {
    dev.log('🗺️ [getStates] Fetching states...', name: 'UserApiService');

    final data = await _request(method: 'GET', endpoint: '/public/states');
    final states = List<String>.from(data as List);

    dev.log('✅ [getStates] count: ${states.length}', name: 'UserApiService');
    return states;
  }

  /// GET /api/public/districts/:state
  static Future<List<String>> getDistricts(String state) async {
    dev.log('🗺️ [getDistricts] state: $state', name: 'UserApiService');

    final data = await _request(
      method: 'GET',
      endpoint: '/public/districts/${Uri.encodeComponent(state)}',
    );
    final districts = List<String>.from(data as List);

    dev.log(
      '✅ [getDistricts] count: ${districts.length}',
      name: 'UserApiService',
    );
    return districts;
  }

  /// GET /api/public/cities?state=&district=
  static Future<List<String>> getCities(String state, String district) async {
    dev.log(
      '🏙️ [getCities] state: $state, district: $district',
      name: 'UserApiService',
    );

    final uri = Uri.parse(
      '$_baseUrl/public/cities',
    ).replace(queryParameters: {'state': state, 'district': district});

    dev.log('📤 [GET] /public/cities → $uri', name: 'UserApiService');

    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      dev.log('🔴 [Network Error] /public/cities → $e', name: 'UserApiService');
      throw ApiException(
        statusCode: 0,
        message: 'Network error. Check your connection.',
      );
    }

    dev.log(
      '📥 [GET] /public/cities\n   Status: ${response.statusCode}\n   Body: ${response.body}',
      name: 'UserApiService',
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch cities',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final cities = List<String>.from(decoded['cities'] ?? []);

    dev.log('✅ [getCities] count: ${cities.length}', name: 'UserApiService');
    return cities;
  }
}
