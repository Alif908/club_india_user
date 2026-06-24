import 'dart:convert';
import 'package:club_india_user/main.dart';
import 'package:club_india_user/views/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:club_india_user/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────

const String _baseUrl = 'https://coinapi.bestagencyindia.com/api';
// const String _baseUrl = 'http://192.168.1.6:3030/api';

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
  static String get imageBaseUrl => _baseUrl.replaceAll('/api', '');

  // ── Token helpers ──────────────────────────────────────────

  static Future<void> _saveToken(String token) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('💾 [Auth] _saveToken() called');
    debugPrint('   Key         : $_tokenKey');
    debugPrint('   Token length: ${token.length}');
    debugPrint('   Token full   : $token');
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(_tokenKey, token);
    debugPrint('   Saved       : $success');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static Future<String?> _getToken() async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔑 [Auth] _getToken() called');
    debugPrint('   Key: $_tokenKey');
    final prefs = await SharedPreferences.getInstance();

    final allKeys = prefs.getKeys();
    debugPrint('   All SharedPrefs keys: $allKeys');

    final token = prefs.getString(_tokenKey);
    if (token == null) {
      debugPrint('   Result: NULL — key "$_tokenKey" not found in SharedPrefs');
    } else if (token.isEmpty) {
      debugPrint('   Result: EMPTY STRING — token exists but is empty');
    } else {
      debugPrint('   Result: EXISTS');
      debugPrint('   Token length : ${token.length}');
      debugPrint('   Token full  : $token');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return token;
  }

  static Future<void> logout() async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🚪 [Auth] logout() called');
    debugPrint('   Removing key: $_tokenKey');
    final prefs = await SharedPreferences.getInstance();
    final removed = await prefs.remove(_tokenKey);
    debugPrint('   Removed: $removed');
    final remaining = prefs.getKeys();
    debugPrint('   Remaining keys: $remaining');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static Future<bool> isLoggedIn() async {
    debugPrint('🔐 [Auth] isLoggedIn() called');
    final token = await _getToken();
    final loggedIn = token != null && token.isNotEmpty;
    debugPrint('   isLoggedIn result: $loggedIn');
    return loggedIn;
  }

  // ── Request helper ─────────────────────────────────────────

  static Future<dynamic> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📤 [$method] $endpoint');
    debugPrint('   URI: $uri');

    // ── AUTH TOKEN ─────────────────────────────────────────────
    if (requiresAuth) {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        debugPrint('❌ [Auth] No token found');

        throw ApiException(
          statusCode: 401,
          message: 'No token found. Please login again.',
        );
      }

      headers['Authorization'] = 'Bearer $token';

      debugPrint('   Auth: Bearer token attached');
      debugPrint('   Token length: ${token.length}');
    }

    // ── BODY ────────────────────────────────────────────────────
    if (body != null) {
      debugPrint('   Body: ${jsonEncode(body)}');
    } else {
      debugPrint('   Body: none');
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 15));
          break;

        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 15));
          break;

        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;

        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      debugPrint('🔴 [Network Error] $endpoint');
      debugPrint('   Error: $e');

      throw ApiException(
        statusCode: 0,
        message: 'Network error. Check your internet connection.',
      );
    }

    debugPrint('📥 [$method] $endpoint');
    debugPrint('   Status: ${response.statusCode}');
    debugPrint('   Response: ${response.body}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    // ─────────────────────────────────────────────
    // 401 HANDLING (TOKEN EXPIRED)
    // ─────────────────────────────────────────────
    if (response.statusCode == 401) {
      debugPrint('🔒 TOKEN EXPIRED / UNAUTHORIZED');

      try {
        await logout();

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } catch (e) {
        debugPrint('❌ Navigation Error: $e');
      }

      throw ApiException(statusCode: 401, message: 'SESSION_EXPIRED');
    }

    // ─────────────────────────────────────────────
    // OTHER ERRORS
    // ─────────────────────────────────────────────
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String msg = 'Something went wrong';

      if (decoded is Map && decoded['message'] != null) {
        msg = decoded['message'].toString();
      }

      debugPrint('❌ API ERROR: $msg');

      throw ApiException(statusCode: response.statusCode, message: msg);
    }

    debugPrint('✅ API SUCCESS: $endpoint');

    return decoded;
  }

  // ────────────────────────────────────────────────────────────
  // AUTH
  // ────────────────────────────────────────────────────────────

  /// POST /api/user/send-otp
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    debugPrint('🔑 [sendOtp] Sending OTP to phone: $phone');

    final data = await _request(
      method: 'POST',
      endpoint: '/user/send-otp',
      body: {'phone': phone},
    );

    debugPrint('✅ [sendOtp] OTP sent successfully');
    debugPrint('   OTP (dev only): ${data['otp']}');

    return Map<String, dynamic>.from(data);
  }

  /// POST /api/user/verify-otp
  static Future<({String token, UserModel user})> verifyOtp({
    required String phone,
    required String otp,
    String? name,
    String? email,
    double? latitude,
    double? longitude,
    bool forceLogin = false, // 🔥 ADD THIS
  }) async {
    debugPrint('✅ [verifyOtp] Verifying OTP for phone: $phone');

    final bodyPayload = <String, dynamic>{
      'phone': phone,
      'otp': otp,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (forceLogin) 'force_login': true, // 🔥 ADD THIS
    };

    debugPrint('   Payload keys: ${bodyPayload.keys.toList()}');

    final data = await _request(
      method: 'POST',
      endpoint: '/user/verify-otp',
      body: bodyPayload,
    );

    final token = data['token'] as String;
    await _saveToken(token);

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    debugPrint('🎟️ [verifyOtp] Login successful');
    debugPrint('   User ID: ${user.id}');
    debugPrint('   User Phone: ${user.phone}');
    debugPrint('   Wallet Balance: ${user.walletBalance}');

    return (token: token, user: user);
  }

  // ────────────────────────────────────────────────────────────
  // HOME
  // ────────────────────────────────────────────────────────────

  /// GET /api/user/home
  static Future<HomeResponseModel> getHome() async {
    debugPrint('🏠 [getHome] Fetching home data...');

    final data = await _request(
      method: 'GET',
      endpoint: '/user/home',
      requiresAuth: true,
    );

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📦 RAW HOME RESPONSE');
    debugPrint(data.toString());
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 🔥 DEBUG
    debugPrint('POPUPS => ${(data as Map<String, dynamic>)['popups']}');
    debugPrint('POPUP => ${data['popup']}');
    debugPrint('SPECIAL AD => ${data['special_ad']}');
    debugPrint('ALL KEYS => ${data.keys.toList()}');

    final result = HomeResponseModel.fromJson(data);

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🎁 OFFERS DEBUG');
    debugPrint('Total Offers : ${result.offers.length}');

    for (final offer in result.offers) {
      debugPrint('----------------------------');
      debugPrint('ID          : ${offer.id}');
      debugPrint('STORE ID    : ${offer.storeId}');
      debugPrint('STORE NAME  : ${offer.storeName}');
      debugPrint('TITLE       : ${offer.title}');
      debugPrint('DESCRIPTION : ${offer.description}');
      debugPrint('BANNER      : ${offer.banner}');
      debugPrint('ACTIVE      : ${offer.isActive}');
      debugPrint('EXPIRY DATE : ${offer.expiryDate}');

      // 🔥 NEW FIELDS
      debugPrint('ADDON ID    : ${offer.addonId}');
      debugPrint('DAYS        : ${offer.days}');
      debugPrint('ADDON PRICE : ${offer.addonPrice}');
      debugPrint('TOTAL PRICE : ${offer.totalPrice}');
      debugPrint('START DATE  : ${offer.startDate}');
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    debugPrint('✅ [getHome] Home data loaded');
    debugPrint('   Nearby Stores: ${result.nearbyStores.length}');
    debugPrint('   Offers: ${result.offers.length}');
    debugPrint('   User Wallet Balance: ${result.user.walletBalance}');
    debugPrint('   Special Ad Active: ${result.specialAd?.active ?? false}');
    debugPrint('   Popup Ad Active: ${result.popupAd?.active ?? false}');

    return result;
  }

  //---------validation session-------------------
  static Future<bool> validateSession() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      await getProfile(); // backend validation

      return true;
    } catch (e) {
      debugPrint('❌ Session validation failed: $e');
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────
  // PROFILE
  // ────────────────────────────────────────────────────────────

  /// GET /api/user/profile
  static Future<UserModel> getProfile() async {
    debugPrint('👤 [getProfile] Fetching user profile...');

    final data = await _request(
      method: 'GET',
      endpoint: '/user/profile',
      requiresAuth: true,
    );

    // 🔥 FIX: Backend wraps response in { "user": {...} }
    final Map<String, dynamic> userJson =
        (data is Map<String, dynamic> && data.containsKey('user'))
        ? data['user'] as Map<String, dynamic>
        : data as Map<String, dynamic>;

    final user = UserModel.fromJson(userJson);
    debugPrint('✅ [getProfile] Profile loaded');
    debugPrint('   User ID: ${user.id}');
    debugPrint('   Name: ${user.name}');
    debugPrint('   Phone: ${user.phone}');
    debugPrint('   Wallet Balance: ${user.walletBalance}');
    debugPrint('   Total Earned: ${user.totalEarned}');
    debugPrint('   Total Redeemed: ${user.totalRedeemed}');
    debugPrint('   Has Bank Details: ${user.hasBankDetails}');
    debugPrint('   Has UPI: ${user.hasUpi}');

    return user;
  }

  // ────────────────────────────────────────────────────────────
  // TRANSACTION HISTORY
  // ────────────────────────────────────────────────────────────

  /// GET /api/user/history
  static Future<List<TransactionModel>> getHistory() async {
    debugPrint('📜 [getHistory] Fetching transaction history...');

    final data = await _request(
      method: 'GET',
      endpoint: '/user/history',
      requiresAuth: true,
    );

    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic> &&
        data.containsKey('transactions')) {
      list = data['transactions'] as List<dynamic>;
    } else {
      list = [];
      debugPrint('⚠️ [getHistory] Unexpected response format');
    }

    final transactions = list
        .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
        .toList();

    debugPrint('✅ [getHistory] Transactions loaded');
    debugPrint('   Total Transactions: ${transactions.length}');
    final earned = transactions.where((t) => t.isEarned).length;
    final redeemed = transactions.where((t) => t.isRedeemed).length;
    final withdrawn = transactions.where((t) => t.isWithdrawn).length;

    debugPrint(
      '   Earned: $earned  |  Redeemed: $redeemed  |  Withdrawn: $withdrawn',
    );

    for (final t in transactions) {
      debugPrint(
        'TYPE=${t.transactionType} '
        'POINTS=${t.rewardPoints} '
        'EARNED=${t.isEarned} '
        'REDEEMED=${t.isRedeemed}',
      );
    }

    return transactions;
  }

  // ────────────────────────────────────────────────────────────
  // WITHDRAW POINTS
  // ────────────────────────────────────────────────────────────

  /// POST /api/user/withdraw
  static Future<({double withdrawnPoints, double remainingBalance})>
  withdrawPoints(double points) async {
    debugPrint('💸 [withdrawPoints] Initiating withdrawal...');
    debugPrint('   Points to Withdraw: $points');

    if (points <= 0) {
      debugPrint('❌ [withdrawPoints] Invalid points amount: $points');
      throw ApiException(
        statusCode: 400,
        message: 'Enter a valid points amount',
      );
    }

    // 🔥 FIX: Send as int — backend may reject 5000.0 format
    final data = await _request(
      method: 'POST',
      endpoint: '/user/withdraw',
      body: {'points': points.toInt()},
      requiresAuth: true,
    );

    final withdrawnPoints =
        double.tryParse(data['withdrawn_points'].toString()) ?? 0.0;
    final remainingBalance =
        double.tryParse(data['remaining_balance'].toString()) ?? 0.0;

    debugPrint('✅ [withdrawPoints] Withdrawal successful');
    debugPrint('   Withdrawn Points: $withdrawnPoints');
    debugPrint('   Remaining Balance: $remainingBalance');

    return (
      withdrawnPoints: withdrawnPoints,
      remainingBalance: remainingBalance,
    );
  }

  // ────────────────────────────────────────────────────────────
  // SAVE FCM TOKEN
  // ────────────────────────────────────────────────────────────

  /// POST /api/user/save-fcm-token
  static Future<void> saveFcmToken(String fcmToken) async {
    debugPrint('📱 [saveFcmToken] Saving FCM token...');

    await _request(
      method: 'POST',
      endpoint: '/user/save-fcm-token',
      body: {'fcm_token': fcmToken},
      requiresAuth: true,
    );

    debugPrint('✅ [saveFcmToken] FCM token saved successfully');
  }

  // ────────────────────────────────────────────────────────────
  // SAVE BANK DETAILS
  // ────────────────────────────────────────────────────────────

  /// POST /api/user/save-bank-details
  static Future<UserModel> saveBankDetails({
    String? bankHolderName,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
  }) async {
    debugPrint('🏦 [saveBankDetails] Saving bank details...');

    final data = await _request(
      method: 'POST',
      endpoint: '/user/save-bank-details',
      body: {
        if (bankHolderName != null) 'bank_holder_name': bankHolderName,
        if (bankName != null) 'bank_name': bankName,
        if (accountNumber != null) 'account_number': accountNumber,
        if (ifscCode != null) 'ifsc_code': ifscCode,
        if (upiId != null) 'upi_id': upiId,
      },
      requiresAuth: true,
    );

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    debugPrint('✅ [saveBankDetails] Bank details saved');
    debugPrint('   Account: ${user.accountNumber}');
    debugPrint('   UPI: ${user.upiId}');

    return user;
  }

  // ────────────────────────────────────────────────────────────
  // LOCATION (public — no auth needed)
  // ────────────────────────────────────────────────────────────

  /// GET /api/public/states
  static Future<List<String>> getStates() async {
    debugPrint('🗺️ [getStates] Fetching states list...');

    final data = await _request(method: 'GET', endpoint: '/public/states');
    final states = List<String>.from(data as List);

    debugPrint('✅ [getStates] States loaded: ${states.length}');
    return states;
  }

  //update location

  static Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);

    final place = placemarks.first;

    final city = place.subLocality?.isNotEmpty == true
        ? place.subLocality!
        : (place.locality ?? '');

    final district = place.subAdministrativeArea ?? '';

    await _request(
      method: 'PUT',
      endpoint: '/user/update-location',
      requiresAuth: true,
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'district': district,
      },
    );
  }

  /// GET /api/public/districts/:state
  static Future<List<String>> getDistricts(String state) async {
    debugPrint('🗺️ [getDistricts] Fetching districts for state: $state');

    final data = await _request(
      method: 'GET',
      endpoint: '/public/districts/${Uri.encodeComponent(state)}',
    );
    final districts = List<String>.from(data as List);

    debugPrint('✅ [getDistricts] Districts loaded: ${districts.length}');
    return districts;
  }

  /// GET /api/public/cities?state=&district=
  static Future<List<String>> getCities(String state, String district) async {
    debugPrint('🏙️ [getCities] Fetching cities...');
    debugPrint('   State: $state  |  District: $district');

    final uri = Uri.parse(
      '$_baseUrl/public/cities',
    ).replace(queryParameters: {'state': state, 'district': district});

    debugPrint('📤 [GET] /public/cities → $uri');

    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('🔴 [Network Error] /public/cities → $e');
      throw ApiException(
        statusCode: 0,
        message: 'Network error. Check your connection.',
      );
    }

    debugPrint('📥 [GET] /public/cities');
    debugPrint('   Status: ${response.statusCode}');
    debugPrint('   Body: ${response.body}');

    if (response.statusCode != 200) {
      debugPrint('❌ [getCities] Failed with status: ${response.statusCode}');
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to fetch cities',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final cities = List<String>.from(decoded['cities'] ?? []);

    debugPrint('✅ [getCities] Cities loaded: ${cities.length}');
    return cities;
  }

  //delete account

  static Future<void> openDeleteAccountPage() async {
    final Uri url = Uri.parse(
      'https://coinapi.bestagencyindia.com/delete-user.html',
    );

    if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
      throw Exception('Could not launch $url');
    }
  }
}
