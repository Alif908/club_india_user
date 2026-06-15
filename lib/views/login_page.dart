// ============================================================
// lib/views/login_page.dart
// ============================================================

import 'package:club_india_user/services/api_service.dart';
import 'package:club_india_user/services/location_service.dart';
import 'package:club_india_user/views/legal%20page/policy_screen.dart';
import 'package:club_india_user/views/legal%20page/terms_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';

import 'navigation_bar_page.dart';

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
  bool _isTermsAccepted = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocation();
    });
  }

  Future<void> _checkLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Location Required'),
          content: const Text('Please turn on your location to continue.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openLocationSettings();
              },
              child: const Text('Enable Location'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _animateOtpFill(String otp) async {
    _otpController.clear();
    for (int i = 0; i < otp.length && i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 110));
      if (!mounted) return;
      final newText = otp.substring(0, i + 1);
      _otpController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  // ── Send OTP ────────────────────────────────────────────────
  void _onSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showSnack('Please enter a valid 10-digit mobile number');
      return;
    }

    if (!_isTermsAccepted) {
      _showSnack('Please accept the Terms & Conditions and Privacy Policy');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await UserApiService.sendOtp(phone);
      final String? devOtp = res['otp']?.toString();
      debugPrint('🔑 OTP from server: $devOtp');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      _animController.forward(from: 0);

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) FocusScope.of(context).requestFocus(_otpFocus);
      });

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
      _showSnack('Network error. Check your connection.');
    }
  }

  void _onVerifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length < 6) {
      _showSnack('Please enter the 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    double? latitude;
    double? longitude;

    final locationResult = await LocationService.getCurrentLocation();

    if (locationResult is LocationSuccess) {
      latitude = locationResult.latitude;
      longitude = locationResult.longitude;

      debugPrint('📍 GPS: $latitude, $longitude');
    }

    try {
      final phone = _phoneController.text.trim();

      await UserApiService.verifyOtp(
        phone: phone,
        otp: otp,
        latitude: latitude,
        longitude: longitude,
      );

      // 🔥 Get FCM Token
      final fcmToken = await FirebaseMessaging.instance.getToken();

      debugPrint('FCM TOKEN => $fcmToken');

      // 🔥 Save token to backend
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await UserApiService.saveFcmToken(fcmToken);
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(e.message);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF2D78),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;

    return Container(
      padding: EdgeInsets.all(28 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 200 * s,
              height: 110 * s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF8BBD0).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/logo/badacoinuser.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: 20 * s),
          Text(
            'Badacoin.',
            style: TextStyle(
              fontSize: (26 * s).clamp(20.0, 30.0),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1C2E),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 6 * s),
          Text(
            'Enter your mobile number to continue',
            style: TextStyle(
              fontSize: (14 * s).clamp(12.0, 16.0),
              color: const Color(0xFF8E8E93),
            ),
          ),
          SizedBox(height: 28 * s),
          _FieldLabel(label: 'Mobile Number', scale: s),
          SizedBox(height: 8 * s),
          _InputField(
            controller: _phoneController,
            hintText: '10-digit mobile number',
            keyboardType: TextInputType.phone,
            scale: s,
            enabled: !_otpSent && !_isLoading,
            prefixIcon: Icons.phone_outlined,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          SizedBox(height: 20 * s),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _otpSent
                ? FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(label: 'OTP', scale: s),
                          SizedBox(height: 8 * s),
                          _InputField(
                            controller: _otpController,
                            hintText: '6-digit OTP',
                            keyboardType: TextInputType.number,
                            scale: s,
                            focusNode: _otpFocus,
                            prefixIcon: Icons.lock_outline_rounded,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            disableAutofill: true,
                          ),
                          SizedBox(height: 10 * s),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _onSendOtp,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Didn't receive? ",
                                    style: TextStyle(
                                      fontSize: (12 * s).clamp(10.0, 14.0),
                                      color: const Color(0xFFAAAAAA),
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
                          SizedBox(height: 8 * s),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(height: 16 * s),

          // ─── T&C Checkbox ────────────────────────────────────────
          GestureDetector(
            onTap: () {
              setState(() {
                _isTermsAccepted = !_isTermsAccepted;
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20 * s,
                  height: 20 * s,
                  decoration: BoxDecoration(
                    color: _isTermsAccepted
                        ? const Color(0xFFFF2D78)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _isTermsAccepted
                          ? const Color(0xFFFF2D78)
                          : const Color(0xFFBDBDBD),
                      width: 1.8,
                    ),
                  ),
                  child: _isTermsAccepted
                      ? Icon(Icons.check, size: 13 * s, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 10 * s),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: (11 * s).clamp(10.0, 13.0),
                        color: const Color(0xFFBBBBBB),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            fontSize: (11 * s).clamp(10.0, 13.0),
                            color: const Color(0xFFFF2D78),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFFF2D78),
                            height: 1.5,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TermsAndConditionsPage(),
                                ),
                              );
                            },
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            fontSize: (11 * s).clamp(10.0, 13.0),
                            color: const Color(0xFFFF2D78),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFFF2D78),
                            height: 1.5,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyPage(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ─────────────────────────────────────────────────────────
          SizedBox(height: 20 * s),
          _GradientButton(
            label: _otpSent ? 'Verify OTP' : 'Send OTP',
            isLoading: _isLoading,
            scale: s,
            onTap: _otpSent ? _onVerifyOtp : _onSendOtp,
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────

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
