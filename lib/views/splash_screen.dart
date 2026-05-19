import 'package:club_india_user/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _subtitleFadeAnim;

  @override
  void initState() {
    super.initState();

    // Hide status bar for full immersive splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo fade in
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    // Logo scale
    _scaleAnim = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // Subtitle fades in slightly after logo
    _subtitleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Navigate to onboarding after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        // Replace with your navigation logic:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF0F3), // very light pink top-left
              Color(0xFFFFD6E0), // soft pink center
              Color(0xFFFFB6C8), // deeper pink bottom-right
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Logo Text
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(scale: _scaleAnim, child: child),
                  );
                },
                child: const _ClubIndiaLogo(),
              ),

              const SizedBox(height: 18),

              // Animated Subtitle
              AnimatedBuilder(
                animation: _subtitleFadeAnim,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _subtitleFadeAnim,
                    child: child,
                  );
                },
                child: const Text(
                  'Earn Anywhere. Redeem Everywhere.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A4A50),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders "ClubIndia" with the gradient shimmer effect:
/// "Club" = vivid pink, "India" = faded/light pink (as seen in the design)
class _ClubIndiaLogo extends StatelessWidget {
  const _ClubIndiaLogo();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFF2D78), // vivid pink — "Club"
            Color(0xFFFF6BA8), // mid pink
            Color(0xFFFFB3CB), // light faded pink — "India"
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(bounds);
      },
      child: const Text(
        'ClubIndia',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white, // overridden by shader
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
