import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'login_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _bgController;
  late final AnimationController _logoController;
  late final AnimationController _ruleController;
  late final AnimationController _titleController;
  late final AnimationController _taglineController;
  late final AnimationController _barController;
  late final AnimationController _exitController;

  late final Animation<double> _bgOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _glowPulse;
  late final Animation<double> _ruleWidth;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset>  _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _barProgress;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();
    _buildAnimations();
    _runSequence();
  }

  void _buildAnimations() {
    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _bgOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _bgController, curve: Curves.easeOut));

    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.7, curve: Curves.easeOut)));
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic));
    _glowPulse = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _ruleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _ruleWidth = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ruleController, curve: Curves.easeOut));

    _titleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _titleController, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic));

    _taglineController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _taglineController, curve: Curves.easeOut));

    _barController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _barProgress = CurvedAnimation(parent: _barController, curve: Curves.easeInOut);

    _exitController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 60));
    _bgController.forward();

    await Future.delayed(const Duration(milliseconds: 150));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 350));
    _ruleController.forward();

    await Future.delayed(const Duration(milliseconds: 250));
    _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _taglineController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _barController.forward();

    await Future.delayed(const Duration(milliseconds: 1350));
    if (!mounted) return;

    await _exitController.forward();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _ruleController.dispose();
    _titleController.dispose();
    _taglineController.dispose();
    _barController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isSmall = size.height < 680; 

    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (_, child) => Opacity(opacity: _exitOpacity.value, child: child),
      child: Scaffold(
        body: Stack(
          children: [

            FadeTransition(
              opacity: _bgOpacity,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 1.4,
                    colors: [
                      Color(0xFF7B2268),
                      Color(0xFF6A1B5D),
                      Color(0xFF3A0B32),
                      Color(0xFF1E0619),
                    ],
                    stops: [0.0, 0.35, 0.70, 1.0],
                  ),
                ),
              ),
            ),

            FadeTransition(
              opacity: _bgOpacity,
              child: CustomPaint(
                size: Size(size.width, size.height),
                painter: _SplashPatternPainter(),
              ),
            ),

            AnimatedBuilder(
              animation: _glowPulse,
              builder: (_, _) => Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.07 * _glowPulse.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmall ? 8 : 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              AnimatedBuilder(
                                animation: _logoController,
                                builder: (_, child) => Opacity(
                                  opacity: _logoOpacity.value,
                                  child: Transform.scale(scale: _logoScale.value, child: child),
                                ),
                                child: _LogoBadge(size: isSmall ? 120 : 160),
                              ),

                              SizedBox(height: isSmall ? 20 : 32),

                              AnimatedBuilder(
                                animation: _ruleWidth,
                                builder: (_, _) => Container(
                                  width: 200 * _ruleWidth.value,
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.35),
                                        Colors.white.withValues(alpha: 0.35),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: isSmall ? 14 : 22),

                              FadeTransition(
                                opacity: _taglineOpacity,
                                child: Text(
                                  'RESIDENCIA PARA ADULTOS MAYORES',
                                  style: TextStyle(
                                    fontSize: isSmall ? 8 : 9,
                                    letterSpacing: 3.5,
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),

                              SizedBox(height: isSmall ? 8 : 12),

                              SlideTransition(
                                position: _titleSlide,
                                child: FadeTransition(
                                  opacity: _titleOpacity,
                                  child: Text(
                                    'Carlota',
                                    style: TextStyle(
                                      fontSize: isSmall ? 44 : 56,
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                      letterSpacing: 8,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: isSmall ? 10 : 16),


                              AnimatedBuilder(
                                animation: _ruleWidth,
                                builder: (_, _) => Container(
                                  width: 64 * _ruleWidth.value,
                                  height: 1.5,
                                  color: Colors.white.withValues(alpha: 0.40),
                                ),
                              ),

                              SizedBox(height: isSmall ? 12 : 18),


                              FadeTransition(
                                opacity: _taglineOpacity,
                                child: Text(
                                  'Cuidado · Respeto · Bienestar',
                                  style: TextStyle(
                                    fontSize: isSmall ? 10 : 12,
                                    letterSpacing: 2.2,
                                    color: Colors.white.withValues(alpha: 0.50),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const SizedBox(),
                            ),
                          ),
                          Text(
                            'CODE & LENS SOLUTIONS',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2.8,
                              color: Colors.white.withValues(alpha: 0.60),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  AnimatedBuilder(
                    animation: _barProgress,
                    builder: (_, _) => LinearProgressIndicator(
                      value: _barProgress.value,
                      minHeight: 2,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            FadeTransition(
              opacity: _bgOpacity,
              child: CustomPaint(
                size: Size(size.width, size.height),
                painter: _CornerOrnamentPainter(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _LogoBadge extends StatelessWidget {
  final double size;
  const _LogoBadge({this.size = 160});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.18),
            blurRadius: 50,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: const Color(0xFF6A1B5D).withValues(alpha: 0.50),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.80),
          width: 2,
        ),
      ),
      padding: EdgeInsets.all(size * 0.175),
      child: Image.asset(
        'assets/images/LogoCarlota.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SplashPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double i = -size.height; i < size.width * 2; i += 80) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height * 0.6, size.height), p);
    }

    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.1),
        width: size.width * 1.4,
        height: size.width * 1.4,
      ),
      0, pi, false, arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CornerOrnamentPainter extends CustomPainter {
  final Color color;
  const _CornerOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const len = 36.0;
    const pad = 22.0;
    const gap = 6.0;

    void corner(double cx, double cy, double dx, double dy) {
      canvas.drawLine(Offset(cx, cy + gap * dy), Offset(cx, cy + len * dy), p);
      canvas.drawLine(Offset(cx + gap * dx, cy), Offset(cx + len * dx, cy), p);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, cy), width: 4, height: 4),
        p..style = PaintingStyle.fill,
      );
      p.style = PaintingStyle.stroke;
    }

    corner(pad, pad, 1, 1);
    corner(size.width - pad, pad, -1, 1);
    corner(pad, size.height - pad, 1, -1);
    corner(size.width - pad, size.height - pad, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}