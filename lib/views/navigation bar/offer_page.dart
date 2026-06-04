import 'package:club_india_user/models/user_model.dart';
import 'package:club_india_user/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpecialOffersPage extends StatefulWidget {
  final VoidCallback? onBack;
  const SpecialOffersPage({super.key, this.onBack});

  @override
  State<SpecialOffersPage> createState() => _SpecialOffersPageState();
}

class _SpecialOffersPageState extends State<SpecialOffersPage> {
  bool _loading = true;
  String? _error;
  List<OfferModel> _offers = [];
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final HomeResponseModel data = await UserApiService.getHome();
      final List<OfferModel> cityOffers = data.offers;
      final cats = <String>{'All'};
      for (final o in cityOffers) {
        if (o.offerType.isNotEmpty) cats.add(_formatCategory(o.offerType));
      }
      setState(() {
        _offers = cityOffers;
        _categories = cats.toList();
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = 'All';
        }
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Network error. Check your connection.';
      });
    }
  }

  String _formatCategory(String raw) =>
      raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);

  List<OfferModel> get _filteredOffers => _selectedCategory == 'All'
      ? _offers.where((o) => o.isActive).toList()
      : _offers
            .where(
              (o) =>
                  o.isActive &&
                  _formatCategory(o.offerType) == _selectedCategory,
            )
            .toList();

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

  /// Build the full image URL from banner field
  String? _buildBannerUrl(String? banner) {
    if (banner == null || banner.isEmpty) return null;

    // Already a full URL
    if (banner.startsWith('http://') || banner.startsWith('https://')) {
      debugPrint('🖼️ Banner is already full URL: $banner');
      return banner;
    }

    // Relative path — prepend base URL
    final fullUrl = '${UserApiService.imageBaseUrl}/uploads/$banner';
    debugPrint('🖼️ Banner relative path: $banner');
    debugPrint('🌐 Built full URL: $fullUrl');
    return fullUrl;
  }

  void _showOfferDetails(BuildContext context, OfferModel offer, int index) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📋 [OfferDetails] Offer ID   : ${offer.id}');
    debugPrint('📋 [OfferDetails] Title      : ${offer.title}');
    debugPrint('📋 [OfferDetails] Type       : ${offer.offerType}');
    debugPrint('📋 [OfferDetails] Banner raw : ${offer.banner}');
    debugPrint(
      '📋 [OfferDetails] imageBaseUrl: ${UserApiService.imageBaseUrl}',
    );

    final bannerUrl = _buildBannerUrl(offer.banner);
    debugPrint('📋 [OfferDetails] Final URL  : $bannerUrl');
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
              // Drag handle
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

              // Banner image or fallback
              if (bannerUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    bannerUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
                      debugPrint('❌ [OfferDetails] Image load failed: $error');
                      debugPrint('   Failed URL: $bannerUrl');
                      return _fallbackBanner(gradientColors, offer.offerType);
                    },
                  ),
                )
              else
                _fallbackBanner(gradientColors, offer.offerType),

              // Details
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatCategory(offer.offerType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C2E),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
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

                    // Expiry
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
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CategoryFilterDelegate(
                      categories: _categories,
                      selected: _selectedCategory,
                      onSelect: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                  if (_filteredOffers.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No offers in this category',
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
              // Gradient Header
              Container(
                constraints: const BoxConstraints(minHeight: 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradientFor(index),
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _iconFor(offer.offerType),
                            color: Colors.white,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            offer.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatCategory(offer.offerType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // White Body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.description ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1C1C2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF8E8E93),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _validTill(offer.expiryDate),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFFFF2D78),
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
}

// ─────────────────────────────────────────────────────────────
// Category filter header
// ─────────────────────────────────────────────────────────────

class _CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryFilterDelegate({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Colors.white,
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final cat = categories[i];
            final isSelected = selected == cat;
            return GestureDetector(
              onTap: () => onSelect(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFF48FB1), Color(0xFFFFF5F8)],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4A4A68),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryFilterDelegate old) =>
      old.selected != selected || old.categories != categories;
}
