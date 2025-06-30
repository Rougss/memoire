import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../authentification/login_screen.dart';
import '../services/auth_service.dart';
import '../administrateur/admin_dashboard.dart';
import '../administrateur/formateur_dashboard.dart';
import '../administrateur/chef_depart_dashboard.dart';
import '../administrateur/eleve_dashboard.dart';

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
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<double> _progressWidth;
  late Animation<double> _particleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  double progressValue = 0.0;
  Timer? _progressTimer;
  String loadingText = 'Initialisation...';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
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

    // Pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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
        _startProgressAndAuth();
      }
    });
  }

  void _startProgressAndAuth() {
    _checkAuthenticationStatus();
    _startProgressTimer();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      print('🔄 Vérification du statut d\'authentification...');

      if (mounted) {
        setState(() {
          loadingText = 'Vérification de la session...';
        });
      }

      final sessionData = await AuthService.checkExistingSession();

      if (sessionData != null && sessionData['isLoggedIn'] == true) {
        final userRole = sessionData['role'];
        print('✅ Session trouvée pour rôle: $userRole');

        if (mounted) {
          setState(() {
            loadingText = 'Connexion automatique...';
          });
        }

        _waitForProgressAndNavigate(() => _navigateToDashboard(userRole));
      } else {
        print('❌ Pas de session, redirection vers login');

        if (mounted) {
          setState(() {
            loadingText = 'Chargement du login...';
          });
        }

        _waitForProgressAndNavigate(() => _navigateToLogin());
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification auth: $e');

      if (mounted) {
        setState(() {
          loadingText = 'Erreur de connexion...';
        });
      }

      _waitForProgressAndNavigate(() => _navigateToLogin());
    }
  }

  void _waitForProgressAndNavigate(VoidCallback navigationCallback) {
    if (progressValue >= 80) {
      Timer(const Duration(milliseconds: 800), () {
        if (mounted) {
          navigationCallback();
        }
      });
    } else {
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (progressValue >= 95 || !mounted) {
          timer.cancel();
          if (mounted) {
            Timer(const Duration(milliseconds: 500), () {
              if (mounted) {
                navigationCallback();
              }
            });
          }
        }
      });
    }
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted) {
        setState(() {
          progressValue += 2;
          if (progressValue >= 100) {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _navigateToDashboard(String role) {
    Widget targetScreen;

    switch (role.toLowerCase()) {
      case 'administrateur':
      case 'admin':
        targetScreen = AdminDashboard();
        break;
      case 'formateur':
        targetScreen = FormateurDashboard();
        break;
      case 'directeur des etudes':
        targetScreen = ChefDepartDashboard();
        break;
      case 'elève':
        targetScreen = EleveDashboard();
        break;
      default:
        print('⚠️ Rôle non reconnu: $role, redirection vers login');
        _navigateToLogin();
        return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
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
    _pulseController.dispose();
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
              Color(0xFF4A6FA5), // Bleu CFPT principal
              Color(0xFF3D5A91), // Bleu CFPT foncé
              Color(0xFF2A4073), // Bleu CFPT très foncé
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
                  // Logo avec animations
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoScale, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value * (1.0 + _pulseAnimation.value * 0.05),
                        child: Transform.rotate(
                          angle: _logoRotation.value * 0.1,
                          child: _buildCFPTLogo(),
                        ),
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
                                color: Color(0xFFE3F2FD), // Bleu clair
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Gestion Intelligente des Emplois du Temps',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFBBDEFB), // Bleu très clair
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
                    color: const Color(0xFFBBDEFB).withOpacity(0.7),
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
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: ClipOval(
            child: Image.asset(
              'images/img2.jpg',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback en cas d'erreur de chargement de l'image
                return Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4A6FA5),
                  ),
                  child: const Center(
                    child: Text(
                      'CFPT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
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
                  Color(0xFFE53E3E), // Rouge CFPT pour la barre de progression
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loadingText,
                style: const TextStyle(
                  color: Color(0xFFE3F2FD),
                  fontSize: 14,
                ),
              ),
              Text(
                '${progressValue.round()}%',
                style: const TextStyle(
                  color: Color(0xFFE3F2FD),
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
                    color: Color(0xFFE53E3E), // Rouge CFPT
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