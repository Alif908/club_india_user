// ============================================================
// lib/views/login_page.dart
// ============================================================

import 'package:club_india_user/services/api_service.dart';
import 'package:club_india_user/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'navigation_bar_page.dart';

// ── If you still use UserNotificationService, keep this import:
// import '../services/user_notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenHeight / 812.0).clamp(0.75, 1.2);

    return Scaffold(
      backgroundColor: const Color(0xFFFCEEF1),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: (screenWidth * 0.06).clamp(16.0, 32.0),
                vertical: 24.0 * scale,
              ),
              child: _LoginCard(scale: scale),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  final double scale;
  const _LoginCard({required this.scale});

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  bool _otpSent = false;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ✅ Types OTP digit by digit into the existing text field with a delay
  // between each digit — creates a "typing" animation effect in the same UI
  Future<void> _animateOtpFill(String otp) async {
    _otpController.clear();

    for (int i = 0; i < otp.length && i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 110));
      if (!mounted) return;
      final newText = otp.substring(0, i + 1);
      _otpController.value = TextEditingValue(
        text: newText,
        // Keep cursor at end after each digit
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  // ── Send OTP ────────────────────────────────────────────────────────────────
  void _onSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showSnack('Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await UserApiService.sendOtp(phone);

      // Dev only: backend returns OTP in response body
      final String? devOtp = res['otp']?.toString();
      debugPrint('🔑 OTP from server: $devOtp');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      _animController.forward(from: 0);

      // Focus OTP field
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) FocusScope.of(context).requestFocus(_otpFocus);
      });

      // ✅ Wait for OTP section slide-in animation (380ms) to finish,
      //    then animate digits one by one into the same text field
      if (devOtp != null && devOtp.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 450));
        if (!mounted) return;
        await _animateOtpFill(devOtp);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('❌ [_onSendOtp] Unexpected error: $e');
      _showSnack('Network error. Check your connection.');
    }
  }

  // ── Verify OTP ──────────────────────────────────────────────────────────────
  // ============================================================
  // REPLACEMENT for _onVerifyOtp() in lib/views/login_page.dart
  // ============================================================
  //
  // ADD this import at the top of login_page.dart:
  //   import 'package:club_india_user/services/location_service.dart';
  //
  // Then REPLACE the existing _onVerifyOtp() with the method below.
  // Everything else in login_page.dart stays exactly the same.
  // ============================================================

  // ── Verify OTP ──────────────────────────────────────────────────────────────
  void _onVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      _showSnack('Please enter the 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    // ── Step A: Fetch location before calling the API ────────────────────────
    //
    // We try to get location silently. If it fails for any reason
    // (GPS off, denied, timeout) we still let the user log in —
    // location is optional, not a blocker.
    //
    double? latitude;
    double? longitude;

    _showSnack('Fetching your location…');
    debugPrint('📍 Fetching user location...');
    final locationResult = await LocationService.getCurrentLocation();

    if (locationResult is LocationSuccess) {
      latitude = locationResult.latitude;
      longitude = locationResult.longitude;
      debugPrint('📍 Location: $latitude, $longitude');
    } else if (locationResult is LocationFailure) {
      // Log the reason but don't block login
      debugPrint('⚠️ Location skipped: ${locationResult.reason}');

      // Show a softer warning — login still continues
      if (mounted) {
        _showSnack('Location unavailable — continuing without it.');
      }

      // Optional: If permission is permanently denied, offer to open Settings.
      // Uncomment the block below if you want that behaviour:
      //
      // if (locationResult.reason.contains('permanently denied')) {
      //   final open = await showDialog<bool>(
      //     context: context,
      //     builder: (_) => AlertDialog(
      //       title: const Text('Location Permission'),
      //       content: const Text(
      //         'Location access is permanently denied. '
      //         'Open Settings to enable it?',
      //       ),
      //       actions: [
      //         TextButton(
      //           onPressed: () => Navigator.pop(context, false),
      //           child: const Text('Skip'),
      //         ),
      //         TextButton(
      //           onPressed: () => Navigator.pop(context, true),
      //           child: const Text('Open Settings'),
      //         ),
      //       ],
      //     ),
      //   );
      //   if (open == true) await LocationService.openAppSettings();
      // }
    }

    // ── Step B: Call verifyOtp API with (optional) location ─────────────────
    try {
      final phone = _phoneController.text.trim();

      final result = await UserApiService.verifyOtp(
        phone: phone,
        otp: otp,
        latitude: latitude, // null if location was unavailable
        longitude: longitude, // null if location was unavailable
      );

      debugPrint('🎟️ Logged in as user id: ${result.user.id}');

      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => MainNavScreen(phoneNumber: phone),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('❌ [_onVerifyOtp] Unexpected error: $e');
      _showSnack('Network error. Check your connection.');
    }
  }

  // ── Resend OTP ──────────────────────────────────────────────────────────────
  void _onResendOtp() async {
    _otpController.clear();
    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();

      final res = await UserApiService.sendOtp(phone);
      final String? devOtp = res['otp']?.toString();
      debugPrint('🔁 Resend OTP (dev): $devOtp');

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('OTP resent successfully!');

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) FocusScope.of(context).requestFocus(_otpFocus);
      });

      // ✅ Animate resent OTP digit by digit too
      if (devOtp != null && devOtp.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        await _animateOtpFill(devOtp);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('❌ [_onResendOtp] Unexpected error: $e');
      _showSnack('Network error. Check your connection.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF2D78),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 28.0 * s, vertical: 36.0 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28 * s),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB6C8).withOpacity(0.18),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20 * s),
          Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFF2D78), Color(0xFFFF80AB)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: (30 * s).clamp(22.0, 34.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          SizedBox(height: 8 * s),
          Center(
            child: Text(
              'Enter your phone number to continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (14 * s).clamp(11.0, 16.0),
                color: const Color(0xFF888888),
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 32 * s),
          _FieldLabel(label: 'Phone Number', scale: s),
          SizedBox(height: 10 * s),
          _InputField(
            controller: _phoneController,
            hintText: '+91 98765 43210',
            keyboardType: TextInputType.phone,
            scale: s,
            enabled: !_otpSent,
            prefixIcon: Icons.phone_outlined,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            child: _otpSent
                ? FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20 * s),
                          _FieldLabel(label: 'OTP', scale: s),
                          SizedBox(height: 10 * s),
                          // ✅ Exact same OTP input field — no UI change
                          // _animateOtpFill() types digits one by one via controller
                          _InputField(
                            controller: _otpController,
                            hintText: 'Enter 6-digit OTP',
                            keyboardType: TextInputType.number,
                            scale: s,
                            focusNode: _otpFocus,
                            prefixIcon: Icons.lock_outline_rounded,
                            disableAutofill: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                          ),
                          SizedBox(height: 10 * s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _otpSent = false;
                                    _otpController.clear();
                                    _animController.reset();
                                  }),
                                  child: Text(
                                    'Change number',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: (12 * s).clamp(10.0, 14.0),
                                      color: const Color(0xFF888888),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: GestureDetector(
                                  onTap: _onResendOtp,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          "Didn't receive? ",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: (12 * s).clamp(
                                              10.0,
                                              14.0,
                                            ),
                                            color: const Color(0xFFAAAAAA),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Resend',
                                        style: TextStyle(
                                          fontSize: (12 * s).clamp(10.0, 14.0),
                                          color: const Color(0xFFFF2D78),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(height: 28 * s),
          _GradientButton(
            label: _otpSent ? 'Verify OTP' : 'Send OTP',
            isLoading: _isLoading,
            scale: s,
            onTap: _otpSent ? _onVerifyOtp : _onSendOtp,
          ),
          SizedBox(height: 20 * s),
          Center(
            child: Text(
              'By continuing, you agree to our Terms & Privacy Policy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (11 * s).clamp(10.0, 13.0),
                color: const Color(0xFFBBBBBB),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final double scale;
  const _FieldLabel({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: (14 * scale).clamp(12.0, 16.0),
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2D2D2D),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final double scale;
  final bool enabled;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool disableAutofill;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.scale,
    this.enabled = true,
    this.focusNode,
    this.prefixIcon,
    this.inputFormatters,
    this.disableAutofill = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      height: (54 * s).clamp(46.0, 60.0),
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFFAFAFA) : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(14 * s),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (prefixIcon != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * s),
                child: Icon(
                  prefixIcon,
                  color: enabled
                      ? const Color(0xFFFF2D78)
                      : const Color(0xFFCCCCCC),
                  size: 20 * s,
                ),
              ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                enabled: enabled,
                focusNode: focusNode,
                inputFormatters: inputFormatters,
                textAlignVertical: TextAlignVertical.center,

                // ✅ Disable all system autofill for OTP field
                autofillHints: disableAutofill ? const [] : null,
                enableIMEPersonalizedLearning: !disableAutofill,
                autocorrect: !disableAutofill,
                enableSuggestions: !disableAutofill,

                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: const Color(0xFFCCCCCC),
                    fontSize: (15 * s).clamp(12.0, 17.0),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(right: 12 * s),
                  isDense: true,
                  isCollapsed: true,
                ),
                style: TextStyle(
                  fontSize: (15 * s).clamp(12.0, 17.0),
                  color: enabled
                      ? const Color(0xFF2D2D2D)
                      : const Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final double scale;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: (56 * s).clamp(48.0, 62.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF2D78), Color(0xFFFF6FAB), Color(0xFFFFAACC)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16 * s),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2D78).withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: (16 * s).clamp(13.0, 18.0),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: (18 * s).clamp(14.0, 20.0),
                  ),
                ],
              ),
      ),
    );
  }
}
