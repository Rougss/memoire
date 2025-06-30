import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CreateFormateurScreen extends StatefulWidget {
  const CreateFormateurScreen({Key? key}) : super(key: key);

  @override
  _CreateFormateurScreenState createState() => _CreateFormateurScreenState();
}

class _CreateFormateurScreenState extends State<CreateFormateurScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();

  DateTime? _dateNaissance;
  String _genre = 'M';
  File? _selectedImage;
  int? _selectedSpecialiteId;
  List<Map<String, dynamic>> _specialites = [];
  bool _isLoading = false;
  bool _isLoadingSpecialites = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSpecialites();
  }

  Future<void> _loadSpecialites() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSpecialites = true;
      _errorMessage = null;
    });

    try {
      print('Tentative de récupération des spécialités...');
      final specialites = await UserService.getSpecialites();

      if (!mounted) return;

      print('Spécialités récupérées: $specialites');

      setState(() {
        _specialites = specialites ?? [];
        _isLoadingSpecialites = false;
      });

      if (_specialites.isEmpty) {
        print('Aucune spécialité trouvée');
        setState(() {
          _errorMessage = 'Aucune spécialité disponible';
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des spécialités: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingSpecialites = false;
        _errorMessage = 'Erreur: ${e.toString()}';
        _specialites = [
          {'id': 1, 'intitule': 'Informatique'},
          {'id': 2, 'intitule': 'Mathématiques'},
          {'id': 3, 'intitule': 'Français'},
          {'id': 4, 'intitule': 'Anglais'},
          {'id': 5, 'intitule': 'Sciences'},
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur de connexion. Spécialités par défaut chargées.'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: _loadSpecialites,
          ),
        ),
      );
    }
  }



  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateNaissance) {
      setState(() {
        _dateNaissance = picked;
      });
    }
  }

  Future<void> _createFormateur() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecialiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner une spécialité'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Récupération des rôles...');
      final roles = await UserService.getRoles();
      final formateurRole = roles.firstWhere(
            (role) => role['intitule'] == 'Formateur',
        orElse: () => throw Exception('Rôle Formateur non trouvé'),
      );

      final userData = {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'email': _emailController.text,
        'telephone': _telephoneController.text,
        'date_naissance': _dateNaissance?.toIso8601String().split('T')[0],
        'genre': _genre,
        'lieu_naissance': _lieuNaissanceController.text,
        'role_id': formateurRole['id'],
        'specialite_id': _selectedSpecialiteId,
      };

      print('Données utilisateur à envoyer: $userData');
      final result = await UserService.createUser(userData);

      if (mounted) {
        // ✅ NOUVEAU: Dialog avec informations complètes
        await _showSuccessDialog(result);
      }
    } catch (e) {
      print('Erreur lors de la création du formateur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

// ✅ NOUVELLE MÉTHODE: Afficher le dialog de succès
  Future<void> _showSuccessDialog(Map<String, dynamic> result) async {
    final user = result['data']['user'];
    final password = result['data']['password'];
    final matricule = result['data']['matricule'];
    final role = result['data']['role'];

    await showDialog(
      context: context,
      barrierDismissible: false, // L'utilisateur DOIT cliquer OK
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Formateur créé !',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de l'utilisateur
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user['prenom']} ${user['nom']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.email_rounded, 'Email', user['email']),
                      _buildInfoRow(Icons.badge_rounded, 'Matricule', matricule),
                      _buildInfoRow(Icons.work_rounded, 'Rôle', role),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Identifiants de connexion
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.1),
                        const Color(0xFF1D4ED8).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.vpn_key_rounded,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Identifiants de connexion',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Login
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Login: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                user['email'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                             Text(
                              'Mot de passe: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                password,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                  fontSize: 16,
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Transmettez ces identifiants au formateur pour qu\'il puisse se connecter.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [

            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Ferme le dialog
                  Navigator.of(context).pop(); // Retourne à l'écran précédent
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Terminé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// ✅ MÉTHODE HELPER: Construire une ligne d'info
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Créer un Formateur',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3B82F6),
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
                onPressed: _loadSpecialites,
                tooltip: 'Recharger les spécialités',
              ),
            ),
        ],
      ),
      body: _isLoadingSpecialites
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
                SpinKitThreeInOut(
                  color: Color(0xFF3B82F6),
                  size: 35.0,
                ),
                SizedBox(height: 16),
                Text(
                  'Chargement des spécialités...',
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

              // Informations personnelles
              _buildSectionHeader(
                'Informations personnelles',
                Icons.person_rounded,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _prenomController,
                      label: 'Prénom',
                      icon: Icons.person_outline_rounded,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _nomController,
                      label: 'Nom',
                      icon: Icons.person_rounded,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildModernTextField(
                controller: _emailController,
                label: 'Adresse email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                required: true,
              ),
              const SizedBox(height: 20),

              _buildModernTextField(
                controller: _telephoneController,
                label: 'Numéro de téléphone',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Genre
              _buildGenderSelection(),
              const SizedBox(height: 20),

              // Date de naissance
              _buildDatePicker(),
              const SizedBox(height: 20),

              _buildModernTextField(
                controller: _lieuNaissanceController,
                label: 'Lieu de naissance',
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 32),

              // Informations professionnelles
              _buildSectionHeader(
                'Informations professionnelles',
                Icons.work_rounded,
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 20),

              // Spécialité
              _buildSpecialiteDropdown(),
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
            onPressed: _loadSpecialites,
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

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people_rounded, color: Color(0xFF8B5CF6), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Genre',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _genre = 'M'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _genre == 'M' ? const Color(0xFF3B82F6).withOpacity(0.1) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _genre == 'M' ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
                      width: _genre == 'M' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.male_rounded,
                        color: _genre == 'M' ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Masculin',
                        style: TextStyle(
                          color: _genre == 'M' ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _genre = 'F'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _genre == 'F' ? const Color(0xFFEC4899).withOpacity(0.1) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _genre == 'F' ? const Color(0xFFEC4899) : const Color(0xFFE5E7EB),
                      width: _genre == 'F' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.female_rounded,
                        color: _genre == 'F' ? const Color(0xFFEC4899) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Féminin',
                        style: TextStyle(
                          color: _genre == 'F' ? const Color(0xFFEC4899) : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF3B82F6), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              _dateNaissance != null
                  ? '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}'
                  : 'Date de naissance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _dateNaissance != null ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialiteDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFFAFBFC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedSpecialiteId != null
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE2E8F0),
            width: 1.7,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            hint: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.1),
                        const Color(0xFF1D4ED8).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _specialites.isEmpty
                        ? 'Aucune spécialité disponible'
                        : 'Sélectionner une spécialité',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            value: _selectedSpecialiteId,
            isExpanded: true,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
            dropdownColor: Colors.white,
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            items: _specialites.map((specialite) {
              return DropdownMenuItem<int>(
                value: specialite['id'],
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3B82F6).withOpacity(0.1),
                              const Color(0xFF1D4ED8).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Color(0xFF3B82F6),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          specialite['intitule']?.toString() ?? 'Sans nom',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      if (_selectedSpecialiteId == specialite['id'])
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: _specialites.isEmpty
                ? null
                : (value) {
              setState(() => _selectedSpecialiteId = value);
            },
          ),
        ),
      ),
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
        onPressed: (_isLoading || _specialites.isEmpty) ? null : _createFormateur,
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
              'Créer le Formateur',
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
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _lieuNaissanceController.dispose();
    super.dispose();
  }
}