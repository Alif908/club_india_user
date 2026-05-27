// ============================================================
// lib/views/navigation bar/redeem_point_screen.dart
// ============================================================

import 'package:club_india_user/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RedeemPointsPage extends StatefulWidget {
  final double walletBalance;
  final void Function(double remainingBalance)? onRedeemSuccess;

  const RedeemPointsPage({
    super.key,
    required this.walletBalance,
    this.onRedeemSuccess,
  });

  @override
  State<RedeemPointsPage> createState() => _RedeemPointsPageState();
}

class _RedeemPointsPageState extends State<RedeemPointsPage> {
  // ── Constants ────────────────────────────────────────────────
  static const double _conversionRate = 0.10;
  static const int _minPoints = 500;

  // ── State ────────────────────────────────────────────────────
  late double _currentBalance;
  late double _sliderMin;
  late double _sliderMax;
  late double _selectedPoints;
  bool _isRedeeming = false;
  bool _insufficientBalance = false;
  bool _loadingProfile = true;

  // 🔥 FIX: Track whether user has manually interacted with slider/input
  // so we don't reset their selection on balance refresh
  bool _userHasInteracted = false;

  // ── Controllers ──────────────────────────────────────────────
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  // ── Computed ─────────────────────────────────────────────────
  double get _rupeeValue => _selectedPoints * _conversionRate;
  bool get _sliderEnabled => _sliderMax > _sliderMin && !_isRedeeming;

  String get _formattedPoints {
    final pts = _selectedPoints.toInt();
    if (pts >= 1000) {
      final thousands = pts ~/ 1000;
      final remainder = (pts % 1000).toString().padLeft(3, '0');
      return '$thousands,$remainder';
    }
    return pts.toString();
  }

