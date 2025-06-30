import 'package:flutter/material.dart';
import 'package:memoire/screens/role_selection_screen.dart';
import '../services/user_service.dart';
import '../services/connectivity_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'no_connection_screen.dart';
import '../screens/edit_user_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({Key? key}) : super(key: key);

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  String searchQuery = '';
  String selectedRole = 'Tous';

  final List<String> roles = [
    'Tous',
    'Administrateur',
    'Directeur des Etudes',
    'Formateur',
    'Elève',
    'Surveillant'
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      // Utiliser le service de connectivité pour gérer les erreurs
      final data = await ConnectivityService.executeWithConnectivity(
            () => UserService.getAllUsers(),
        errorMessage: 'Impossible de charger les utilisateurs',
      );

      setState(() {
        users = data;
        isLoading = false;
        hasError = false;
      });

      print('✅ TOTAL utilisateurs chargés: ${users.length}');

      // Debug pour voir exactement ce qui est retourné
      for (int i = 0; i < users.length && i < 3; i++) {
        final user = users[i];
        print('👤 User $i: ${user['prenom']} ${user['nom']} - Rôle: ${user['role_name']}');
      }

    } on NoInternetException catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
      print('❌ Erreur de connexion: $e');
    } on ApiException catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
      print('❌ Erreur API: $e');
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Erreur inattendue: $e';
      });
      print('❌ Erreur générale: $e');
    }
  }

  Future<void> _showUserDetails(Map<String, dynamic> user) async {
    // Afficher un loading pendant la récupération des détails
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await UserService.getUserById(user['id']);

      if (mounted) {
        Navigator.pop(context); // Fermer le loading

        if (result['success'] == true) {
          final userData = result['data'];
          _showUserDetailsDialog(userData);
        } else {
          _showErrorSnackBar(result['message'] ?? 'Erreur lors du chargement');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le loading
        _showErrorSnackBar('Erreur de connexion');
      }
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserScreen(user: user),
      ),
    );

    if (result == true) {
      _loadUsers(); // Recharger la liste
    }
  }

  List<Map<String, dynamic>> get filteredUsers {
    return users.where((user) {
      String userRole = user['role_name']?.toString().trim() ?? 'Non défini';

      // Filtrage par recherche (nom/prénom)
      final matchesSearch = searchQuery.isEmpty ||
          _matchesSearchQuery(user, searchQuery);

      // Filtrage par rôle
      final matchesRole = selectedRole == 'Tous' || userRole == selectedRole;

      return matchesSearch && matchesRole;
    }).toList();
  }

  bool _matchesSearchQuery(Map<String, dynamic> user, String query) {
    final queryLower = query.toLowerCase();
    final nom = (user['prenom']?.toString() ?? '').toLowerCase();
    final prenom = (user['nom']?.toString() ?? '').toLowerCase();

    return nom.contains(queryLower) || prenom.contains(queryLower);
  }

  Color _getRoleColor(String role) {
    switch (role.trim()) {
      case 'Administrateur':
        return const Color(0xFFE91E63);
      case 'Directeur des Etudes':
        return const Color(0xFF9C27B0);
      case 'Formateur':
        return const Color(0xFF2196F3);
      case 'Elève':
        return const Color(0xFF4CAF50);
      case 'Surveillant':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.trim()) {
      case 'Administrateur':
        return Icons.admin_panel_settings_rounded;
      case 'Directeur des Etudes':
        return Icons.business_center_rounded;
      case 'Formateur':
        return Icons.school_rounded;
      case 'Elève':
        return Icons.person_rounded;
      case 'Surveillant':
        return Icons.security_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si erreur de connexion, afficher l'écran d'erreur élégant
    if (hasError && errorMessage.contains('connexion')) {
      return NoConnectionScreen(
        onRetry: _loadUsers,
        customMessage: 'Impossible de charger les utilisateurs.\nVérifiez votre connexion Internet.',
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des utilisateurs',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Vérifier la connexion avant de naviguer
          if (!await ConnectivityService.checkConnectivity()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text('Connexion Internet requise'),
                  ],
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RoleSelectionScreen(),
            ),
          );
          if (result == true) {
            _loadUsers();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvel utilisateur'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Header avec recherche et filtres
          _buildSearchAndFilters(),

          // Liste des utilisateurs
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitThreeInOut(
              color: Color(0xFF3B82F6),
              size: 30.0,
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des utilisateurs...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return _buildErrorState();
    }

    if (filteredUsers.isEmpty) {
      return _buildEmptyState();
    }

    return _buildUsersList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher par nom ou prénom...',
                hintStyle: TextStyle(color: Color(0xFF64748B)),
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Filtres par rôle
          const Text(
            'Filtrer par rôle',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roles.map((role) {
              final isSelected = selectedRole == role;
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedRole = role;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return Column(
      children: [
        // Compteur
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${filteredUsers.length} utilisateur(s) trouvé(s) sur ${users.length} au total',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Liste
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            color: const Color(0xFF3B82F6),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                return _buildCleanUserCard(filteredUsers[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanUserCard(Map<String, dynamic> user) {
    final String nom = user['prenom']?.toString() ?? 'N/A';
    final String prenom = user['nom']?.toString() ?? 'N/A';
    final String role = user['role_name']?.toString().trim() ?? 'Non défini';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar avec initiales
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getRoleColor(role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${nom.isNotEmpty ? nom[0].toUpperCase() : ''}${prenom.isNotEmpty ? prenom[0].toUpperCase() : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getRoleColor(role),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Informations utilisateur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom complet
                  Text(
                    '$prenom $nom',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Badge du rôle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getRoleColor(role).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRoleIcon(role),
                          size: 14,
                          color: _getRoleColor(role),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          role,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getRoleColor(role),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: const Color(0x1A000000),
              color: Colors.white,
              surfaceTintColor: Colors.white,
              padding: EdgeInsets.zero,
              splashRadius: 20,
              tooltip: 'Options',
              offset: const Offset(0, 8),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                            Icons.visibility_rounded,
                            size: 16,
                            color: Color(0xFF64748B)
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Voir les détails',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'edit',
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Color(0xFF3B82F6)
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Modifier',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'delete',
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                            Icons.delete_rounded,
                            size: 16,
                            color: Color(0xFFEF4444)
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Supprimer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleUserAction(value, user),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 60,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Essayez de modifier votre recherche'
                : 'Commencez par ajouter des utilisateurs',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  selectedRole = 'Tous';
                });
              },
              child: const Text('Effacer les filtres'),
            ),
          ],
        ],
      ),
    );
  }

  void _handleUserAction(String action, Map<String, dynamic> user) async {
    // Vérifier la connexion avant toute action
    if (!await ConnectivityService.checkConnectivity()) {
      _showConnectionError();
      return;
    }

    switch (action) {
      case 'view':
        await _showUserDetails(user);
        break;
      case 'edit':
        await _editUser(user);
        break;
      case 'delete':
        _confirmDeleteUser(user);
        break;
    }
  }

  void _showConnectionError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text('Connexion Internet requise'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRoleColor(user['role_name'] ?? '').withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getRoleIcon(user['role_name'] ?? ''),
                color: _getRoleColor(user['role_name'] ?? ''),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${user['prenom']} ${user['nom']}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             // _buildDetailRow('ID', user['id']?.toString() ?? 'N/A'),
              _buildDetailRow('Nom', user['nom']?.toString() ?? 'N/A'),
              _buildDetailRow('Prénom', user['prenom']?.toString() ?? 'N/A'),
              _buildDetailRow('Email', user['email']?.toString() ?? 'N/A'),
              _buildDetailRow('Téléphone', user['telephone']?.toString() ?? 'N/A'),
              _buildDetailRow('Matricule', user['matricule']?.toString() ?? 'N/A'),
              _buildDetailRow('Genre', user['genre']?.toString() ?? 'N/A'),
              _buildDetailRow('Date de naissance', user['date_naissance']?.toString() ?? 'N/A'),
              _buildDetailRow('Lieu de naissance', user['lieu_naissance']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRoleColor(user['role_name'] ?? '').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getRoleColor(user['role_name'] ?? '').withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoleIcon(user['role_name'] ?? ''),
                      size: 16,
                      color: _getRoleColor(user['role_name'] ?? ''),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user['role_name']?.toString() ?? 'Non défini',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _getRoleColor(user['role_name'] ?? ''),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _editUser(user);
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Modifier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 24,
        child: Container(
          color: Colors.white,
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 500,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec icône d'avertissement
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Confirmer la suppression',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Message de confirmation
                  const Text(
                    'Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Carte utilisateur
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF8FAFC),
                          const Color(0xFFEFF6FF).withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getRoleColor(user['role_name'] ?? ''),
                                _getRoleColor(user['role_name'] ?? '').withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getRoleColor(user['role_name'] ?? '').withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _getUserInitials(user),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
                              Text(
                                '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF1F2937),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(user['role_name'] ?? '').withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      user['role_name'] ?? 'Non défini',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _getRoleColor(user['role_name'] ?? ''),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),


                  const SizedBox(height: 32),

                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteUser(user);
                          },
                          icon: const Icon(Icons.delete_rounded, size: 18),
                          label: const Text(
                            'Supprimer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                            shadowColor: const Color(0xFFEF4444).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getUserInitials(Map<String, dynamic> user) {
    String prenom = user['prenom']?.toString() ?? '';
    String nom = user['nom']?.toString() ?? '';

    String initials = '';
    if (prenom.isNotEmpty) initials += prenom[0].toUpperCase();
    if (nom.isNotEmpty) initials += nom[0].toUpperCase();

    return initials.isEmpty ? '?' : initials;
  }

  void _deleteUser(Map<String, dynamic> user) async {
    // Afficher le loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Suppression en cours...'),
            ],
          ),
          backgroundColor: const Color(0xFF64748B),
          duration: const Duration(seconds: 30),
        ),
      );
    }

    try {
      final result = await ConnectivityService.executeWithConnectivity(
            () => UserService.deleteUser(user['id']),
        errorMessage: 'Impossible de supprimer l\'utilisateur',
      );

      if (mounted) {
        // Cacher le snackbar de loading
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (result['success'] == true) {
          // Supprimer de la liste locale
          setState(() {
            users.removeWhere((u) => u['id'] == user['id']);
          });

          _showSuccessSnackBar(
              '${user['prenom']} ${user['nom']} supprimé avec succès'
          );
        } else {
          _showErrorSnackBar(result['message'] ?? 'Erreur lors de la suppression');
        }
      }
    } on NoInternetException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar(e.toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('Erreur inattendue lors de la suppression');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}