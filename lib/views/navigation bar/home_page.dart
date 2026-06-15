// ============================================================
// lib/views/navigation bar/home_page.dart
// ============================================================

import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:club_india_user/models/user_model.dart';
import 'package:club_india_user/services/api_service.dart';
import 'package:club_india_user/views/login_page.dart';
import 'package:club_india_user/views/navigation%20bar/redeem_point_screen.dart';
import 'package:club_india_user/views/navigation_bar_page.dart';
import 'package:flutter/material.dart';
import 'package:club_india_user/services/location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _loading = true;
  String? _error;

  Timer? _locationTimer;

  // ── Parsed data ─────────────────────────────────────────────
  String _userName = '';
  String _phone = '';
  String _city = '';
  double _walletBalance = 0;
  Uint8List? _qrBytes;

  List<OfferModel> _offers = [];
  List<PartnerStoreModel> _partners = [];

  // ── Ad data ──────────────────────────────────────────────────
  SpecialAdModel? _specialAd;
  PopupAdModel? _popupAd;

  @override
  void initState() {
    super.initState();

    _initializeHome();

    _locationTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _updateCurrentLocation();
    });
  }

  Future<void> _initializeHome() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final locationResult = await LocationService.getCurrentLocation();

      if (locationResult is LocationSuccess) {
        await UserApiService.updateLocation(
          latitude: locationResult.latitude,
          longitude: locationResult.longitude,
        );

        debugPrint(
          '📍 Location Updated: '
          '${locationResult.latitude}, '
          '${locationResult.longitude}',
        );
      }

      await _fetchHome();
    } catch (e) {
      debugPrint('Location update failed: $e');

      setState(() {
        _loading = false;
        _error = 'Failed to load data';
      });
    }
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final locationResult = await LocationService.getCurrentLocation();

      if (locationResult is LocationSuccess) {
        await UserApiService.updateLocation(
          latitude: locationResult.latitude,
          longitude: locationResult.longitude,
        );

        debugPrint(
          '📍 Auto Location Updated: '
          '${locationResult.latitude}, '
          '${locationResult.longitude}',
        );
      }
    } catch (e) {
      debugPrint('❌ Auto location update failed: $e');
    }
  }

  // ── Decode base64 QR from backend ───────────────────────────
  Uint8List? _decodeQr(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final base64Str = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(base64Str);
    } catch (e) {
      debugPrint('❌ [QR Decode] Failed: $e');
      return null;
    }
  }

  Future<void> _fetchHome() async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🏠 HOME API CALL STARTED');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    try {
      final HomeResponseModel data = await UserApiService.getHome();

      if (!mounted) return;

      setState(() {
        _error = null;

        _userName = data.user.name ?? 'User';
        _phone = data.user.phone;
        _city = data.user.city ?? '';
        _walletBalance = data.user.walletBalance;
        _qrBytes = _decodeQr(data.user.qrCode);

        _offers = data.offers.take(3).toList();
        _partners = data.nearbyStores.take(5).toList();

        _specialAd = data.specialAd;
        _popupAd = data.popupAd;

        _loading = false;
      });

      debugPrint('📢 [Ad] Using popup from Home API');

      if (_popupAd != null && _popupAd!.shouldShow && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showPopupAd();
          }
        });
      }
    } on ApiException catch (e) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ API EXCEPTION');
      debugPrint('Status  : ${e.statusCode}');
      debugPrint('Message : ${e.message}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (e.statusCode == 401) {
        debugPrint('🔄 Redirecting to LoginPage');

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );

        return;
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      debugPrint('❌ [HomePage._fetchHome] $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Network error. Check your connection.';
      });
    }
  }

  // ── Popup Ad Dialog ──────────────────────────────────────────
  void _showPopupAd() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🎬 [Ad] _showPopupAd() called');
    debugPrint('📢 Popup Image Raw = ${_popupAd?.image}');
    debugPrint('   Image URL: ${_popupAd!.image}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      barrierDismissible: false,
      builder: (_) => _PopupAdDialog(ad: _popupAd!),
    );
  }

  @override
  void dispose() {
    debugPrint('🗑️ [HomePage] dispose()');

    _locationTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEEF1),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF2D78)),
              )
            : _error != null
            ? _buildError()
            : RefreshIndicator(
                color: const Color(0xFFFF2D78),
                onRefresh: _initializeHome,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildQRCard(context),
                      const SizedBox(height: 16),
                      _buildPointsCard(),
                      const SizedBox(height: 16),

                      // ── Special Ad Banner ─────────────────
                      if (_specialAd != null && _specialAd!.shouldShow) ...[
                        _SpecialAdBanner(ad: _specialAd!),
                        const SizedBox(height: 16),
                      ],

                      _buildSectionHeader('Special Offers', 'View All', () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const MainNavScreen(initialTabIndex: 1),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                      _buildOffersRow(),
                      const SizedBox(height: 24),
                      _buildNearbyHeader(),
                      const SizedBox(height: 14),
                      _buildPartnerList(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildError() {
    return RefreshIndicator(
      color: const Color(0xFFFF2D78),
      onRefresh: _initializeHome,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Color(0xFFFF2D78),
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF888888)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2D78),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello,',
                style: TextStyle(fontSize: 16, color: Color(0xFF4A4A68)),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C2E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (_city.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFFFF2D78),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _city,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C2E),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── QR Card ─────────────────────────────────────────────────
  Widget _buildQRCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD6E7), Color(0xFFFFF0F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _buildQrImage(
              size: (MediaQuery.of(context).size.width * 0.55).clamp(
                140.0,
                220.0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showFullScreenQR(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.remove_red_eye_outlined,
                  color: Color(0xFFF48FB1),
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'View Full Screen',
                  style: TextStyle(
                    color: Color(0xFFF48FB1),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrImage({required double size}) {
    if (_qrBytes != null) {
      return Image.memory(
        _qrBytes!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildQrError(size),
      );
    }
    return _buildQrError(size);
  }

  Widget _buildQrError(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: size * 0.45,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Text(
            'QR not available',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  void _showFullScreenQR(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C2E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _phone,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (ctx) {
                  final size = (MediaQuery.of(ctx).size.width * 0.65).clamp(
                    160.0,
                    280.0,
                  );
                  return _buildQrImage(size: size);
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFFF48FB1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Points / Wallet Card ─────────────────────────────────────
  Widget _buildPointsCard() {
    final formatted = _walletBalance
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD6E7), Color(0xFFFFF0F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallet Balance',
                  style: TextStyle(fontSize: 14, color: Color(0xFF4A4A68)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFF2D78), Color(0xFFF8BBD0)],
                        ).createShader(bounds),
                        child: Text(
                          formatted,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFF2D78),
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2D78), Color(0xFFF8BBD0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              // ✅ UPDATED: await push so _fetchHome() runs after back
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RedeemPointsPage(walletBalance: _walletBalance),
                  ),
                );
                if (mounted) {
                  _fetchHome();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Redeem',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────
  Widget _buildSectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C2E),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'View All',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFFF2D78),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── Offers Row ───────────────────────────────────────────────
  Widget _buildOffersRow() {
    const fallbackColors = [
      Color(0xFFF3D6F5),
      Color(0xFFFFE4CC),
      Color(0xFFD6EEF8),
    ];

    if (_offers.isEmpty) {
      return const SizedBox(
        height: 155,
        child: Center(
          child: Text(
            'No offers available',
            style: TextStyle(color: Color(0xFF888888)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final OfferModel o = _offers[i];
          return Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fallbackColors[i % fallbackColors.length],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFFFF2D78),
                  size: 30,
                ),
                const Spacer(),
                Text(
                  o.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1C1C2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  o.description ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A4A68),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Nearby Partners ──────────────────────────────────────────
  Widget _buildNearbyHeader() {
    return const Row(
      children: [
        Icon(Icons.storefront_outlined, color: Color(0xFFFF2D78), size: 22),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Nearby Partners',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C2E),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerList() {
    if (_partners.isEmpty) {
      return const Center(
        child: Text(
          'No nearby partners',
          style: TextStyle(color: Color(0xFF888888)),
        ),
      );
    }
    return Column(
      children: _partners.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPartnerTile(p),
        );
      }).toList(),
    );
  }

  Widget _buildPartnerTile(PartnerStoreModel p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.storeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1C1C2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  p.address ?? p.city,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2D78), Color(0xFFF8BBD0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.subscriptionStatus == 'active' ? 'Active' : 'Partner',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SPECIAL AD BANNER WIDGET
// ════════════════════════════════════════════════════════════

class _SpecialAdBanner extends StatelessWidget {
  final SpecialAdModel ad;

  const _SpecialAdBanner({required this.ad});

  @override
  Widget build(BuildContext context) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🖼️ [SpecialAdBanner] build() called');
    debugPrint('   active    : ${ad.active}');
    debugPrint('   shouldShow: ${ad.shouldShow}');
    debugPrint('   image     : ${ad.image ?? "NULL"}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D78).withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              ad.image!,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) {
                  debugPrint('✅ [SpecialAdBanner] Image loaded successfully');
                  return child;
                }
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD6E7), Color(0xFFFFF0F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF2D78),
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              },
              errorBuilder: (_, error, ___) {
                debugPrint('❌ [SpecialAdBanner] Image load FAILED: $error');
                debugPrint('   URL: ${ad.image}');
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD6E7), Color(0xFFFFF0F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFFFF2D78),
                      size: 36,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// POPUP AD DIALOG WIDGET
// ════════════════════════════════════════════════════════════

class _PopupAdDialog extends StatefulWidget {
  final PopupAdModel ad;

  const _PopupAdDialog({required this.ad});

  @override
  State<_PopupAdDialog> createState() => _PopupAdDialogState();
}

class _PopupAdDialogState extends State<_PopupAdDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  Timer? _autoCloseTimer;
  Timer? _countdownTimer;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🎬 [PopupAdDialog] initState() — dialog opened');
    debugPrint('   Image URL : ${widget.ad.image}');
    debugPrint('   Auto-close: 3 seconds');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnim = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _autoCloseTimer = Timer(const Duration(seconds: 3), _close);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      debugPrint('⏳ [PopupAdDialog] Countdown: $_countdown');
      if (_countdown <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    debugPrint('🗑️ [PopupAdDialog] dispose() — dialog closed');
    _controller.dispose();
    _autoCloseTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _close() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('❌ [PopupAdDialog] _close() called');
    debugPrint('   Remaining countdown: $_countdown');
    debugPrint(
      '   Closed by: ${_countdown > 0 ? "User tap" : "Auto-close (3s)"}',
    );
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: screenW,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2D78).withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: Image.network(
                      widget.ad.image!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) {
                          debugPrint(
                            '✅ [PopupAdDialog] Image loaded successfully',
                          );
                          return child;
                        }
                        return Container(
                          color: const Color(0xFF1C1C2E),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF2D78),
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, error, ___) {
                        debugPrint(
                          '❌ [PopupAdDialog] Image load FAILED: $error',
                        );
                        debugPrint('   URL: ${widget.ad.image}');
                        return Container(
                          color: const Color(0xFF1C1C2E),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(0xFF4A4A68),
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFFF2D78),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Advertisement',
                            style: TextStyle(
                              color: Color(0xFFFF2D78),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _close,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF2D78),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _countdown > 0
                                      ? 'Close ($_countdown)'
                                      : 'Close',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
