import 'package:club_india_user/models/user_model.dart';
import 'package:club_india_user/services/api_service.dart';
import 'package:flutter/material.dart';

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
      final home = await UserApiService.getHome();

      // Build category list from actual offer types; 'All' always first
      final cats = <String>{'All'};
      for (final o in home.offers) {
        if (o.offerType.isNotEmpty) cats.add(_formatCategory(o.offerType));
      }

      setState(() {
        _offers = home.offers;
        _categories = cats.toList();
        // Reset selection if previous category no longer exists
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
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Network error. Check your connection.';
      });
    }
  }

  /// Capitalise "normal" → "Normal", "popup" → "Popup", etc.
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

  // ── Offer → card display data ────────────────────────────────────────────

  /// Pick a gradient based on offer index (cycles through palette)
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

  /// Format expiry date to "Valid till DD MMM YYYY"
  String _validTill(DateTime? date) {
    if (date == null) return 'No expiry';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Valid till ${date.day} ${months[date.month - 1]} ${date.year}';
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
            if (widget.onBack != null) {
              widget.onBack!();
            }
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
            onPressed: _fetchOffers,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D78),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard({required OfferModel offer, required int index}) {
    return Container(
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
            // ── Gradient Header ──────────────────────────────────────
            Container(
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradientFor(index),
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  // Store ID badge (store name not in OfferModel;
                  // show offer type as badge instead)
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

            // ── White Body ───────────────────────────────────────────
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _showClaimDialog(context, offer),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF80AB), Color(0xFFFF2D78)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Claim',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
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
    );
  }

  void _showClaimDialog(BuildContext context, OfferModel offer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          offer.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Claim "${offer.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8E8E93)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${offer.title} claimed successfully! 🎉'),
                  backgroundColor: const Color(0xFFFF2D78),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D78),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Claim', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter header (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

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
