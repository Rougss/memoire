import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CreateSurveillantScreen extends StatefulWidget {
  const CreateSurveillantScreen({Key? key}) : super(key: key);

  @override
  _CreateSurveillantScreenState createState() => _CreateSurveillantScreenState();
}

class _CreateSurveillantScreenState extends State<CreateSurveillantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();

  DateTime? _dateNaissance;
  String _genre = 'M';
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
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
              primary: Color(0xFFEF4444),
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

  Future<void> _createSurveillant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('Récupération des rôles...');
      final roles = await UserService.getRoles();
      final surveillantRole = roles.firstWhere(
            (role) => role['intitule'] == 'Surveillant',
        orElse: () => throw Exception('Rôle Surveillant non trouvé'),
      );

      final userData = {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'email': _emailController.text,
        'telephone': _telephoneController.text,
        'date_naissance': _dateNaissance?.toIso8601String().split('T')[0],
        'genre': _genre,
        'lieu_naissance': _lieuNaissanceController.text,
        'role_id': surveillantRole['id'],
      };

      print('Données utilisateur à envoyer: $userData');
      final result = await UserService.createUser(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Surveillant créé avec succès!\nMot de passe: ${result['data']['password']}'),
            duration: const Duration(seconds: 5),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Erreur lors de la création du surveillant: $e');
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
          'Créer un Surveillant',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor:const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildFormSection(),
          ],
        ),
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

              // Informations personnelles
              _buildSectionHeader(
                'Informations personnelles',
                Icons.person_rounded,
                const Color(0xFFFF9800),
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

              // Bouton de création
              _buildCreateButton(),
            ],
          ),
        ),
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
              color: const Color(0xFFFF9800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFF9800), size: 20),
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
                    color: _genre == 'M' ? const Color(0xFFFF9800).withOpacity(0.1) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _genre == 'M' ? const Color(0xFFFF9800) : const Color(0xFFE5E7EB),
                      width: _genre == 'M' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.male_rounded,
                        color: _genre == 'M' ? const Color(0xFFFF9800) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Masculin',
                        style: TextStyle(
                          color: _genre == 'M' ? const Color(0xFFFF9800) : const Color(0xFF6B7280),
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
                    color: _genre == 'F' ? const Color(0xFFFF9800).withOpacity(0.1) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _genre == 'F' ? const Color(0xFFFF9800) : const Color(0xFFE5E7EB),
                      width: _genre == 'F' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.female_rounded,
                        color: _genre == 'F' ? const Color(0xFFFF9800) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Féminin',
                        style: TextStyle(
                          color: _genre == 'F' ? const Color(0xFFFF9800): const Color(0xFF6B7280),
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
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: const Color(0xFFFF9800), size: 20),
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

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [const Color(0xFFFF9800), Color(0xFFDC3629)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createSurveillant,
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
            Icon(Icons.security_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Créer le Surveillant',
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