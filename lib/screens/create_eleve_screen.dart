import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CreateEleveScreen extends StatefulWidget {
  const CreateEleveScreen({Key? key}) : super(key: key);

  @override
  _CreateEleveScreenState createState() => _CreateEleveScreenState();
}

class _CreateEleveScreenState extends State<CreateEleveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _contactUrgenceController = TextEditingController();

  DateTime? _dateNaissance;
  String _genre = 'M';
  File? _selectedImage;
  int? _selectedMetierId;
  int? _selectedSalleId;
  List<Map<String, dynamic>> _metiers = [];
  bool _isLoading = false;
  bool _isLoadingData = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Début du chargement des données...');

      // Chargement des métiers avec gestion d'erreur améliorée
      print('📚 Chargement des métiers...');
      try {
        final metiers = await UserService.getMetiers();
        print('✅ ${metiers.length} métiers chargés');

        // Validation améliorée des métiers
        final metiersValides = metiers.where((metier) {
          bool isValid = metier != null &&
              metier['id'] != null &&
              metier['nom'] != null &&
              metier['nom'].toString().trim().isNotEmpty;
          if (!isValid) {
            print('⚠ Métier invalide détecté: $metier');
          }
          return isValid;
        }).toList();

        if (!mounted) return;

        setState(() => _metiers = metiersValides);
        print('✅ ${metiersValides.length} métiers valides chargés');

        if (_metiers.isEmpty) {
          setState(() {
            _errorMessage = 'Aucun métier disponible';
            // Métiers par défaut en cas d'erreur
            _metiers = [
              {'id': 1, 'intitule': 'Développement Web'},
              {'id': 2, 'intitule': 'Marketing Digital'},
              {'id': 3, 'intitule': 'Design Graphique'},
              {'id': 4, 'intitule': 'Comptabilité'},
              {'id': 5, 'intitule': 'Ressources Humaines'},
            ];
          });
        }

      } catch (e) {
        print('❌ Erreur chargement métiers: $e');

        if (!mounted) return;

        setState(() {
          _metiers = [
            {'id': 1, 'intitule': 'Développement Web'},
            {'id': 2, 'intitule': 'Marketing Digital'},
            {'id': 3, 'intitule': 'Design Graphique'},
            {'id': 4, 'intitule': 'Comptabilité'},
            {'id': 5, 'intitule': 'Ressources Humaines'},
          ];
          _errorMessage = 'Erreur de connexion. Métiers par défaut chargés.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur de connexion. Métiers par défaut chargés.'),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }

      setState(() => _isLoadingData = false);
      print('✅ Chargement des données terminé');

    } catch (e, stackTrace) {
      print('❌ Erreur générale lors du chargement des données: $e');
      print('📍 Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoadingData = false;
        _errorMessage = 'Erreur de chargement des données';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: _loadData,
          ),
        ),
      );
    }
  }



  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
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

  Future<void> _createEleve() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation améliorée des sélections
    if (_selectedMetierId == null || _metiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner un métier${_metiers.isEmpty ? ' (aucun métier disponible)' : ''}'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final roles = await UserService.getRoles();
      final eleveRole = roles.firstWhere(
            (role) => role['intitule'] == 'Elève',
        orElse: () => throw Exception('Rôle Élève non trouvé'),
      );

      final userData = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'date_naissance': _dateNaissance?.toIso8601String().split('T')[0],
        'genre': _genre,
        'lieu_naissance': _lieuNaissanceController.text.trim(),
        'role_id': eleveRole['id'],
        'metier_id': _selectedMetierId,
        'contact_urgence': _contactUrgenceController.text.trim(),
      };

      print('📦 Données à envoyer: $userData');

      final result = await UserService.createUser(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Élève créé avec succès!\nMot de passe: ${result['data']['password']}'),
            duration: const Duration(seconds: 8),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Erreur création élève: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Créer un Élève',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF10B981),
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
                onPressed: _loadData,
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
                SpinKitThreeInOut(
                  color:  Color(0xFF10B981),
                  size: 35.0,
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

              // Photo de profil

              const SizedBox(height: 32),

              // Informations personnelles
              _buildSectionHeader(
                'Informations personnelles',
                Icons.person_rounded,
                const Color(0xFF10B981),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email est requis';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Format d\'email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildModernTextField(
                controller: _telephoneController,
                label: 'Numéro de téléphone',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                required: true,
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
                required: true,
              ),
              const SizedBox(height: 32),

              // Informations académiques
              _buildSectionHeader(
                'Informations académiques',
                Icons.school_rounded,
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 20),

              // Métier
              _buildMetierDropdown(),
              const SizedBox(height: 32),

              // Contact d'urgence
              _buildSectionHeader(
                'Contact d\'urgence',
                Icons.emergency_rounded,
                const Color(0xFFEF4444),
              ),
              const SizedBox(height: 20),

              _buildModernTextField(
                controller: _contactUrgenceController,
                label: 'Contact d\'urgence',
                icon: Icons.contact_phone_rounded,
                keyboardType: TextInputType.phone,
                required: true,
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
            onPressed: _loadData,
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
    String? Function(String?)? validator,
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
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF10B981), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
        validator: validator ?? (required
            ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Ce champ est requis';
          }
          return null;
        }
            : null),
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
                    color: _genre == 'M' ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _genre == 'M' ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                      width: _genre == 'M' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.male_rounded,
                        color: _genre == 'M' ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Masculin',
                        style: TextStyle(
                          color: _genre == 'M' ? const Color(0xFF10B981) : const Color(0xFF6B7280),
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
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF10B981), size: 20),
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

  Widget _buildMetierDropdown() {
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
            color: _selectedMetierId != null
                ? const Color(0xFF10B981)
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
                        const Color(0xFF10B981).withOpacity(0.1),
                        const Color(0xFF10B981).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _metiers.isEmpty
                        ? 'Aucun métier disponible'
                        : 'Sélectionner un métier',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            value: _selectedMetierId,
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
            items: _metiers.map((metier) {
              return DropdownMenuItem<int>(
                value: metier['id'],
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
                          Icons.business_center_rounded,
                          color: Color(0xFF3B82F6),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          metier['intitule']?.toString() ?? 'Sans nom',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      if (_selectedMetierId == metier['id'])
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
            onChanged: _metiers.isEmpty
                ? null
                : (value) {
              setState(() => _selectedMetierId = value);
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
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
        onPressed: (_isLoading || _metiers.isEmpty) ? null : _createEleve,
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
                   'Créer l\'Élève',
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