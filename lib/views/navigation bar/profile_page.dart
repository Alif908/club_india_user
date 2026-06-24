// ============================================================
// lib/views/navigation bar/profile_page.dart
// ============================================================

import 'package:club_india_user/models/user_model.dart';
import 'package:club_india_user/services/api_service.dart';
import 'package:club_india_user/services/location_service.dart';
import 'package:club_india_user/views/legal%20page/addition_legal_screen.dart';
import 'package:club_india_user/views/legal%20page/policy_screen.dart';
import 'package:club_india_user/views/legal%20page/terms_screen.dart';
import 'package:club_india_user/views/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onBack;
  const ProfilePage({super.key, this.onBack});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String? _error;
  UserModel? _user;

  String _placeName = "-";

  int _totalEarned = 0;
  int _totalRedeemed = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchStats();
  }

  Future<void> _fetchProfile() async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('👤 [ProfilePage] _fetchProfile() called');

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await UserApiService.getProfile();

      debugPrint('📦 [ProfilePage] RAW USER DATA:');
      debugPrint('   city     : "${user.city}"');
      debugPrint('   district : "${user.district}"');
      debugPrint('   state    : "${user.state}"');
      debugPrint('   latitude : ${user.latitude}');
      debugPrint('   longitude: ${user.longitude}');

      // String placeName = "—";

      // if (user.latitude != null && user.longitude != null) {
      //   try {
      //     placeName = await LocationService.getPlaceName(
      //       user.latitude!,
      //       user.longitude!,
      //     );

      //     debugPrint('📍 [ProfilePage] Reverse Geocoded Location: $placeName');
      //   } catch (e) {
      //     debugPrint('❌ reverse geocoding failed: $e');
      //   }
      // }

      String placeName = [
        user.city,
        user.district,
      ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

      debugPrint('📍 [ProfilePage] DB Location: $placeName');

      debugPrint('🏦 [ProfilePage] Bank fields:');
      debugPrint('   bankHolderName: "${user.bankHolderName}"');
      debugPrint('   bankName      : "${user.bankName}"');
      debugPrint('   accountNumber : "${user.accountNumber}"');
      debugPrint('   ifscCode      : "${user.ifscCode}"');
      debugPrint('   upiId         : "${user.upiId}"');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (!mounted) return;

      setState(() {
        _user = user;
        _placeName = placeName;

        if (_placeName.isEmpty) {
          _placeName = '—';
        }

        debugPrint("CITY = ${user.city}");
        debugPrint("DISTRICT = ${user.district}");
        debugPrint('PROFILE LOCATION = $_placeName');

        _loading = false;
      });
    } on ApiException catch (e) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ PROFILE API EXCEPTION');
      debugPrint('Status  : ${e.statusCode}');
      debugPrint('Message : ${e.message}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (e.message == 'SESSION_EXPIRED') return;

      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _fetchStats() async {
    try {
      final transactions = await UserApiService.getHistory();

      final earned = transactions
          .where((t) => t.isEarned)
          .fold(0, (sum, t) => sum + (t.rewardPoints ?? 0).toInt());

      final redeemed = transactions
          .where((t) => t.isRedeemed)
          .fold(0, (sum, t) => sum + (t.redeemedPoints ?? 0).toInt());

      debugPrint('📊 [ProfilePage] Stats from history:');
      debugPrint('   totalEarned  : $earned');
      debugPrint('   totalRedeemed: $redeemed');

      if (!mounted) return;
      setState(() {
        _totalEarned = earned;
        _totalRedeemed = redeemed;
        _statsLoaded = true;
      });
    } catch (e) {
      debugPrint('⚠️ [ProfilePage] _fetchStats failed: $e');
      if (!mounted) return;
      setState(() => _statsLoaded = false);
    }
  }

  Future<void> refreshPage() async {
    await Future.wait([_fetchProfile(), _fetchStats()]);
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
          'Profile',
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
              onRefresh: refreshPage,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _ProfileInfoCard(
                        user: _user!,
                        displayLocation: _placeName,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _PointsSummaryCard(
                        user: _user!,
                        // _statsLoaded true → history-computed values
                        // false → UserModel API fallback
                        totalEarned: _statsLoaded
                            ? _totalEarned
                            : _user!.totalEarned.toInt(),
                        totalRedeemed: _statsLoaded
                            ? _totalRedeemed
                            : _user!.totalRedeemed.toInt(),
                        statsLoading: !_statsLoaded,
                      ),
                    ),
                  ),
                  if (_user!.hasBankDetails || _user!.hasUpi)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: _BankDetailsCard(user: _user!),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _SettingsMenu(
                        phone: _user!.phone,
                        onLogout: _handleLogout,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
    );
  }

  Future<void> _handleLogout() async {
    debugPrint('🚪 [ProfilePage] Logout triggered');
    await UserApiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _buildError() {
    return RefreshIndicator(
      color: const Color(0xFFFF2D78),
      onRefresh: _fetchProfile,
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
                  onPressed: _fetchProfile,
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

// ─────────────────────────────────────────────────────────────
// Profile Info Card
// ─────────────────────────────────────────────────────────────

class _ProfileInfoCard extends StatelessWidget {
  final UserModel user;
  final String displayLocation;

  const _ProfileInfoCard({
    super.key,
    required this.user,
    required this.displayLocation,
  });

  String _memberSince() {
    if (user.createdAt == null) return 'Club India Member';
    final d = user.createdAt!;
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
    return 'Member since ${months[d.month - 1]} ${d.year}';
  }

  String get _displayName =>
      (user.name?.isNotEmpty == true) ? user.name! : user.phone;

  String get _location {
    final result = displayLocation.isNotEmpty ? displayLocation : '—';
    debugPrint('📍 [_ProfileInfoCard] Final UI location: "$result"');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6BA8), Color(0xFFFF2D78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _memberSince(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: '+91 ${user.phone}',
          ),
          if (user.email?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            _InfoRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: user.email!,
            ),
          ],
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: _location,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Points Summary Card
// ─────────────────────────────────────────────────────────────

class _PointsSummaryCard extends StatelessWidget {
  final UserModel user;
  final int totalEarned;
  final int totalRedeemed;
  final bool statsLoading;

  const _PointsSummaryCard({
    required this.user,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.statsLoading,
  });

  String _fmt(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );

  String _fmtDouble(double v) => v.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0EC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Points Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),

          // ── Vertically stacked stat rows ──────────────────────────────
          Column(
            children: [
              _StatBox(
                label: 'Wallet Balance',
                // walletBalance: UserModel API value (always reliable)
                value: _fmtDouble(user.walletBalance),
                color: const Color(0xFFFF2D78),
                icon: Icons.account_balance_wallet_outlined,
                loading: false,
              ),
              const SizedBox(height: 10),
              _StatBox(
                label: 'Total Earned',
                // history-computed sum; placeholder while loading
                value: _fmt(totalEarned),
                color: const Color(0xFF00B96B),
                icon: Icons.trending_up_rounded,
                loading: statsLoading,
              ),
              const SizedBox(height: 10),
              _StatBox(
                label: 'Total Redeemed',
                // history-computed sum; placeholder while loading
                value: _fmt(totalRedeemed),
                color: const Color(0xFFFF2D78),
                icon: Icons.redeem_rounded,
                loading: statsLoading,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stat Box — full-width horizontal card
// ─────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool loading;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Leading colored icon badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),

          // Label
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Value — grey box placeholder while history is loading
          loading
              ? Container(
                  width: 48,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bank Details Card
// ─────────────────────────────────────────────────────────────

class _BankDetailsCard extends StatelessWidget {
  final UserModel user;
  const _BankDetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 20,
                color: Color(0xFFFF2D78),
              ),
              const SizedBox(width: 8),
              const Text(
                'Bank Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (user.bankHolderName?.isNotEmpty == true)
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Account Holder',
              value: user.bankHolderName!,
            ),
          if (user.bankName?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.account_balance,
              label: 'Bank',
              value: user.bankName!,
            ),
          ],
          if (user.accountNumber?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.credit_card_outlined,
              label: 'Account Number',
              value: user.accountNumber!,
            ),
          ],
          if (user.ifscCode?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.tag,
              label: 'IFSC Code',
              value: user.ifscCode!,
            ),
          ],
          if (user.upiId?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _InfoRow(icon: Icons.payment, label: 'UPI ID', value: user.upiId!),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Info Row
// ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: const Color(0xFFFF2D78)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Settings Menu
// ─────────────────────────────────────────────────────────────

class _SettingsMenu extends StatelessWidget {
  final String phone;
  final Future<void> Function() onLogout;

  const _SettingsMenu({required this.phone, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── General settings card ──────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFF5B8DEF),
                label: 'Notifications',
                onTap: () {},
              ),
              _Divider(),
              _Divider(),
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFF9B59B6),
                label: 'Help & Support',
                onTap: () {},
              ),
              _Divider(),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Legal card ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 2),
                child: Text(
                  'LEGAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF5B8DEF),
                label: 'Terms & Conditions',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsAndConditionsPage(),
                  ),
                ),
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF2DB87D),
                label: 'Privacy Policy',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                ),
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.gavel_rounded,
                iconColor: const Color(0xFFFF9500),
                label: 'Additional Legal Policies',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdditionalLegalPoliciesPage(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFFF3B30),
                label: 'Logout',
                labelColor: const Color(0xFFFF3B30),
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Delete account ─────────────────────────────────
        const _DeleteAccountButton(),

        const SizedBox(height: 50),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF999999)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await onLogout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Settings Tile
// ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor = const Color(0xFF1A1A2E),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 54,
      color: Color(0xFFF5F5F5),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Delete Account Button
// ─────────────────────────────────────────────────────────────

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            content: const Text(
              'You will be redirected to the account deletion page. This action is irreversible. Do you want to continue?',
              style: TextStyle(color: Color(0xFF666666)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        try {
          await UserApiService.openDeleteAccountPage();
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text(
              'Delete Account',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
