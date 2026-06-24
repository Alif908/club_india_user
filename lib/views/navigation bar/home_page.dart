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
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _popupAlreadyShown = false;
  bool _loading = true;
  String? _error;
  Timer? _locationTimer;

  String _userName = '';
  String _phone = '';
  String _city = '';
  double _walletBalance = 0;
  Uint8List? _qrBytes;

  List<OfferModel> _offers = [];
  List<PartnerStoreModel> _partners = [];

  PopupAdModel? _popupAd;

  @override
  void initState() {
    super.initState();
    _initializeHome();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
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

  Future<void> refreshPage() async {
    await _fetchHome();
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final locationResult = await LocationService.getCurrentLocation();
      if (locationResult is LocationSuccess) {
        await UserApiService.updateLocation(
          latitude: locationResult.latitude,
          longitude: locationResult.longitude,
        );
        await _fetchHome();
      }
    } catch (e) {
      debugPrint('❌ Auto location update failed: $e');
    }
  }

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

  String? _buildBannerUrl(String? banner) {
    if (banner == null || banner.isEmpty) return null;
    if (banner.startsWith('http://') || banner.startsWith('https://')) {
      return banner;
    }
    return '${UserApiService.imageBaseUrl}/uploads/$banner';
  }

  List<Color> _gradientFor(int index) {
    const palettes = [
      [Color(0xFF9B59B6), Color(0xFFFF6EB4)],
      [Color(0xFFFF8C42), Color(0xFFFF5252)],
      [Color(0xFF00B4DB), Color(0xFF00CFFF)],
      [Color(0xFF2ECC71), Color(0xFF1ABC9C)],
      [Color(0xFF667EEA), Color(0xFF764BA2)],
    ];
    return palettes[index % palettes.length];
  }

  IconData _iconFor(String offerType) {
    switch (offerType.toLowerCase()) {
      case 'popup':
        return Icons.campaign_rounded;
      case 'normal':
      default:
        return Icons.local_offer_rounded;
    }
  }

  String _validTill(DateTime? date) {
    if (date == null) return 'No expiry';
    return 'Valid till ${DateFormat('d MMM yyyy').format(date)}';
  }

  void _showOfferDetails(BuildContext context, OfferModel offer, int index) {
    final bannerUrl = _buildBannerUrl(offer.banner);
    final gradientColors = _gradientFor(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (bannerUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    bannerUrl,
                    height: 380,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            height: 220,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF2D78),
                              ),
                            ),
                          ),
                    errorBuilder: (_, __, ___) =>
                        _fallbackBanner(gradientColors, offer.offerType),
                  ),
                )
              else
                _fallbackBanner(gradientColors, offer.offerType),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront,
                          size: 18,
                          color: Color(0xFFFF2D78),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            offer.storeName ?? 'Store',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A4A68),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (offer.description != null &&
                        offer.description!.isNotEmpty)
                      Text(
                        offer.description!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF4A4A68),
                          height: 1.5,
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: Color(0xFFFF2D78),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _validTill(offer.expiryDate),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackBanner(List<Color> colors, String offerType) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(_iconFor(offerType), color: Colors.white, size: 60),
      ),
    );
  }

  Future<void> _fetchHome() async {
    try {
      final HomeResponseModel data = await UserApiService.getHome();

      if (!mounted) return;
      debugPrint('🔥 POPUP storeName = ${data.popupAd?.storeName}');
      debugPrint('🔥 POPUP title     = ${data.popupAd?.title}');
      setState(() {
        _error = null;
        _userName = data.user.name ?? '';
        _phone = data.user.phone;
        _city = data.user.city ?? '';
        _walletBalance = data.user.walletBalance;
        _qrBytes = _decodeQr(data.user.qrCode);
        _offers = data.offers.take(3).toList();
        _partners = data.nearbyStores.take(5).toList();

        if (data.popupAd != null &&
            data.popupAd!.active == true &&
            data.popupAd!.shouldShow == true) {
          _popupAd = data.popupAd;
        } else {
          _popupAd = null;
        }

        _loading = false;
      });

      if (_popupAd != null &&
          _popupAd!.active == true &&
          _popupAd!.shouldShow == true &&
          !_popupAlreadyShown &&
          mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _popupAlreadyShown = true;
          _showPopupAd();
        });
      }
    } on ApiException catch (e) {
      if (e.message == 'SESSION_EXPIRED') return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Network error. Check your connection.';
      });
    }
  }

  void _showPopupAd() {
    if (_popupAd == null ||
        _popupAd!.active != true ||
        _popupAd!.shouldShow != true)
      return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      barrierDismissible: false,
      builder: (_) => _PopupAdDialog(ad: _popupAd!),
    );
  }

  @override
  void dispose() {
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
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RedeemPointsPage(walletBalance: _walletBalance),
                  ),
                );
                if (mounted) _fetchHome();
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

  Widget _buildOffersRow() {
    const fallbackColors = [
      Color(0xFFF3D6F5),
      Color(0xFFFFE4CC),
      Color(0xFFD6EEF8),
    ];

    if (_offers.isEmpty) {
      return const SizedBox(
        height: 185,
        child: Center(
          child: Text(
            'No offers available',
            style: TextStyle(color: Color(0xFF888888)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 185,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final OfferModel o = _offers[i];
          final bannerUrl = _buildBannerUrl(o.banner);

          return GestureDetector(
            onTap: () => _showOfferDetails(context, o, i),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: fallbackColors[i % fallbackColors.length],
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bannerUrl != null)
                      Image.network(
                        bannerUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF2D78),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.image, size: 40)),
                      )
                    else
                      Container(
                        color: fallbackColors[i % fallbackColors.length],
                        child: const Center(
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: Color(0xFFFF2D78),
                            size: 40,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              o.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              o.storeName ?? 'Store',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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
              p.subscriptionStatus == 'active' ? 'Available' : 'Partner',
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
// POPUP AD DIALOG WIDGET  🔥 image + title
//
// TIMING LOGIC (as requested):
//   Phase 1 (0-5s)  -> countdown number shown, NO close icon, not closable
//   Phase 2 (5-10s) -> close icon shown, user can tap to close,
//                      otherwise auto-closes when this phase ends
//
// TAP LOGIC:
//   Tapping the ad body (image/title) opens a detail bottom sheet,
//   same style as the "Special Offers" detail sheet.
// ════════════════════════════════════════════════════════════

class _PopupAdDialog extends StatefulWidget {
  final PopupAdModel ad;
  const _PopupAdDialog({required this.ad});

  @override
  State<_PopupAdDialog> createState() => _PopupAdDialogState();
}

class _PopupAdDialogState extends State<_PopupAdDialog>
    with SingleTickerProviderStateMixin {
  static const int _countdownSeconds = 5; // Phase 1 duration
  static const int _closableSeconds = 5; // Phase 2 duration

  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  Timer? _phaseTimer;
  Timer? _tickTimer;

  bool _isClosable = false; // false = countdown phase, true = close-icon phase
  int _secondsLeft = _countdownSeconds;

  @override
  void initState() {
    super.initState();
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

    _startCountdownPhase();
  }

  void _startCountdownPhase() {
    _isClosable = false;
    _secondsLeft = _countdownSeconds;

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) _secondsLeft = 0;
      });
    });

    _phaseTimer?.cancel();
    _phaseTimer = Timer(Duration(seconds: _countdownSeconds), () {
      if (!mounted) return;
      _startClosablePhase();
    });
  }

  void _startClosablePhase() {
    _tickTimer?.cancel();
    setState(() {
      _isClosable = true;
      _secondsLeft = _closableSeconds;
    });

    // After the second duration ends, auto-close if user hasn't closed it.
    _phaseTimer?.cancel();
    _phaseTimer = Timer(Duration(seconds: _closableSeconds), _close);
  }

  @override
  void dispose() {
    _controller.dispose();
    _phaseTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  void _openAdDetails() {
    final ad = widget.ad;
    final imageUrl = ad.image;
    final hasTitle =
        (ad.title != null && ad.title!.isNotEmpty) ||
        (ad.storeName != null && ad.storeName!.isNotEmpty);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 380,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            height: 220,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF2D78),
                              ),
                            ),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(
                          Icons.campaign_rounded,
                          color: Color(0xFFFF2D78),
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),
              if (hasTitle)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ad.storeName != null && ad.storeName!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront,
                              size: 18,
                              color: Color(0xFFFF2D78),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ad.storeName!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A4A68),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      if (ad.title != null && ad.title!.isNotEmpty)
                        Text(
                          ad.title!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C2E),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final hasTitle =
        (widget.ad.title != null && widget.ad.title!.isNotEmpty) ||
        (widget.ad.storeName != null && widget.ad.storeName!.isNotEmpty);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: ConstrainedBox(
            // limit max height so it never overflows the screen
            constraints: BoxConstraints(
              maxHeight: screenH * 0.8,
              maxWidth: screenW,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Card: image + optional title (TAPPABLE -> opens details) ──
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openAdDetails,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: screenW,
                      color: Colors.transparent,
                      child: SingleChildScrollView(
                        // scroll instead of overflow if content is tall
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ IMAGE
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: const Radius.circular(24),
                                bottom: hasTitle
                                    ? Radius.zero
                                    : const Radius.circular(24),
                              ),
                              child: ConstrainedBox(
                                // cap image height relative to screen
                                constraints: BoxConstraints(
                                  maxHeight: screenH * 0.6,
                                ),
                                child: Image.network(
                                  widget.ad.image!,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      height: 300,
                                      color: Colors.black54,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFFF2D78),
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 300,
                                    color: Colors.black54,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Color(0xFF4A4A68),
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ✅ TITLE + STORE NAME SECTION
                            if (hasTitle)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(24),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.ad.storeName != null &&
                                        widget.ad.storeName!.isNotEmpty)
                                      Text(
                                        widget.ad.storeName!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    if (widget.ad.title != null &&
                                        widget.ad.title!.isNotEmpty)
                                      Text(
                                        widget.ad.title!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1C1C2E),
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

                // ── Top-right badge: countdown number OR close icon ──────
                Positioned(
                  top: -12,
                  right: -12,
                  child: GestureDetector(
                    // Only closable during phase 2
                    onTap: _isClosable ? _close : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF2D78),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: !_isClosable
                            // Phase 1: countdown number only, no close icon
                            ? Text(
                                '$_secondsLeft',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            // Phase 2: close icon, tappable
                            : const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
