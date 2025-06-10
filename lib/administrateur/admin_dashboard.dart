import 'package:flutter/material.dart';
import 'package:memoire/screens/create_user_screen.dart';
import 'package:memoire/screens/role_selection_screen.dart';
import 'package:memoire/screens/user_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../screens/batiment_manage_screen.dart';
import '../screens/departement_manage_screen.dart';
import '../screens/salle_manage_screen.dart';
import '../screens/specialite_manage_screen.dart';
import '../screens/users_list_screen.dart';
import '../services/user_service.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? user;
  String? userRole;
  List<Map<String, dynamic>> specialites = [];
  List<Map<String, dynamic>> salles = [];
  Map<String, int> stats = {
    'utilisateurs': 0,
    'specialites': 0,
    'departements': 0,
   // 'salles': 0,
    'batiments': 0,
    'niveaux': 0,
    'annees': 0,
  };
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // Essayer différents noms de clés pour le token
      String? token = prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('user_token');

      print('🔍 Token trouvé: ${token != null ? "Oui" : "Non"}');

      if (token == null) {
        // Charger les statistiques individuellement sans token
        await _loadStatsIndividually();
        return;
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      // Essayer d'abord l'endpoint stats global
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
          print('✅ Statistiques chargées depuis l\'endpoint global');
          return;
        }
      } catch (e) {
        print('❌ Endpoint global non disponible: $e');
      }

      // Si l'endpoint global ne fonctionne pas, charger individuellement
      await _loadStatsIndividually(token: token, headers: headers);

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('❌ Erreur générale: $e');
      // Charger quand même les statistiques sans authentification
      await _loadStatsIndividually();
    }
  }

  Future<void> _loadStatsIndividually({String? token, Map<String, String>? headers}) async {
    print('🔄 Chargement des statistiques individuellement...');

    final Map<String, int> newStats = {};

    // Liste des endpoints à tester
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

    // Endpoints alternatifs sans auth
    final publicEndpoints = [
      {'key': 'specialites', 'url': '/common/specialites'},
      {'key': 'departements', 'url': '/common/departements'},
      {'key': 'niveaux', 'url': '/common/niveaux'},
      {'key': 'annees', 'url': '/common/annees'},
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http.get(
          Uri.parse('${UserService.baseUrl}${endpoint['url']}'),
          headers: headers ?? {'Accept': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            newStats[endpoint['key']!] = data.length;
          } else if (data is Map && data.containsKey('data')) {
            newStats[endpoint['key']!] = (data['data'] as List).length;
          } else {
            newStats[endpoint['key']!] = 0;
          }
          print('✅ ${endpoint['key']}: ${newStats[endpoint['key']!]}');
        } else {
          print('❌ ${endpoint['key']}: Status ${response.statusCode}');
          newStats[endpoint['key']!] = 0;
        }
      } catch (e) {
        print('❌ Erreur ${endpoint['key']}: $e');
        newStats[endpoint['key']!] = 0;
      }
    }

    // Essayer les endpoints publics pour certaines données
    for (final endpoint in publicEndpoints) {
      if (newStats[endpoint['key']!] == 0) {
        try {
          final response = await http.get(
            Uri.parse('${UserService.baseUrl}${endpoint['url']}'),
            headers: {'Accept': 'application/json'},
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is List) {
              newStats[endpoint['key']!] = data.length;
            } else if (data is Map && data.containsKey('data')) {
              newStats[endpoint['key']!] = (data['data'] as List).length;
            }
            print('✅ ${endpoint['key']} (public): ${newStats[endpoint['key']!]}');
          }
        } catch (e) {
          print('❌ Erreur public ${endpoint['key']}: $e');
        }
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

    print('📊 Statistiques finales: $stats');
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tableau de Bord Administrateur'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: _logout,
              tooltip: 'Se déconnecter',
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildStatsSection(),
              const SizedBox(height: 24),
              _buildManagementSection(),
              const SizedBox(height: 80), // Espace pour éviter l'overflow
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                ),
                child: Center(
                  child: Text(
                    user?['prenom'] != null && user!['prenom'].isNotEmpty
                        ? user!['prenom'][0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bienvenue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user?['prenom'] ?? ''} ${user?['nom'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              userRole ?? "Administrateur",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aperçu Général',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        // Première ligne de stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Utilisateurs',
                value: stats['utilisateurs'].toString(),
                icon: Icons.people_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Spécialités',
                value: stats['specialites'].toString(),
                icon: Icons.school_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Deuxième ligne de stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Départements',
                value: stats['departements'].toString(),
                icon: Icons.business_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Salles',
                value: stats['salles'].toString(),
                icon: Icons.meeting_room_rounded,
                color: const Color(0xFFEF4444),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                padding: const EdgeInsets.all(8),
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
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
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
        const Text(
          'Gestion du Système',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
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
        'color': const Color(0xFF3B82F6),
        'route': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UsersManagementScreen(),
          ),
        ),
      },
      {
        'title': 'Départements',
        'subtitle': 'Gérer les départements',
        'icon': Icons.business_rounded,
        'color': const Color(0xFF8B5CF6),
        'route': () => Navigator.push(
            context,
          MaterialPageRoute(builder: (context)=>DepartementManageScreen())
        ),
      },
      {
        'title': 'Spécialités',
        'subtitle': 'Gérer les spécialités',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF10B981),
        'route': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context)=>SpecialiteManageScreen())
        ),
      },
      {
        'title': 'Années',
        'subtitle': 'Gérer les années',
        'icon': Icons.calendar_today_rounded,
        'color': const Color(0xFFF59E0B),
        'route': () => _showComingSoon('Gestion des années'),
      },
      {
        'title': 'Salles',
        'subtitle': 'Gérer les salles',
        'icon': Icons.meeting_room_rounded,
        'color': const Color(0xFFEF4444),
        'route': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context)=>SalleManageScreen())
        ),
      },
      {
        'title': 'Niveaux',
        'subtitle': 'Gérer les niveaux',
        'icon': Icons.stairs_rounded,
        'color': const Color(0xFF06B6D4),
        'route': () => _showComingSoon('Gestion des niveaux'),
      },
      {
        'title': 'Batiments',
        'subtitle': 'Gérer les batiments',
        'icon': Icons.stairs_rounded,
        'color': const Color(0xFF36D6D8),
        'route': () =>  Navigator.push(
            context,
            MaterialPageRoute(builder: (context)=>BatimentManageScreen())
        ),
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < managementItems.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                const SizedBox(width: 12),
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
                  const Expanded(child: SizedBox()),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
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
                  padding: const EdgeInsets.all(10),
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
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
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
        backgroundColor: const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}