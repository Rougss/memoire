import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/departement_service.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateDepartementScreen extends StatefulWidget {
  const CreateDepartementScreen({Key? key}) : super(key: key);

  @override
  _CreateDepartementScreenState createState() => _CreateDepartementScreenState();
}

class _CreateDepartementScreenState extends State<CreateDepartementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomDepartementController = TextEditingController();

  int? _selectedBatimentId;
  int? _selectedFormateurId;

  List<Map<String, dynamic>> _batiments = [];
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
      print('🔄 Chargement des données initiales...');

      await Future.wait([
        _loadBatiments(),
        _loadFormateurs(),
      ]);

      if (!mounted) return;

      setState(() {
        _isLoadingData = false;
      });

      print('✅ Données chargées:');
      print('  - Bâtiments: ${_batiments.length}');
      print('  - Formateurs: ${_formateurs.length}');

    } catch (e) {
      print('❌ Erreur lors du chargement: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingData = false;
        _errorMessage = 'Erreur lors du chargement des données: $e';
      });

      _showError('Erreur lors du chargement: $e');
    }
  }

  Future<void> _loadBatiments() async {
    try {
      final batiments = await UserService.getBatiments();
      if (mounted) {
        setState(() {
          _batiments = batiments ?? [];
        });
        print('✅ ${_batiments.length} bâtiments chargés');
      }
    } catch (e) {
      print('❌ Erreur chargement bâtiments: $e');
      // Fallback avec des données d'exemple
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

  // 🔥 MÉTHODE SIMPLIFIÉE : Utilise seulement l'API des formateurs
  Future<void> _loadFormateurs() async {
    try {
      print('🔍 Chargement des formateurs depuis l\'API...');

      // 🎯 MÉTHODE 1: Utiliser le service DepartementService
      final formateurs = await DepartementService.getFormateurs();

      if (formateurs.isNotEmpty && mounted) {
        setState(() {
          _formateurs = formateurs;
        });

        print('✅ ${_formateurs.length} formateurs chargés depuis DepartementService:');
        for (var formateur in _formateurs.take(3)) {
          print('  - ${formateur['full_name']} (ID: ${formateur['id']})');
        }
        return;
      }

    } catch (e) {
      print('⚠ Échec DepartementService.getFormateurs(): $e');
    }

    // 🎯 MÉTHODE 2: Essayer les endpoints directs
    try {
      final formateurs = await _getFormateursDirectAPI();

      if (formateurs.isNotEmpty && mounted) {
        setState(() {
          _formateurs = formateurs;
        });

        print('✅ ${_formateurs.length} formateurs chargés depuis API directe:');
        for (var formateur in _formateurs.take(3)) {
          print('  - ${formateur['full_name']} (ID: ${formateur['id']})');
        }
        return;
      }

    } catch (e) {
      print('⚠ Échec API directe: $e');
    }

    // 🎯 MÉTHODE 3: Fallback - Utiliser les utilisateurs avec rôle formateur
    try {
      final formateurs = await _getFormateursFromUsers();

      if (mounted) {
        setState(() {
          _formateurs = formateurs;
        });

        print('⚠ ${_formateurs.length} formateurs depuis fallback utilisateurs');
      }

    } catch (e) {
      print('❌ Échec total chargement formateurs: $e');
      if (mounted) {
        setState(() {
          _formateurs = [];
        });
      }
    }
  }

  // Helper pour récupérer les headers d'authentification
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 🔥 MÉTHODE DIRECTE: Récupérer formateurs depuis API
  Future<List<Map<String, dynamic>>> _getFormateursDirectAPI() async {
    final headers = await _getHeaders();

    // Tester différents endpoints
    List<String> endpoints = [
      '${DepartementService.baseUrl}/admin/formateurs',
      '${DepartementService.baseUrl}/formateurs',
    ];

    for (String endpoint in endpoints) {
      try {
        print('🔄 Test endpoint: $endpoint');

        final response = await http.get(
          Uri.parse(endpoint),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          List<Map<String, dynamic>> formateurs;
          if (data is List) {
            formateurs = List<Map<String, dynamic>>.from(data);
          } else if (data is Map && data.containsKey('data')) {
            formateurs = List<Map<String, dynamic>>.from(data['data']);
          } else {
            continue;
          }

          // Traiter les formateurs
          List<Map<String, dynamic>> formateursTraites = [];
          for (var formateur in formateurs) {
            Map<String, dynamic> formateurTraite = {
              'id': formateur['id'], // ✅ ID formateur réel
              'user_id': formateur['user_id'],
              'specialite_id': formateur['specialite_id'],
            };

            // Récupérer nom/prénom
            if (formateur['user'] != null) {
              formateurTraite['nom'] = formateur['user']['nom'] ?? '';
              formateurTraite['prenom'] = formateur['user']['prenom'] ?? '';
              formateurTraite['email'] = formateur['user']['email'] ?? '';
            } else {
              formateurTraite['nom'] = formateur['nom'] ?? '';
              formateurTraite['prenom'] = formateur['prenom'] ?? '';
            }

            formateurTraite['full_name'] = '${formateurTraite['prenom']} ${formateurTraite['nom']}'.trim();

            if (formateurTraite['full_name'].isNotEmpty) {
              formateursTraites.add(formateurTraite);
            }
          }

          if (formateursTraites.isNotEmpty) {
            print('✅ ${formateursTraites.length} formateurs trouvés avec $endpoint');
            return formateursTraites;
          }
        }
      } catch (e) {
        print('❌ Échec $endpoint: $e');
        continue;
      }
    }

    return [];
  }

  // 🎯 FALLBACK: Récupérer formateurs depuis les utilisateurs (SANS mapping manuel)
  Future<List<Map<String, dynamic>>> _getFormateursFromUsers() async {
    try {
      final users = await UserService.getAllUsers();
      final roles = await UserService.getRoles();

      final formateurRole = roles.firstWhere(
            (role) => role['intitule']?.toLowerCase() == 'formateur',
        orElse: () => {},
      );

      if (formateurRole.isNotEmpty) {
        final formateursUsers = users.where((user) =>
        user['role_id'] == formateurRole['id']).toList();

        List<Map<String, dynamic>> formateurs = [];

        for (var user in formateursUsers) {
          // ⚠️ ATTENTION: Ici on utilise l'ID utilisateur comme ID formateur
          // Ce n'est pas idéal mais c'est le fallback
          formateurs.add({
            'id': user['id'], // ⚠️ ID utilisateur (pas idéal)
            'user_id': user['id'],
            'nom': user['nom'],
            'prenom': user['prenom'],
            'full_name': '${user['prenom']} ${user['nom']}'.trim(),
            'email': user['email'],
            'telephone': user['telephone'],
            'is_fallback': true, // Flag pour indiquer que c'est un fallback
          });
        }

        print('⚠️ Fallback: ${formateurs.length} formateurs depuis utilisateurs');
        print('⚠️ ATTENTION: Les IDs peuvent ne pas correspondre aux vrais IDs formateurs');

        return formateurs;
      }

      return [];
    } catch (e) {
      print('❌ Erreur fallback formateurs: $e');
      return [];
    }
  }

  Future<void> _createDepartement() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBatimentId == null) {
      _showError('Veuillez sélectionner un bâtiment');
      return;
    }

    if (_selectedFormateurId == null) {
      _showError('Veuillez sélectionner un formateur chef de département');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Vérifier le formateur sélectionné
      final selectedFormateur = _formateurs.firstWhere(
            (f) => f['id'] == _selectedFormateurId,
        orElse: () => {},
      );

      if (selectedFormateur.isEmpty) {
        throw Exception('Formateur sélectionné introuvable');
      }

      // ⚠️ Vérifier si c'est un fallback
      if (selectedFormateur['is_fallback'] == true) {
        print('⚠️ ATTENTION: Utilisation d\'un formateur fallback');
        print('⚠️ L\'ID ${_selectedFormateurId} pourrait ne pas être le vrai ID formateur');
      }

      final departementData = {
        'nom_departement': _nomDepartementController.text.trim(),
        'batiment_id': _selectedBatimentId,
        'formateur_id': _selectedFormateurId,
      };

      print('📤 Données département à envoyer: $departementData');
      print('📋 Formateur chef sélectionné: ${selectedFormateur['full_name']}');

      final result = await DepartementService.createDepartement(departementData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Département "${_nomDepartementController.text}" créé avec succès !\nChef: ${selectedFormateur['full_name']}'),
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

              // Formateur chef de département
              _buildDropdown(
                title: 'Formateur Chef de Département',
                icon: Icons.account_balance_rounded,
                color: const Color(0xFF10B981),
                items: _formateurs,
                selectedValue: _selectedFormateurId,
                onChanged: (value) => setState(() => _selectedFormateurId = value),
                emptyMessage: 'Aucun formateur disponible',
                displayKey: 'full_name',
              ),
              const SizedBox(height: 32),

              // Note explicative
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Le formateur sélectionné deviendra automatiquement le chef de ce département.',
                        style: TextStyle(
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
        onPressed: (_isLoading || _batiments.isEmpty || _formateurs.isEmpty)
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