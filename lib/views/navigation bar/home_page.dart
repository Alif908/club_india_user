// ============================================================
// lib/views/home_page.dart
// ============================================================

import 'package:club_india_user/models/user_model.dart';
import 'package:club_india_user/services/api_service.dart';
import 'package:club_india_user/views/navigation_bar_page.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String? _error;

  // ── Parsed data ─────────────────────────────────────────────
  String _userName = '';
  String _phone = '';
  String _city = '';
  double _walletBalance =
      0; // ✅ FIX: was int _points, backend sends wallet_balance as double
  String _qrData = '';

  List<OfferModel> _offers = []; // ✅ typed list
  List<PartnerStoreModel> _partners = []; // ✅ typed list

  @override
  void initState() {
    super.initState();
    _fetchHome();
  }

  Future<void> _fetchHome() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ✅ UserApiService.getHome() — returns HomeResponseModel
      final HomeResponseModel data = await UserApiService.getHome();

      // ── Parse user ──────────────────────────────────────────
      _userName = data.user.name ?? 'User';
      _phone = data.user.phone;
      _city = data.user.city ?? '';

      // ✅ FIX: backend field is wallet_balance (double), not points/balance
      _walletBalance = data.user.walletBalance;

      // QR: backend stores full base64 QR in qr_code field
      // Use it directly if present, else fallback to phone-based string
      _qrData = data.user.qrCode?.isNotEmpty == true
          ? data.user.qrCode! // base64 data URL from backend
          : 'CLUBINDIA-$_phone'; // fallback

      // ── Offers (max 3 on home) ──────────────────────────────
      _offers = data.offers.take(3).toList();

      // ── Nearby stores (max 5) ───────────────────────────────
      _partners = data.nearbyStores.take(5).toList();

      setState(() => _loading = false);
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      debugPrint('❌ [HomePage._fetchHome] $e');
      setState(() {
        _loading = false;
        _error = 'Network error. Check your connection.';
      });
    }
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
                onRefresh: _fetchHome,
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
                      const SizedBox(height: 24),
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
    return Center(
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
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
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
  // Backend qr_code is a base64 data URL — we render the phone-based string
  // for QrImageView since it needs raw text, not an image URL.
  Widget _buildQRCard(BuildContext context) {
    // QrImageView needs a plain string (not base64 image).
    // Use phone as QR content; backend QR image can be shown via Image.memory if needed.
    final qrContent = 'CLUBINDIA-$_phone';

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
            child: LayoutBuilder(
              builder: (context, _) {
                final qrSize = (MediaQuery.of(context).size.width * 0.55).clamp(
                  140.0,
                  220.0,
                );
                return QrImageView(
                  data: qrContent,
                  version: QrVersions.auto,
                  size: qrSize,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFFF48FB1),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFFF48FB1),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showFullScreenQR(context, qrContent),
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

  void _showFullScreenQR(BuildContext context, String qrContent) {
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
              // ── Username at top ──────────────────────────────
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
              // ── QR Code ──────────────────────────────────────
              Builder(
                builder: (ctx) {
                  final size = (MediaQuery.of(ctx).size.width * 0.65).clamp(
                    160.0,
                    280.0,
                  );
                  return QrImageView(
                    data: qrContent,
                    version: QrVersions.auto,
                    size: size,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFFF48FB1),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFFF48FB1),
                    ),
                  );
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
    // ✅ FIX: show wallet_balance (double), formatted with commas
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
                  'Wallet Balance', // ✅ updated label to match backend
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
              onPressed: () {
                // TODO: navigate to withdraw/redeem page
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
          final OfferModel o = _offers[i]; // ✅ typed — no more Map casting
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
                  o.title, // ✅ direct field access
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
                  o.description ?? '', // ✅ direct field access
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
    // ✅ typed parameter
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
                  p.storeName, // ✅ direct field
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1C1C2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  p.address ?? p.city, // ✅ address or city fallback
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