  String _formatBalance(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  // ── Init ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _currentBalance = widget.walletBalance;
    _initSliderRange(preserveSelection: false);
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    try {
      final user = await UserApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _currentBalance = user.walletBalance; // fresh balance

        // 🔥 FIX: Only reset slider if user has NOT interacted yet
        _initSliderRange(preserveSelection: _userHasInteracted);

        // Auto-fill bank details only if fields are still empty
        if (_accountHolderController.text.isEmpty &&
            user.bankHolderName?.isNotEmpty == true) {
          _accountHolderController.text = user.bankHolderName!;
        }
        if (_bankNameController.text.isEmpty &&
            user.bankName?.isNotEmpty == true) {
          _bankNameController.text = user.bankName!;
        }
        if (_accountNumberController.text.isEmpty &&
            user.accountNumber?.isNotEmpty == true) {
          _accountNumberController.text = user.accountNumber!;
        }
        if (_ifscController.text.isEmpty && user.ifscCode?.isNotEmpty == true) {
          _ifscController.text = user.ifscCode!;
        }
        if (_upiController.text.isEmpty && user.upiId?.isNotEmpty == true) {
          _upiController.text = user.upiId!;
        }
        _loadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  // 🔥 FIX: preserveSelection = true → keep _selectedPoints if still valid
  void _initSliderRange({required bool preserveSelection}) {
    final balanceInt = _currentBalance.toInt();
    if (balanceInt < _minPoints) {
      _insufficientBalance = true;
      _sliderMin = 0;
      _sliderMax = 0;
      _selectedPoints = 0;
    } else {
      _insufficientBalance = false;
      _sliderMin = _minPoints.toDouble();
      _sliderMax = balanceInt.clamp(_minPoints, 999999).toDouble();

      if (preserveSelection) {
        // Keep existing selection but re-clamp to new valid range
        _selectedPoints = _selectedPoints.clamp(_sliderMin, _sliderMax);
      } else {
        _selectedPoints = 5000.0.clamp(_sliderMin, _sliderMax);
      }
    }
    _syncController();
  }

  void _syncController() {
    _pointsController.text = _selectedPoints.toInt().toString();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  // ── Points input handlers ─────────────────────────────────────
  void _onPointsInputChanged(String value) {
    _userHasInteracted = true; // 🔥 FIX: Mark as interacted
    final parsed = double.tryParse(value);
    if (parsed == null) return;
    setState(() => _selectedPoints = parsed.clamp(_sliderMin, _sliderMax));
  }

  void _onPointsInputSubmitted() {
    setState(
      () => _selectedPoints = _selectedPoints.clamp(_sliderMin, _sliderMax),
    );
    _syncController();
    _moveCursorToEnd();
  }

  void _moveCursorToEnd() {
    _pointsController.selection = TextSelection.fromPosition(
      TextPosition(offset: _pointsController.text.length),
    );
  }

  void _selectPreset(int points) {
    if (_insufficientBalance) return;
    _userHasInteracted = true; // 🔥 FIX: Mark as interacted
    setState(
      () => _selectedPoints = points.toDouble().clamp(_sliderMin, _sliderMax),
    );
    _syncController();
  }

  // ── Validation ───────────────────────────────────────────────
  String? _validate() {
    if (_insufficientBalance) {
      return 'Insufficient balance. Minimum $_minPoints points required.';
    }
    if (_selectedPoints < _minPoints) {
      return 'Minimum redemption is $_minPoints points.';
    }
    if (_selectedPoints > _currentBalance) {
      return 'Selected points exceed your balance.';
    }
    if (_accountHolderController.text.trim().isEmpty) {
      return 'Please enter the account holder name.';
    }
    if (_accountNumberController.text.trim().isEmpty) {
      return 'Please enter the account number.';
    }
    if (_ifscController.text.trim().isEmpty) {
      return 'Please enter the IFSC code.';
    }
    // 🔥 FIX: IFSC must be exactly 11 characters
    if (_ifscController.text.trim().length != 11) {
      return 'IFSC code must be exactly 11 characters.';
    }
    return null;
  }

  // ── Redeem ───────────────────────────────────────────────────
  Future<void> _onRedeemTap() async {
    FocusScope.of(context).unfocus();
    _onPointsInputSubmitted();

    final error = _validate();
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => _isRedeeming = true);

    try {
      // Step 1: Bank details save
      await UserApiService.saveBankDetails(
        bankHolderName: _accountHolderController.text.trim(),
        bankName: _bankNameController.text.trim().isNotEmpty
            ? _bankNameController.text.trim()
            : null,
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        upiId: _upiController.text.trim().isNotEmpty
            ? _upiController.text.trim()
            : null,
      );

      // Step 2: Withdraw points
      final result = await UserApiService.withdrawPoints(_selectedPoints);

      setState(() {
        _currentBalance = result.remainingBalance;
        _userHasInteracted = false; // reset so slider re-initialises cleanly
        _initSliderRange(preserveSelection: false);
        _isRedeeming = false;
      });

      widget.onRedeemSuccess?.call(result.remainingBalance);

      if (mounted) {
        _showSnack(
          '₹${(_selectedPoints * _conversionRate).toStringAsFixed(2)} '
          'redemption initiated! Balance: ${_formatBalance(result.remainingBalance)} pts',
        );
      }
    } on ApiException catch (e) {
      setState(() => _isRedeeming = false);
      if (mounted) _showSnack(e.message, isError: true);
    } catch (e) {
      setState(() => _isRedeeming = false);
      if (mounted) {
        _showSnack('Something went wrong. Please try again.', isError: true);
      }
    }
  }

  // ── Pull-to-refresh ──────────────────────────────────────────
  Future<void> _onRefresh() async {
    setState(() => _loadingProfile = true);
    await _loadBankDetails();
  }

  // ── Confirm dialog ───────────────────────────────────────────
  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Confirm Redemption',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            content: Text(
              'Redeem $_formattedPoints points '
              '(₹${_rupeeValue.toStringAsFixed(2)}) to your bank account?',
              style: const TextStyle(color: Color(0xFF555555)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    color: Color(0xFFFF2D78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Snackbar ─────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFFFF2D78),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  // ── Input decoration ─────────────────────────────────────────
  InputDecoration _bankFieldDecoration(String label, {bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF0F0F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF2D78), width: 1.5),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFFFF2D78),
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top bar ───────────────────────────────────
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Redeem Points',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const Spacer(),
                          if (_loadingProfile)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF2D78),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Available Points card ─────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD6E7), Color(0xFFFFF0F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Points',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888888),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFF2D78), Color(0xFFF8BBD0)],
                              ).createShader(bounds),
                              child: Text(
                                _formatBalance(_currentBalance),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Insufficient balance warning ──────────────
                      if (_insufficientBalance) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3F3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFD32F2F),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You need at least 500 points to redeem.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFD32F2F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Points selector ───────────────────────────
                      if (!_insufficientBalance) ...[
                        const Text(
                          'Select Points to Redeem',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF444444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Points input ──────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 180,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFF2D78),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF2D78,
                                      ).withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _pointsController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  enabled: !_isRedeeming,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFF2D78),
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isCollapsed: true,
                                  ),
                                  onChanged: _onPointsInputChanged,
                                  onEditingComplete: _onPointsInputSubmitted,
                                  onTapOutside: (_) =>
                                      _onPointsInputSubmitted(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '= ₹${_rupeeValue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Min $_minPoints  •  Max ${_sliderMax.toInt()} pts',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFBBBBBB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Preset buttons ──────────────────────────
                        Row(
                          children: [
                            _PresetButton(
                              label: '500',
                              selected: _selectedPoints == 500,
                              enabled: _sliderEnabled && _sliderMax >= 500,
                              onTap: () => _selectPreset(500),
                            ),
                            const SizedBox(width: 10),
                            _PresetButton(
                              label: '1K',
                              selected: _selectedPoints == 1000,
                              enabled: _sliderEnabled && _sliderMax >= 1000,
                              onTap: () => _selectPreset(1000),
                            ),
                            const SizedBox(width: 10),
                            _PresetButton(
                              label: '5K',
                              selected: _selectedPoints == 5000,
                              enabled: _sliderEnabled && _sliderMax >= 5000,
                              onTap: () => _selectPreset(5000),
                            ),
                            const SizedBox(width: 10),
                            _PresetButton(
                              label: 'Max',
                              selected: _selectedPoints == _sliderMax,
                              enabled: _sliderEnabled,
                              onTap: () => _selectPreset(_sliderMax.toInt()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Slider ──────────────────────────────────
                        if (_sliderMax > _sliderMin)
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFFFF2D78),
                              inactiveTrackColor: const Color(0xFFE0E0E0),
                              thumbColor: const Color(0xFFFF2D78),
                              overlayColor: const Color(0x29FF2D78),
                              trackHeight: 5,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 22,
                              ),
                            ),
                            child: Slider(
                              value: _selectedPoints.clamp(
                                _sliderMin,
                                _sliderMax,
                              ),
                              min: _sliderMin,
                              max: _sliderMax,
                              divisions: ((_sliderMax - _sliderMin) / 100)
                                  .round()
                                  .clamp(1, 1000),
                              onChanged: _isRedeeming
                                  ? null
                                  : (value) {
                                      _userHasInteracted =
                                          true; // 🔥 FIX: Mark interacted
                                      setState(
                                        () => _selectedPoints = value
                                            .roundToDouble(),
                                      );
                                      _pointsController.text = _selectedPoints
                                          .toInt()
                                          .toString();
                                    },
                            ),
                          ),

                        if (_sliderMax > _sliderMin)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_sliderMin.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                                Text(
                                  '${_sliderMax.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],

                      // ── Bank Details section ──────────────────────
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade200)),
                          const SizedBox(width: 12),
                          Text(
                            'BANK DETAILS',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Divider(color: Colors.grey.shade200)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD6E7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.credit_card_outlined,
                              color: Color(0xFFFF2D78),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Bank Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Auto-filled indicator
                          if (!_loadingProfile &&
                              _accountNumberController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Auto-filled',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Bank fields ───────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.07),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Account Holder *
                            TextField(
                              controller: _accountHolderController,
                              textCapitalization: TextCapitalization.words,
                              enabled: !_isRedeeming,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                              decoration: _bankFieldDecoration(
                                'Account Holder Name',
                                required: true,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Bank Name (optional)
                            TextField(
                              controller: _bankNameController,
                              textCapitalization: TextCapitalization.words,
                              enabled: !_isRedeeming,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                              decoration: _bankFieldDecoration('Bank Name'),
                            ),
                            const SizedBox(height: 16),

                            // Account Number *
                            TextField(
                              controller: _accountNumberController,
                              keyboardType: TextInputType.number,
                              enabled: !_isRedeeming,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                              decoration: _bankFieldDecoration(
                                'Account Number',
                                required: true,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 🔥 FIX: IFSC — maxLength 11, uppercase enforced
                            TextField(
                              controller: _ifscController,
                              textCapitalization: TextCapitalization.characters,
                              enabled: !_isRedeeming,
                              maxLength: 11,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]'),
                                ),
                                // Force uppercase
                                TextInputFormatter.withFunction(
                                  (oldValue, newValue) => newValue.copyWith(
                                    text: newValue.text.toUpperCase(),
                                  ),
                                ),
                              ],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                              decoration: _bankFieldDecoration(
                                'IFSC Code',
                                required: true,
                              ).copyWith(counterText: ''), // hide char counter
                            ),
                            const SizedBox(height: 16),

                            // UPI ID (optional)
                            TextField(
                              controller: _upiController,
                              enabled: !_isRedeeming,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                              decoration: _bankFieldDecoration(
                                'UPI ID (optional)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Info banner ───────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE3F2FD), Color(0xFFEDE7F6)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF1976D2),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Amount will be credited to your bank account within 2-3 business days',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Redeem button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: (_isRedeeming || _insufficientBalance)
                                  ? [
                                      const Color(0xFFFFB3CC),
                                      const Color(0xFFFFCDD2),
                                    ]
                                  : [
                                      const Color(0xFFFF2D78),
                                      const Color(0xFFF8BBD0),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: (_isRedeeming || _insufficientBalance)
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF2D78,
                                      ).withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: (_isRedeeming || _insufficientBalance)
                                ? null
                                : _onRedeemTap,
                            child: _isRedeeming
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _insufficientBalance
                                        ? 'Insufficient Balance'
                                        : 'Redeem ₹${_rupeeValue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
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

// ─────────────────────────────────────────────────────────────
// _PresetButton
// ─────────────────────────────────────────────────────────────
class _PresetButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: !enabled
                ? const Color(0xFFF5F5F5)
                : selected
                ? const Color(0xFFFFD6E7)
                : const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: !enabled
                  ? const Color(0xFFE0E0E0)
                  : selected
                  ? const Color(0xFFFF2D78)
                  : const Color(0xFFFFCDD2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: !enabled
                    ? const Color(0xFFBBBBBB)
                    : selected
                    ? const Color(0xFFFF2D78)
                    : const Color(0xFF555555),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
