import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memoire/administrateur/eleve_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../administrateur/admin_dashboard.dart';
import '../administrateur/chef_depart_dashboard.dart';
import '../administrateur/formateur_dashboard.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String _selectedUserType = '';
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _particlesController;
  late AnimationController _logoController;
  late AnimationController _errorController; // 🔥 NOUVEAU: Animation pour les erreurs

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _logoScale;
  late Animation<double> _errorShake; // 🔥 NOUVEAU: Animation de secousse pour les erreurs

  Future<Map<String, dynamic>> _loginUser(String email, String password) async {
    const String baseUrl = 'http://10.0.2.2:8000/api';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map<String, dynamic> &&
            responseData['success'] == true &&
            responseData['data'] != null) {

          return {
            'success': true,
            'user': responseData['data']['user'],
            'access_token': responseData['data']['token'],
            'message': responseData['message'],
          };
        } else {
          return {
            'success': false,
            'message': 'Format de réponse invalide',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Email ou mot de passe incorrect',
        };
      } else if (response.statusCode == 422) {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Données invalides',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Données invalides',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur (${response.statusCode}). Veuillez réessayer.',
        };
      }
    } catch (e) {
      print('Erreur réseau: $e');
      rethrow;
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('user_data', jsonEncode(user));
    await prefs.setString('user_role', user['role']['intitule']);
    await prefs.setInt('user_id', user['id']);

    print('=== DONNÉES SAUVEGARDÉES ===');
    print('Token: ${token.substring(0, 20)}...');
    print('User: ${user['nom']} ${user['prenom']}');
    print('Role: ${user['role']['intitule']}');
    print('==========================');
  }

  void _navigateTodashboard(String role) {
    print('Navigation vers dashboard pour le rôle: $role');

    switch (role.toLowerCase()) {
      case 'administrateur':
      case 'admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(),
          ),
        );
        break;

      case 'formateur':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FormateurDashboard(),
          ),
        );
        break;
      case 'directeur des etudes':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context)=> ChefDepartDashboard())
        );
        break;
      case 'elève':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context)=>EleveDashboard())
        );
    }
  }

  // 🔥 NOUVEAU: SnackBar d'erreur avec design moderne et animations
  void _showErrorSnackBar(String message) {
    // Déclencher l'animation de secousse
    _errorController.forward().then((_) {
      _errorController.reverse();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Erreur de connexion',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        // 🔥 Arrière-plan avec gradient
        clipBehavior: Clip.antiAlias,
      ),
    );

    // Overlay avec gradient pour le SnackBar
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 32,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE53E3E),
                  Color(0xFFDC2626),
                  Color(0xFFB91C1C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE53E3E).withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Connexion échouée',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    overlayEntry.remove();
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Supprimer automatiquement après 5 secondes
    Future.delayed(Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // 🔥 NOUVEAU: Dialog d'erreur élégant avec animations
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône d'erreur animée
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE53E3E),
                        Color(0xFFDC2626),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFE53E3E).withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                SizedBox(height: 24),

                // Titre
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12),

                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32),

                // Bouton de fermeture
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2E4F99),
                        Color(0xFF1E3A7A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Réessayer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _debugTokenAndUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userData = prefs.getString('user_data');
    final userRole = prefs.getString('user_role');

    print('=== DEBUG INFO ===');
    print('Token sauvegardé: ${token?.substring(0, 20)}...' ?? 'Aucun token');
    print('User data: $userData');
    print('User role: $userRole');
    print('================');
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _particlesController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _logoController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    // 🔥 NOUVEAU: Contrôleur d'animation pour les erreurs
    _errorController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut)
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_particlesController);

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut)
    );

    // 🔥 NOUVEAU: Animation de secousse pour les erreurs
    _errorShake = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _errorController, curve: Curves.elasticOut),
    );

    // Démarrer les animations
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _slideController.forward();
      _logoController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _particlesController.dispose();
    _logoController.dispose();
    _errorController.dispose(); // 🔥 NOUVEAU
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildTopSection(),
              Expanded(
                child: _buildBottomSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      child: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A6FA5), // Bleu CFPT principal
                  Color(0xFF3D5A91), // Bleu CFPT moyen
                  Color(0xFF2A4073), // Bleu CFPT foncé
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(160),
                bottomRight: Radius.circular(600),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4A6FA5).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),

          // Particules animées
          _buildAnimatedParticles(),

          // Contenu principal
          Container(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 60),

                // Logo CFPT animé
                AnimatedBuilder(
                  animation: _logoScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: _buildCFPTLogo(),
                    );
                  },
                ),

                SizedBox(height: 20),

                // Titre avec effet de brillance
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, Colors.white70, Colors.white],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: Text(
                    'Connexion',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // Sous-titre
                Text(
                  'CFPT Sénégal-Japon',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(15, (index) {
            final random = math.Random(index);
            final left = random.nextDouble();
            final top = random.nextDouble();
            final animationOffset = math.sin(_particleAnimation.value * 2 * math.pi + index) * 30;

            return Positioned(
              left: MediaQuery.of(context).size.width * left,
              top: MediaQuery.of(context).size.height * 0.45 * top + animationOffset,
              child: Container(
                width: 6 + random.nextDouble() * 4,
                height: 6 + random.nextDouble() * 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
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
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(8),
        child: ClipOval(
          child: Image.asset(
            'images/img2.jpg', // 🔥 Logo officiel CFPT
            width: 74,
            height: 74,
            fit: BoxFit.cover, // Pour bien remplir le cercle
            errorBuilder: (context, error, stackTrace) {
              // Fallback stylé en cas d'erreur
              return Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2E4F99), // Bleu CFPT exact
                      Color(0xFF1E3A7A), // Bleu CFPT foncé
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CFPT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'SN-JP',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                // Titre de section
                Text(
                  'Accédez à votre espace',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),

                Text(
                  'Entrez vos identifiants pour continuer',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: 32),

                // 🔥 NOUVEAU: Wrapper avec animation de secousse pour les champs
                AnimatedBuilder(
                  animation: _errorShake,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        math.sin(_errorShake.value * math.pi * 4) * 5,
                        0,
                      ),
                      child: Column(
                        children: [
                          _buildEmailField(),
                          SizedBox(height: 24),
                          _buildPasswordField(),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 40),
                _buildLoginButton(),

                SizedBox(height: 32),

                // Footer avec informations
                _buildFooterInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Entrez votre email',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Container(
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF2E4F99).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.email_outlined, color: Color(0xFF2E4F99), size: 20),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
            style: TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email requis';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Email invalide';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Entrez votre mot de passe',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Container(
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF2E4F99).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lock_outline, color: Color(0xFF2E4F99), size: 20),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[500],
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
            style: TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Mot de passe requis';
              }
              if (value.length < 6) {
                return 'Minimum 6 caractères';
              }
              return null;
            },
          ),
        ),
        SizedBox(
          height: 11,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
                onPressed: (){},
                child: Container(
                  child: Text(
                    'Mot de passe oublié?',
                    style: TextStyle(
                        color: Color(0xFF2D3748)
                    ),
                  ),
                )
            )
          ],
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2E4F99),
            Color(0xFF1E3A7A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2E4F99).withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Se connecter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Center(
      child: Column(
        children: [
          Container(
            height: 1,
            width: 60,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'Centre de Formation Professionnelle et Technique',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState == null) {
      _showErrorSnackBar('Erreur de formulaire');
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await AuthService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        // 🔥 DEBUG POUR VOIR LA RÉPONSE
        print('=== RÉPONSE AUTHSERVICE ===');
        print('Response: $response');
        print('Success: ${response['success']}');
        print('Token: ${response.containsKey('token') ? "Présent" : "Absent"}');
        print('Access_token: ${response.containsKey('access_token') ? "Présent" : "Absent"}');
        print('User: ${response.containsKey('user') ? "Présent" : "Absent"}');
        print('========================');

        if (response.containsKey('success') && response['success'] == true) {
          // 🔥 VÉRIFIER LES DEUX FORMATS DE TOKEN
          final token = response['token'] ?? response['access_token'];
          final user = response['user'];

          if (token != null && user != null) {
            print('✅ Connexion réussie avec token');

            if (user['role'] != null && user['role']['intitule'] != null) {
              _navigateTodashboard(user['role']['intitule']);
            } else {
              _showErrorSnackBar('Rôle utilisateur non défini');
            }
          } else {
            _showErrorSnackBar('Token ou données utilisateur manquants');
          }
        } else {
          // 🔥 NOUVEAU: Messages d'erreur personnalisés selon le type d'erreur
          String errorMessage = response['message'] ?? 'Erreur inconnue';

          if (errorMessage.toLowerCase().contains('email') ||
              errorMessage.toLowerCase().contains('password') ||
              errorMessage.toLowerCase().contains('incorrect')) {
            _showErrorSnackBar('Vérifiez votre email et mot de passe');
          } else if (errorMessage.toLowerCase().contains('network') ||
              errorMessage.toLowerCase().contains('connexion')) {
            _showErrorSnackBar('Problème de connexion. Vérifiez votre internet');
          } else if (errorMessage.toLowerCase().contains('server') ||
              errorMessage.toLowerCase().contains('serveur')) {
            _showErrorSnackBar('Serveur temporairement indisponible');
          } else {
            _showErrorSnackBar(errorMessage);
          }
        }

      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('Erreur lors de la connexion: $e');

        // 🔥 NOUVEAU: Gestion d'erreur plus précise avec des messages personnalisés
        if (e.toString().contains('SocketException') ||
            e.toString().contains('NetworkException')) {
          _showErrorSnackBar('Pas de connexion internet. Vérifiez votre réseau');
        } else if (e.toString().contains('TimeoutException')) {
          _showErrorSnackBar('Délai d\'attente dépassé. Réessayez plus tard');
        } else if (e.toString().contains('FormatException')) {
          _showErrorSnackBar('Erreur de format des données');
        } else {
          _showErrorSnackBar('Une erreur inattendue s\'est produite');
        }
      }
    }
  }
}