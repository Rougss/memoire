import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../authentification/login_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _particlesController;
  late AnimationController _bounceController;

  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<double> _progressWidth;
  late Animation<double> _particleAnimation;
  late Animation<double> _bounceAnimation;

  double progressValue = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _progressWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    // Particles animation
    _particlesController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _particlesController,
    );

    // Bounce animation for loading dots
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _bounceController,
    );
  }

  void _startAnimationSequence() {
    // Logo animation starts after 300ms
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) _logoController.forward();
    });

    // Text animation starts after 800ms
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });

    // Progress animation starts after 1200ms
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _progressController.forward();
        _startProgressTimer();
      }
    });
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted) {
        setState(() {
          progressValue += 2;
          if (progressValue >= 100) {
            timer.cancel();
            // Navigate to HomeScreen after progress completes
            Timer(const Duration(milliseconds: 500), () {
              _navigateToLogin();
            });
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) =>  LoginScreen()), // Redirection vers LoginScreen
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _particlesController.dispose();
    _bounceController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1e3a8a), // blue-900
              Color(0xFF1e40af), // blue-800
              Color(0xFF7c3aed), // purple-600
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles background
            _buildParticlesBackground(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animation
                  AnimatedBuilder(
                    animation: _logoScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: _buildCFPTLogo(),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Text with fade animation
                  AnimatedBuilder(
                    animation: _textOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            const Text(
                              'CFPT Sénégal-Japon',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Centre de Formation Professionnelle et Technique',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFFbfdbfe), // blue-200
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Gestion Intelligente des Emplois du Temps',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFdbeafe), // blue-100
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Progress bar
                  _buildProgressBar(),

                  const SizedBox(height: 40),

                  // Loading dots
                  _buildLoadingDots(),
                ],
              ),
            ),

            // Version info at bottom
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Version 1.0.0 | Développé par ITEA',
                  style: TextStyle(
                    color: const Color(0xFF93c5fd).withOpacity(0.7), // blue-300
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticlesBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(20, (index) {
            final random = math.Random(index);
            final left = random.nextDouble();
            final top = random.nextDouble();
            final animationOffset = math.sin(_particleAnimation.value * 2 * math.pi + index) * 20;

            return Positioned(
              left: MediaQuery.of(context).size.width * left,
              top: MediaQuery.of(context).size.height * top + animationOffset,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildCFPTLogo() {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563eb), // blue-600
            Color(0xFF1d4ed8), // blue-700
            Color(0xFF1e40af), // blue-800
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFeff6ff), // blue-50
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(80, 80),
            painter: CFPTLogoPainter(),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      width: 320,
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue / 100,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF60a5fa), // blue-400
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Initialisation...',
                style: TextStyle(
                  color: Color(0xFFbfdbfe), // blue-200
                  fontSize: 14,
                ),
              ),
              Text(
                '${progressValue.round()}%',
                style: const TextStyle(
                  color: Color(0xFFbfdbfe), // blue-200
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.16;
            final animationValue = (_bounceAnimation.value + delay) % 1.0;
            final scale = animationValue < 0.5
                ? (animationValue * 2)
                : (2 - animationValue * 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF93c5fd), // blue-300
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class CFPTLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1d4ed8) // blue-700
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Letter C
    final cPath = Path();
    cPath.moveTo(centerX - 30, centerY - 25);
    cPath.quadraticBezierTo(centerX - 30, centerY - 35, centerX - 20, centerY - 35);
    cPath.lineTo(centerX - 10, centerY - 35);
    cPath.quadraticBezierTo(centerX, centerY - 35, centerX, centerY - 25);
    cPath.lineTo(centerX, centerY - 15);
    cPath.quadraticBezierTo(centerX, centerY - 5, centerX - 10, centerY - 5);
    cPath.lineTo(centerX - 20, centerY - 5);
    canvas.drawPath(cPath, paint);

    // Letter F
    final fPath = Path();
    fPath.moveTo(centerX + 10, centerY - 35);
    fPath.lineTo(centerX + 10, centerY - 5);
    fPath.moveTo(centerX + 10, centerY - 35);
    fPath.lineTo(centerX + 30, centerY - 35);
    fPath.moveTo(centerX + 10, centerY - 20);
    fPath.lineTo(centerX + 25, centerY - 20);
    canvas.drawPath(fPath, paint);

    // Letter P
    final pPath = Path();
    pPath.moveTo(centerX - 30, centerY + 5);
    pPath.lineTo(centerX - 30, centerY + 35);
    pPath.moveTo(centerX - 30, centerY + 5);
    pPath.lineTo(centerX - 20, centerY + 5);
    pPath.quadraticBezierTo(centerX - 10, centerY + 5, centerX - 10, centerY + 15);
    pPath.quadraticBezierTo(centerX - 10, centerY + 25, centerX - 20, centerY + 25);
    pPath.lineTo(centerX - 30, centerY + 25);
    canvas.drawPath(pPath, paint);

    // Letter T
    final tPath = Path();
    tPath.moveTo(centerX, centerY + 5);
    tPath.lineTo(centerX + 30, centerY + 5);
    tPath.moveTo(centerX + 15, centerY + 5);
    tPath.lineTo(centerX + 15, centerY + 35);
    canvas.drawPath(tPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}