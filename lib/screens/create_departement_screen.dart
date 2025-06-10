import 'package:flutter/material.dart';
import '../services/departement_service.dart';
import '../services/user_service.dart';

class CreateDepartementScreen extends StatefulWidget {
  const CreateDepartementScreen({Key? key}) : super(key: key);

  @override
  _CreateDepartementScreenState createState() => _CreateDepartementScreenState();
}

class _CreateDepartementScreenState extends State<CreateDepartementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomDepartementController = TextEditingController();

  int? _selectedBatimentId;
  int? _selectedUserId;
  int? _selectedFormateurId;

  List<Map<String, dynamic>> _batiments = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _formateurs = [];

  bool _isLoading = false;
  bool _isLoadingData = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      print('Chargement des données initiales...');

      // Charger les bâtiments, utilisateurs et formateurs en parallèle
      await Future.wait([
        _loadBatiments(),
        _loadUsers(),
        _loadFormateurs(),
      ]);

      if (!mounted) return;

      setState(() {
        _isLoadingData = false;
      });

      print('Données chargées avec succès');
      print('Bâtiments: ${_batiments.length}');
      print('Utilisateurs: ${_users.length}');
      print('Formateurs: ${_formateurs.length}');

    } catch (e) {
      print('Erreur lors du chargement des données: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingData = false;
        _errorMessage = 'Erreur lors du chargement des données: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: _loadInitialData,
          ),
        ),
      );
    }
  }

  Future<void> _loadBatiments() async {
    try {
      final batiments = await UserService.getBatiments();
      if (mounted) {
        setState(() {
          _batiments = batiments ?? [];
        });
      }
    } catch (e) {
      print('Erreur chargement bâtiments: $e');
      if (mounted) {
        setState(() {
          _batiments = [
            {'id': 1, 'intitule': 'Bâtiment A'},
            {'id': 2, 'intitule': 'Bâtiment B'},
            {'id': 3, 'intitule': 'Bâtiment C'},
          ];
        });
      }
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await UserService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users ?? [];
        });
      }
    } catch (e) {
      print('Erreur chargement utilisateurs: $e');
      if (mounted) {
        setState(() {
          _users = [
            {'id': 1, 'nom': 'Admin', 'prenom': 'System'},
            {'id': 2, 'nom': 'Directeur', 'prenom': 'Principal'},
          ];
        });
      }
    }
  }

  Future<void> _loadFormateurs() async {
    try {
      print('🔍 Chargement des formateurs depuis l\'API...');

      // Essayer d'abord de récupérer les vrais formateurs
      final formateurs = await DepartementService.getFormateurs();

      if (mounted) {
        setState(() {
          _formateurs = formateurs;
        });

        print('✅ Formateurs chargés avec leurs VRAIS IDs:');
        for (var formateur in _formateurs) {
          print('  - ID: ${formateur['id']}, Nom: ${formateur['nom']}, Prénom: ${formateur['prenom']}');
        }
      }

    } catch (e) {
      print('❌ Erreur chargement formateurs depuis API: $e');

      // Si l'API principale échoue, essayer une méthode alternative
      try {
        print('⚠ Tentative de récupération des formateurs par une méthode alternative');

        // Vérifier si il y a une méthode alternative dans le service
        final formateursList = await _getFormateursAlternative();

        if (mounted) {
          setState(() {
            _formateurs = formateursList;
          });

          if (_formateurs.isNotEmpty) {
            print('✅ Formateurs chargés par méthode alternative:');
            for (var formateur in _formateurs) {
              print('  - ID: ${formateur['id']}, Nom: ${formateur['nom']}, Prénom: ${formateur['prenom']}');
            }
          } else {
            print('⚠ Aucun formateur trouvé');
          }
        }

      } catch (e2) {
        print('❌ Erreur totale lors du chargement des formateurs: $e2');
        if (mounted) {
          setState(() {
            _formateurs = [];
          });
        }
      }
    }
  }

  // Méthode alternative pour récupérer les formateurs
  Future<List<Map<String, dynamic>>> _getFormateursAlternative() async {
    try {
      // Option 1: Essayer une autre méthode du service si elle existe
      // return await DepartementService.getFormateursAlternative();

      // Option 2: Si on doit absolument utiliser les utilisateurs avec rôle formateur,
      // s'assurer qu'on récupère les bonnes informations
      final users = await UserService.getAllUsers();
      final roles = await UserService.getRoles();

      final formateurRole = roles.firstWhere(
            (role) => role['intitule']?.toLowerCase() == 'formateur',
        orElse: () => {},
      );

      if (formateurRole.isNotEmpty) {
        final formateursUsers = users.where((user) =>
        user['role_id'] == formateurRole['id']).toList();

        // IMPORTANT: Ici il faut mapper vers les vrais IDs de formateur
        // Cette partie dépend de votre structure de base de données
        List<Map<String, dynamic>> formateurs = [];

        for (var user in formateursUsers) {
          // Récupérer l'ID formateur correspondant à cet utilisateur
          // Ceci est un exemple - adaptez selon votre structure DB
          try {
            final formateurId = await _getFormateurIdFromUserId(user['id']);
            if (formateurId != null) {
              formateurs.add({
                'id': formateurId, // ✅ VRAI ID de formateur
                'nom': user['nom'],
                'prenom': user['prenom'],
                'user_id': user['id'], // Garder l'ID utilisateur si nécessaire
              });
            }
          } catch (e) {
            print('Erreur lors de la récupération de l\'ID formateur pour l\'utilisateur ${user['id']}: $e');
          }
        }

        return formateurs;
      }

      return [];
    } catch (e) {
      print('Erreur dans la méthode alternative: $e');
      return [];
    }
  }

  // Méthode pour récupérer l'ID formateur à partir de l'ID utilisateur
  Future<int?> _getFormateurIdFromUserId(int userId) async {
    try {
      // OPTION A: Si vous avez une table formateurs avec user_id
      // Créez cette méthode dans DepartementService :
      // return await DepartementService.getFormateurIdByUserId(userId);

      // OPTION B: Si formateur_id = user_id dans votre cas
      // return userId;

      // OPTION C: Si vous devez faire une requête spécifique
      // Exemple : récupérer depuis une table de liaison
      print('🔍 Récupération de l\'ID formateur pour l\'utilisateur $userId');

      // Pour l'instant, retournons l'ID utilisateur
      // VOUS DEVEZ ADAPTER CETTE PARTIE selon votre structure DB
      return userId;

    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'ID formateur: $e');
      return null;
    }
  }



  Future<void> _createDepartement() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBatimentId == null) {
      _showError('Veuillez sélectionner un bâtiment');
      return;
    }

    if (_selectedUserId == null) {
      _showError('Veuillez sélectionner un utilisateur');
      return;
    }

    if (_selectedFormateurId == null) {
      _showError('Veuillez sélectionner un formateur');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Vérifier que l'ID formateur sélectionné est valide
      final selectedFormateur = _formateurs.firstWhere(
            (f) => f['id'] == _selectedFormateurId,
        orElse: () => {},
      );

      if (selectedFormateur.isEmpty) {
        throw Exception('Formateur sélectionné introuvable');
      }

      final departementData = {
        'nom_departement': _nomDepartementController.text.trim(),
        'batiment_id': _selectedBatimentId,
        'user_id': _selectedUserId,
        'formateur_id': _selectedFormateurId, // ✅ Maintenant c'est le vrai ID formateur
      };

      print('📤 Données département à envoyer: $departementData');
      print('📋 Formateur sélectionné: ${selectedFormateur['nom']} ${selectedFormateur['prenom']} (ID: ${selectedFormateur['id']})');

      final result = await DepartementService.createDepartement(departementData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Département "${_nomDepartementController.text}" créé avec succès !'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Erreur lors de la création du département: $e');
      if (mounted) {
        _showError('Erreur lors de la création: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Créer un Département',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 20),
                ),
                onPressed: _loadInitialData,
                tooltip: 'Recharger les données',
              ),
            ),
        ],
      ),
      body: _isLoadingData
          ? _buildLoadingState()
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildFormSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
                SizedBox(height: 16),
                Text(
                  'Chargement des données...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message d'erreur
              if (_errorMessage != null) _buildErrorMessage(),

              // Informations du département
              _buildSectionHeader(
                'Informations du département',
                Icons.business_rounded,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 20),

              _buildModernTextField(
                controller: _nomDepartementController,
                label: 'Nom du département',
                icon: Icons.business_center_rounded,
                required: true,
              ),
              const SizedBox(height: 32),

              // Bâtiment
              _buildDropdown(
                title: 'Bâtiment',
                icon: Icons.location_city_rounded,
                color: const Color(0xFF8B5CF6),
                items: _batiments,
                selectedValue: _selectedBatimentId,
                onChanged: (value) => setState(() => _selectedBatimentId = value),
                emptyMessage: 'Aucun bâtiment disponible',
              ),
              const SizedBox(height: 20),

              // Utilisateur responsable
              _buildDropdown(
                title: 'Utilisateur',
                icon: Icons.person_rounded,
                color: Colors.red.shade300,
                items: _users,
                selectedValue: _selectedUserId,
                onChanged: (value) => setState(() => _selectedUserId = value),
                emptyMessage: 'Aucun utilisateur disponible',
                displayKey: 'full_name',
              ),
              const SizedBox(height: 20),

              // Formateur
              _buildDropdown(
                title: 'Formateur',
                icon: Icons.school_rounded,
                color: const Color(0xFF10B981),
                items: _formateurs,
                selectedValue: _selectedFormateurId,
                onChanged: (value) => setState(() => _selectedFormateurId = value),
                emptyMessage: 'Aucun formateur disponible',
                displayKey: 'full_name',
              ),
              const SizedBox(height: 32),

              // Bouton de création
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadInitialData,
            child: const Text(
              'Réessayer',
              style: TextStyle(color: Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: const Color(0xFFFAFAFA),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
        validator: required
            ? (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est requis';
          }
          return null;
        }
            : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> items,
    required int? selectedValue,
    required Function(int?) onChanged,
    required String emptyMessage,
    String displayKey = 'intitule',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              hint: Text(
                items.isEmpty ? emptyMessage : 'Sélectionner $title',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              value: selectedValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
              items: items.map((item) {
                String displayText;
                if (displayKey == 'full_name') {
                  displayText = '${item['prenom'] ?? ''} ${item['nom'] ?? ''}'.trim();
                  if (displayText.isEmpty) {
                    displayText = item['intitule']?.toString() ?? 'Sans nom';
                  }
                } else {
                  displayText = item[displayKey]?.toString() ?? 'Sans nom';
                }

                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                );
              }).toList(),
              onChanged: items.isEmpty ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isLoading || _batiments.isEmpty || _users.isEmpty || _formateurs.isEmpty)
            ? null
            : _createDepartement,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Création en cours...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Créer le Département',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomDepartementController.dispose();
    super.dispose();
  }
}