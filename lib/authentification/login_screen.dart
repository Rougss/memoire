import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:memoire/administrateur/eleve_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../administrateur/admin_dashboard.dart';
import '../administrateur/chef_depart_dashboard.dart';
import '../administrateur/formateur_dashboard.dart';

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
  late Animation<double> _fadeAnimation;

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

          // Restructurer la réponse pour correspondre à ce que votre code attend
          return {
            'success': true,
            'user': responseData['data']['user'],
            'access_token': responseData['data']['token'], // Conversion token -> access_token
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
      rethrow; // Re-lancer l'exception pour qu'elle soit gérée dans _handleLogin
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

  // Modification de la méthode _navigateTodashboard dans LoginScreen
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


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut)
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
      decoration: BoxDecoration(
        color: Colors.blue.shade300,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(160),
          bottomRight: Radius.circular(600),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100),
            Text(
              'Login',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Form(  // ← AJOUT IMPORTANT : Entourer avec Form
          key: _formKey,  // ← AJOUT IMPORTANT : Associer la clé
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              SizedBox(height: 24),
              _buildEmailField(),
              SizedBox(height: 20),
              _buildPasswordField(),
              SizedBox(height: 40),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade500),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Email',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
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
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade500),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: 'Mot de passe',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'OUBLIÉ',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[400],
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ],
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
    );
  }

  Widget _buildLoginButton() {
    return Align(
      alignment: Alignment.centerRight, // Le bouton va à droite
      child: Container(
        width: 170,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor:Colors.blue.shade300,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connexion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }



  void _handleLogin() async {
    // Vérification de sécurité
    if (_formKey.currentState == null) {
      _showErrorSnackBar('Erreur de formulaire');
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Appel à votre API Laravel
        final response = await _loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        // Vérification de sécurité pour la réponse
        if (response.containsKey('success') && response['success'] == true) {
          // Vérifications supplémentaires
          if (response.containsKey('user') &&
              response.containsKey('access_token') &&
              response['user'] != null &&
              response['access_token'] != null) {

            await _saveUserData(response['user'], response['access_token']);

            // Vérification du rôle - Correction : utiliser 'intitule' au lieu de 'nom'
            if (response['user']['role'] != null &&
                response['user']['role']['intitule'] != null) {
              _navigateTodashboard(response['user']['role']['intitule']);
            } else {
              _showErrorSnackBar('Rôle utilisateur non défini');
            }
          } else {
            _showErrorSnackBar('Données utilisateur manquantes');
          }
        } else {
          _showErrorSnackBar(response['message'] ?? 'Erreur de connexion');
        }

      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('Erreur lors de la connexion: $e'); // Pour le debug
        _showErrorSnackBar('Erreur de connexion. Vérifiez votre connexion internet.');
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}