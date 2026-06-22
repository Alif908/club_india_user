import 'package:club_india_user/models/user_model.dart';
import 'package:club_india_user/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpecialOffersPage extends StatefulWidget {
  final VoidCallback? onBack;
  const SpecialOffersPage({super.key, this.onBack});

  @override
  State<SpecialOffersPage> createState() => SpecialOffersPageState();
}

class SpecialOffersPageState extends State<SpecialOffersPage> {
  bool _loading = true;
  String? _error;
  List<OfferModel> _offers = [];

  @override
  void initState() {
    super.initState();

    debugPrint("OFFERS PAGE INIT");

    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    debugPrint("FETCH OFFERS STARTED");

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final HomeResponseModel data = await UserApiService.getHome();

      // ✅ MOVE HERE
      debugPrint("FULL RESPONSE: $data");
      debugPrint("OFFERS COUNT: ${data.offers.length}");

      setState(() {
        _offers = data.offers;
        _loading = false;
      });
    } on ApiException catch (e) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ OFFERS API EXCEPTION');
      debugPrint('Status  : ${e.statusCode}');
      debugPrint('Message : ${e.message}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (e.message == 'SESSION_EXPIRED') {
        return;
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> refreshPage() async {
    await _fetchOffers();
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _formatCategory(String raw) =>
      raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);

  List<OfferModel> get _filteredOffers => _offers;

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

  // Relative path → full URL; full URL → as-is
  String? _buildBannerUrl(String? banner) {
    if (banner == null || banner.isEmpty) return null;
    if (banner.startsWith('http://') || banner.startsWith('https://')) {
      return banner;
    }
    final fullUrl = '${UserApiService.imageBaseUrl}/uploads/$banner';
    debugPrint('🖼️ Banner: $banner → $fullUrl');
    return fullUrl;
  }

  // ── Offer detail bottom sheet ────────────────────────────────

  void _showOfferDetails(BuildContext context, OfferModel offer, int index) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📋 [OfferDetails] ID    : ${offer.id}');
    debugPrint('📋 [OfferDetails] Title : ${offer.title}');
    debugPrint('📋 [OfferDetails] Banner: ${offer.banner}');

    final bannerUrl = _buildBannerUrl(offer.banner);
    debugPrint('📋 [OfferDetails] URL   : $bannerUrl');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

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
              // ── Drag handle ─────────────────────────────
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

              // ── Banner image or gradient fallback ───────
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
                    errorBuilder: (_, error, __) {
                      debugPrint('❌ [OfferDetails] Image failed: $error');
                      return _fallbackBanner(gradientColors, offer.offerType);
                    },
                  ),
                )
              else
                _fallbackBanner(gradientColors, offer.offerType),

              // ── Detail content ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store name row
                    if (offer.storeName != null &&
                        offer.storeName!.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 18,
                            color: Color(0xFFFF2D78),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              offer.storeName!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A4A68),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Offer title
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C2E),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description (optional)
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

                    // Expiry date row
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

  // Gradient placeholder when banner image is absent or fails
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

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C2E)),
          onPressed: () {
            if (widget.onBack != null) widget.onBack!();
          },
        ),
        title: const Text(
          'Special Offers',
          style: TextStyle(
            color: Color(0xFF1C1C2E),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF2D78)),
            )
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              color: const Color(0xFFFF2D78),
              onRefresh: _fetchOffers,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_filteredOffers.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No offers available',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                  if (_filteredOffers.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        80 + MediaQuery.of(context).padding.bottom,
                      ),
                      sliver: SliverList.separated(
                        itemCount: _filteredOffers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, i) {
                          final offer = _filteredOffers[i];
                          return _buildOfferCard(offer: offer, index: i);
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return RefreshIndicator(
      color: const Color(0xFFFF2D78),
      onRefresh: _fetchOffers,
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
                  onPressed: _fetchOffers,
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

  Widget _buildOfferCard({required OfferModel offer, required int index}) {
    return GestureDetector(
      onTap: () => _showOfferDetails(context, offer, index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // ── Gradient header ────────────────────────

              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFFFEEF5),
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBFF), // soft crystal white
                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1.2,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 10,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            offer.storeName ?? 'Store',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C2E),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            offer.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Color(0xFFFF2D78),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _validTill(offer.expiryDate),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // RIGHT SIDE IMAGE
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: offer.banner != null
                            ? Image.network(
                                _buildBannerUrl(offer.banner)!,
                                fit: BoxFit.contain,
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.store,
                                  size: 40,
                                  color: Color(0xFFFF2D78),
                                ),
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
    );
  }
}
