import 'package:club_india_user/models/user_model.dart';
import 'package:club_india_user/services/api_service.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  final VoidCallback? onBack;
  const HistoryPage({super.key, this.onBack});

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  String? _error;
  List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final transactions = await UserApiService.getHistory();
      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } on ApiException catch (e) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ HISTORY API EXCEPTION');
      debugPrint('Status  : ${e.statusCode}');
      debugPrint('Message : ${e.message}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (e.message == 'SESSION_EXPIRED') {
        debugPrint('🔒 Session expired handled globally');
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
    await _fetchHistory();
  }

  int get _totalEarned => _transactions
      .where((t) => t.isEarned)
      .fold(0, (sum, t) => sum + (t.rewardPoints ?? 0).toInt());

  int get _totalRedeemed => _transactions
      .where((t) => t.isRedeemed)
      .fold(0, (sum, t) => sum + (t.redeemedPoints ?? 0).toInt());

  _CardData _cardData(TransactionModel t) {
    final isEarned = t.isEarned;
    final pts = t.isEarned
        ? (t.rewardPoints ?? 0).toInt()
        : (t.redeemedPoints ?? 0).toInt();

    // Title: prefer a store-based label; fall back to type label
    String title;
    if (t.storeId != null) {
      title = isEarned
          ? 'Earned at Store #${t.storeId}'
          : 'Redeemed at Store #${t.storeId}';
    } else {
      title = isEarned ? 'Points Earned' : 'Points Redeemed';
    }

    // Date string — ISO to readable
    String dateStr = '';
    if (t.createdAt != null) {
      final d = t.createdAt!;
      dateStr =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'
          '  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    return _CardData(
      title: title,
      dateTime: dateStr,
      points: isEarned ? pts : -pts,
      isEarned: isEarned,
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
            if (widget.onBack != null) {
              widget.onBack!();
            }
          },
        ),
        title: const Text(
          'Transaction History',
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
              onRefresh: _fetchHistory,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _SummaryCard(
                        earned: _totalEarned,
                        redeemed: _totalRedeemed,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF2D78).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: Color(0xFFFF2D78),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_transactions.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final data = _cardData(_transactions[i]);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TransactionCard(data: data),
                          );
                        }, childCount: _transactions.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return RefreshIndicator(
      color: const Color(0xFFFF2D78),
      onRefresh: _fetchHistory,
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
                  onPressed: _fetchHistory,
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
}

class _CardData {
  final String title;
  final String dateTime;
  final int points;
  final bool isEarned;

  const _CardData({
    required this.title,
    required this.dateTime,
    required this.points,
    required this.isEarned,
  });
}

class _SummaryCard extends StatelessWidget {
  final int earned;
  final int redeemed;
  const _SummaryCard({required this.earned, required this.redeemed});

  String _fmt(int v) => v.abs().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0EC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Month',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earned',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${_fmt(earned)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B96B),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Redeemed',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmt(redeemed),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF2D78),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Card
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final _CardData data;
  const _TransactionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isEarned = data.isEarned;
    final Color iconBg = isEarned
        ? const Color(0xFFE8FAF2)
        : const Color(0xFFFFEEF4);
    final Color iconColor = isEarned
        ? const Color(0xFF00B96B)
        : const Color(0xFFFF2D78);
    final IconData iconData = isEarned
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final String pointsText = isEarned ? '+${data.points}' : '${data.points}';
    final Color pointsColor = isEarned
        ? const Color(0xFF00B96B)
        : const Color(0xFFFF2D78);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(iconData, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.dateTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            pointsText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: pointsColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
