import 'package:flutter/material.dart';
import '../main.dart'; // Import to access the global navigatorKey

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  WelcomePageState createState() => WelcomePageState();
}

class WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..forward();

    // Fade-in: 0ms → 600ms
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.17, curve: Curves.easeOut),
    );

    // Slide up: 0ms → 600ms
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.17, curve: Curves.easeOut),
    ));

    // Progress bar fills from 0 → 1 over the full 3500ms
    _progressAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Navigate after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      navigatorKey.currentState?.pushReplacementNamed('/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Logo size: occupy ~95% of screen height, limited by width to keep aspect ratio
    final double maxWidth = size.width * 0.95;
    final double logoSize = (size.height * 0.95).clamp(300.0, maxWidth);
    final double logoPadding = logoSize * 0.03;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 5),

                  // ── Logo card ──────────────────────────────────────────
                  Container(
                    width: size.width * 0.8,
                    height: null,
                    padding: EdgeInsets.all(logoPadding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFDCE8E5),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1412343B),
                          blurRadius: 32,
                          offset: Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Color(0x0812343B),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'Assets/images/Logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: size.height * 0.038),

                  // ── App name ───────────────────────────────────────────
                  const Text(
                    'VisionCare',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12343B),
                      letterSpacing: 0.6,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Clinical badge ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDF4EE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'CLINICAL RETINOPATHY SCREENING',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF12343B),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const Spacer(flex: 4),

                  // ── Animated thin progress bar ─────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (_, __) => LinearProgressIndicator(
                          value: _progressAnim.value,
                          minHeight: 3,
                          backgroundColor: const Color(0xFFDCE8E5),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF63C7B2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Tagline ────────────────────────────────────────────
                  const Text(
                    'AI-Assisted Ophthalmology Suite',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF68777B),
                      letterSpacing: 0.3,
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
