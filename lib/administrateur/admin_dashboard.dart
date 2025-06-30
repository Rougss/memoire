import 'package:flutter/material.dart';
import 'package:memoire/screens/annee_manage_screen.dart';
import 'package:memoire/screens/competence_manage_screen.dart';
import 'package:memoire/screens/create_user_screen.dart';
import 'package:memoire/screens/role_selection_screen.dart';
import 'package:memoire/screens/user_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../screens/batiment_manage_screen.dart';
import '../screens/departement_manage_screen.dart';
import '../screens/niveau_manage_screen.dart';
import '../screens/salle_manage_screen.dart';
import '../screens/semestre_manage_screen.dart';
import '../screens/specialite_manage_screen.dart';
import '../screens/type_formation_manage_screen.dart';
import '../services/user_service.dart';
import '../screens/metier_manage_screen.dart';

// Page de profil admin
class AdminProfilePage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const AdminProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEditing = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user?['nom'] ?? '');
    _prenomController = TextEditingController(text: widget.user?['prenom'] ?? '');
    _emailController = TextEditingController(text: widget.user?['email'] ?? '');
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // AppBar moderne avec gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF2E4F99),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2E4F99),
                      Color(0xFF1E3A7A),
                      Color(0xFF1A237E),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.user?['prenom'] != null && widget.user!['prenom'].isNotEmpty
                                ? widget.user!['prenom'][0].toUpperCase()
                                : 'A',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E4F99),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Profil Administrateur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(height: 24),

                  // Section changement de mot de passe
                  _buildSection(
                    title: 'Sécurité',
                    icon: Icons.security_outlined,
                    child: _buildPasswordSection(),
                  ),

                  SizedBox(height: 24),

                  // Section actions
                  _buildSection(
                    title: 'Actions',
                    icon: Icons.settings_outlined,
                    child: _buildActionsSection(),
                  ),

                  SizedBox(height: 100), // Espace pour éviter l'overflow
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2E4F99).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Color(0xFF2E4F99), size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      children: [
        if (!_isChangingPassword) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFE53E3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock_reset, color: Color(0xFFE53E3E), size: 20),
            ),
            title: Text('Changer le mot de passe'),
            subtitle: Text(''),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _isChangingPassword = true),
          ),
        ] else ...[
          _buildPasswordField(
            controller: _oldPasswordController,
            label: 'Ancien mot de passe',
            obscure: _obscureOldPassword,
            onToggle: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
          ),
          SizedBox(height: 16),
          _buildPasswordField(
            controller: _newPasswordController,
            label: 'Nouveau mot de passe',
            obscure: _obscureNewPassword,
            onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
          SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            obscure: _obscureConfirmPassword,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isChangingPassword = false;
                      _oldPasswordController.clear();
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53E3E),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Modifier', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Gérer les préférences de notification',
          onTap: () => _showComingSoon('Notifications'),
        ),

        Divider(height: 1),
        _buildActionTile(
          icon: Icons.logout_rounded,
          title: 'Se déconnecter',
          subtitle: 'Déconnexion de votre compte',
          onTap: _logout,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? Colors.red : Color(0xFF2E4F99)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : Color(0xFF2E4F99),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF2E4F99)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF2E4F99)),
        ),
      ),
    );
  }

  void _changePassword() async {
    // Validation des champs
    if (_oldPasswordController.text.isEmpty) {
      _showErrorSnackBar('Veuillez saisir votre ancien mot de passe');
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showErrorSnackBar('Veuillez saisir votre nouveau mot de passe');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('Le nouveau mot de passe doit contenir au moins 6 caractères');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    // Afficher un loader
    _showLoadingDialog();

    try {
      final result = await UserService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      // Fermer le loader
      Navigator.of(context).pop();

      if (result['success']) {
        // Succès
        setState(() {
          _isChangingPassword = false;
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });

        _showSuccessSnackBar(result['message']);
      } else {
        // Erreur
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      // Fermer le loader
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur inattendue: $e');
    }
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Déconnexion'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Afficher un loader pendant la déconnexion
      _showLoadingDialog();

      try {
        // Utiliser la méthode de déconnexion du service
        await UserService.logout();

        // Fermer le loader
        Navigator.of(context).pop();

        // Rediriger vers la page de connexion
        Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        // Fermer le loader
        Navigator.of(context).pop();

        _showErrorSnackBar('Erreur lors de la déconnexion: $e');
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E4F99)),
              ),
              SizedBox(width: 20),
              Text('Traitement en cours...'),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Fonctionnalité à venir'),
        backgroundColor: Color(0xFF2E4F99),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// Dashboard principal avec navbar moderne
class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  Map<String, dynamic>? user;
  String? userRole;
  Map<String, int> stats = {
    'utilisateurs': 0,
    'specialites': 0,
    'departements': 0,
    'salles': 0,
    'batiments': 0,
    'niveaux': 0,
    'annees': 0,
  };
  bool isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut)
    );

    _loadUserData();
    _loadStats();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // [Gardez toutes vos méthodes existantes _loadStats, _loadStatsIndividually, _loadUserData...]
  Future<void> _loadStats() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('user_token');

      if (token == null) {
        await _loadStatsIndividually();
        return;
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      try {
        final response = await http.get(
          Uri.parse('${UserService.baseUrl}/admin/stats'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            stats = {
              'utilisateurs': data['utilisateurs'] ?? data['users'] ?? 0,
              'specialites': data['specialites'] ?? data['specialites'] ?? 0,
              'departements': data['departements'] ?? data['departments'] ?? 0,
              'salles': data['salles'] ?? data['salles'] ?? 0,
              'batiments': data['batiments'] ?? data['batiments'] ?? 0,
              'niveaux': data['niveaux'] ?? data['niveaux'] ?? 0,
              'annees': data['annees'] ?? data['annees'] ?? 0,
              'formations': data['formations'] ?? data['types_formation'] ?? 0,
            };
            isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('❌ Endpoint global non disponible: $e');
      }

      await _loadStatsIndividually(token: token, headers: headers);

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      await _loadStatsIndividually();
    }
  }

  Future<void> _loadStatsIndividually({String? token, Map<String, String>? headers}) async {
    final Map<String, int> newStats = {};

    final endpoints = [
      {'key': 'utilisateurs', 'url': '/admin/users'},
      {'key': 'specialites', 'url': '/admin/specialites'},
      {'key': 'departements', 'url': '/admin/departements'},
      {'key': 'salles', 'url': '/admin/salles'},
      {'key': 'batiments', 'url': '/admin/batiments'},
      {'key': 'niveaux', 'url': '/admin/niveaux'},
      {'key': 'annees', 'url': '/admin/annees'},
      {'key': 'formations', 'url': '/admin/types-formation'},
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http.get(
          Uri.parse('${UserService.baseUrl}${endpoint['url']}'),
          headers: headers ?? {'Accept': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          int count = 0;

          if (data is List) {
            count = data.length;
          } else if (data is Map) {
            if (data.containsKey('success') && data.containsKey('data')) {
              final innerData = data['data'];
              if (innerData is Map && innerData.containsKey('total')) {
                count = innerData['total'] is int ? innerData['total'] : 0;
              } else if (innerData is List) {
                count = innerData.length;
              }
            } else if (data.containsKey('data') && data['data'] is List) {
              count = (data['data'] as List).length;
            }
          }

          newStats[endpoint['key']!] = count;
        } else {
          newStats[endpoint['key']!] = 0;
        }
      } catch (e) {
        newStats[endpoint['key']!] = 0;
      }
    }

    setState(() {
      stats = {
        'utilisateurs': newStats['utilisateurs'] ?? 0,
        'specialites': newStats['specialites'] ?? 0,
        'departements': newStats['departements'] ?? 0,
        'salles': newStats['salles'] ?? 0,
        'batiments': newStats['batiments'] ?? 0,
        'niveaux': newStats['niveaux'] ?? 0,
        'annees': newStats['annees'] ?? 0,
        'formations': newStats['formations'] ?? 0,
      };
      isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    final role = prefs.getString('user_role');

    if (userData != null) {
      setState(() {
        user = jsonDecode(userData);
        userRole = role;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Navbar moderne sans AppBar
          _buildModernNavbar(),

          // Contenu principal
          Expanded(
            child: isLoading
                ? Center(
              child: SpinKitWave(
                color: Color(0xFF2E4F99),
                size: 30.0,
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      SizedBox(height: 24),
                      _buildStatsSection(),
                      SizedBox(height: 24),
                      _buildManagementSection(),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNavbar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF1E293B),

          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Dashboard Admin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: IconButton(
                      icon: Stack(
                        children: [
                          Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(0xFFE53E3E),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () => _showComingSoon('Notifications'),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminProfilePage(user: user),
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                user?['prenom'] != null && user!['prenom'].isNotEmpty
                                    ? user!['prenom'][0].toUpperCase()
                                    : 'A',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            user?['prenom'] ?? 'Admin',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white.withOpacity(0.7),
                            size: 16,
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
      ),
    );
  }

// Section de bienvenue plus détaillée avec nom complet + informations contextuelles
  Widget _buildWelcomeSection() {
    // Construire le nom complet pour la section principale
    String fullName = 'Administrateur';
    String role = 'Administrateur ';

    if (user != null) {
      String prenom = user!['prenom'] ?? '';
      String nom = user!['nom'] ?? '';

      if (prenom.isNotEmpty && nom.isNotEmpty) {
        fullName = '$prenom $nom';
      } else if (prenom.isNotEmpty) {
        fullName = prenom;
      } else if (nom.isNotEmpty) {
        fullName = nom;
      }

      // Ajuster le rôle si disponible
      if (userRole != null && userRole!.isNotEmpty) {
        role = userRole!;
      }
    }

    // Obtenir l'heure pour un message contextuel
    int hour = DateTime.now().hour;
    String timeGreeting = '';
    IconData timeIcon = Icons.wb_sunny;

    if (hour < 12) {
      timeGreeting = 'Bonjour';
      timeIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      timeGreeting = 'Bon après-midi';
      timeIcon = Icons.wb_sunny_outlined;
    } else {
      timeGreeting = 'Bonsoir';
      timeIcon = Icons.brightness_2;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF1E3A7A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E293B).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: Icon(
                  timeIcon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$timeGreeting, $fullName',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Informations contextuelles
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.calendar_today,
                text: _getFormattedDate(),
              ),
              SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.access_time,
                text: _getFormattedTime(),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Widget helper pour les chips d'information
  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 14,
          ),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// Méthodes utilitaires pour les dates et heures
  String _getFormattedDate() { 
    final now = DateTime.now();
    final days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

    return '${days[now.weekday % 7]} ${now.day} ${months[now.month - 1]}';
  }

  String _getFormattedTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu Général',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Utilisateurs',
                value: stats['utilisateurs'].toString(),
                icon: Icons.people_rounded,
                color: Color(0xFF3B82F6),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Spécialités',
                value: stats['specialites'].toString(),
                icon: Icons.school_rounded,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Départements',
                value: stats['departements'].toString(),
                icon: Icons.business_rounded,
                color: Color(0xFF8B5CF6),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Salles',
                value: stats['salles'].toString(),
                icon: Icons.meeting_room_rounded,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestion du Système',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 16),
        _buildManagementGrid(),
      ],
    );
  }

  Widget _buildManagementGrid() {
    final managementItems = [
      {
        'title': 'Utilisateurs',
        'subtitle': 'Gérer les comptes',
        'icon': Icons.people_rounded,
        'color': Color(0xFF3B82F6),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UsersManagementScreen()),
        ),
      },
      {
        'title': 'Départements',
        'subtitle': 'Gérer les départements',
        'icon': Icons.business_rounded,
        'color': Color(0xFF8B5CF6),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DepartementManageScreen()),
        ),
      },
      {
        'title': 'Spécialités',
        'subtitle': 'Gérer les spécialités',
        'icon': Icons.school_rounded,
        'color': Color(0xFF10B981),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SpecialiteManageScreen()),
        ),
      },
      {
        'title': 'Années',
        'subtitle': 'Gérer les années',
        'icon': Icons.calendar_today_rounded,
        'color': Color(0xFFF59E0B),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AnneeManageScreen()),
        ),
      },
      {
        'title': 'Salles',
        'subtitle': 'Gérer les salles',
        'icon': Icons.meeting_room_rounded,
        'color': Color(0xFFEF4444),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SalleManageScreen()),
        ),
      },
      {
        'title': 'Niveaux',
        'subtitle': 'Gérer les niveaux',
        'icon': Icons.stairs_rounded,
        'color': Color(0xFF06B6D4),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NiveauManageScreen()),
        ),
      },
      {
        'title': 'Bâtiments',
        'subtitle': 'Gérer les bâtiments',
        'icon': Icons.apartment_rounded,
        'color': Color(0xFF36D6D8),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BatimentManageScreen()),
        ),
      },
      {
        'title': 'Type Formations',
        'subtitle': 'Gérer les types',
        'icon': Icons.category_rounded,
        'color': Color(0xFFFF6B6B),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TypeFormationManageScreen()),
        ),
      },
      {
        'title': 'Compétences',
        'subtitle': 'Gérer les compétences',
        'icon': Icons.psychology_rounded,
        'color': Color(0xFF4ECDC4),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CompetenceManageScreen()),
        ),
      },
      {
        'title': 'Semestres',
        'subtitle': 'Gérer les semestres',
        'icon': Icons.event_note_rounded,
        'color': Color(0xFFFFD93D),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SemestreManageScreen()),
        ),
      },
      {
        'title': 'Metiers',
        'subtitle': 'Gérer les metiers',
        'icon': Icons.stairs_rounded,
        'color': Color(0xFF06B6D4),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MetierManageScreen()),
        ),
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < managementItems.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildManagementCard(
                    title: managementItems[i]['title'] as String,
                    subtitle: managementItems[i]['subtitle'] as String,
                    icon: managementItems[i]['icon'] as IconData,
                    color: managementItems[i]['color'] as Color,
                    onTap: managementItems[i]['route'] as VoidCallback,
                  ),
                ),
                SizedBox(width: 12),
                if (i + 1 < managementItems.length)
                  Expanded(
                    child: _buildManagementCard(
                      title: managementItems[i + 1]['title'] as String,
                      subtitle: managementItems[i + 1]['subtitle'] as String,
                      icon: managementItems[i + 1]['icon'] as IconData,
                      color: managementItems[i + 1]['color'] as Color,
                      onTap: managementItems[i + 1]['route'] as VoidCallback,
                    ),
                  )
                else
                  Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: color.withOpacity(0.6),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Fonctionnalité à venir'),
        backgroundColor: Color(0xFF2E4F99),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}