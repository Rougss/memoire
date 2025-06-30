
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/connectivity_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Contrôleurs de texte
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _matriculeController;
  late TextEditingController _lieuNaissanceController;

  String? selectedGenre;
  DateTime? selectedDate;

  final List<String> genres = ['M', 'F'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nomController = TextEditingController(text: widget.user['nom']?.toString() ?? '');
    _prenomController = TextEditingController(text: widget.user['prenom']?.toString() ?? '');
    _emailController = TextEditingController(text: widget.user['email']?.toString() ?? '');
    _telephoneController = TextEditingController(text: widget.user['telephone']?.toString() ?? '');
    _matriculeController = TextEditingController(text: widget.user['matricule']?.toString() ?? '');
    _lieuNaissanceController = TextEditingController(text: widget.user['lieu_naissance']?.toString() ?? '');

    selectedGenre = widget.user['genre']?.toString();

    // Parse date if exists
    if (widget.user['date_naissance'] != null) {
      try {
        selectedDate = DateTime.parse(widget.user['date_naissance']);
      } catch (e) {
        selectedDate = null;
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _matriculeController.dispose();
    _lieuNaissanceController.dispose();
    super.dispose();
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
    final String role = widget.user['role_name']?.toString() ?? 'Non défini';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Modifier l\'utilisateur',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header avec info utilisateur
          Container(
            width: double.infinity,
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
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getRoleIcon(role),
                    size: 30,
                    color: _getRoleColor(role),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.user['prenom']} ${widget.user['nom']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getRoleColor(role),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Formulaire
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Informations personnelles'),
                    const SizedBox(height: 16),

                    _buildFormCard([
                      _buildTextFormField(
                        controller: _prenomController,
                        label: 'Prénom',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le prénom est requis';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTextFormField(
                        controller: _nomController,
                        label: 'Nom',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildDropdownField(
                        value: selectedGenre,
                        label: 'Genre',
                        icon: Icons.wc,
                        items: genres.map((genre) => DropdownMenuItem(
                          value: genre,
                          child: Text(genre == 'M' ? 'Masculin' : 'Féminin'),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGenre = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildDateField(),

                      const SizedBox(height: 16),

                      _buildTextFormField(
                        controller: _lieuNaissanceController,
                        label: 'Lieu de naissance',
                        icon: Icons.location_on_outlined,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Informations de contact'),
                    const SizedBox(height: 16),

                    _buildFormCard([
                      _buildTextFormField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'L\'email est requis';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Format d\'email invalide';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTextFormField(
                        controller: _telephoneController,
                        label: 'Téléphone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Informations système'),
                    const SizedBox(height: 16),

                    _buildFormCard([
                      _buildTextFormField(
                        controller: _matriculeController,
                        label: 'Matricule',
                        icon: Icons.badge_outlined,
                        readOnly: true,
                        enabled: false,
                      ),
                    ]),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Enregistrement...'),
                      ],
                    )
                        : const Text(
                      'Enregistrer les modifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: enabled,
      style: TextStyle(
        fontSize: 16,
        color: enabled ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF64748B),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date de naissance',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedDate != null
                        ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate != null
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (selectedDate != null)
              InkWell(
                onTap: () {
                  setState(() {
                    selectedDate = null;
                  });
                },
                child: const Icon(
                  Icons.clear,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier la connexion
    if (!await ConnectivityService.checkConnectivity()) {
      _showErrorSnackBar('Connexion Internet requise');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userData = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _telephoneController.text.trim().isNotEmpty ? _telephoneController.text.trim() : null,
        'matricule': _matriculeController.text.trim().isNotEmpty ? _matriculeController.text.trim() : null,
        'genre': selectedGenre,
        'lieu_naissance': _lieuNaissanceController.text.trim().isNotEmpty ? _lieuNaissanceController.text.trim() : null,
        'date_naissance': selectedDate?.toIso8601String().split('T')[0],
      };

      final result = await ConnectivityService.executeWithConnectivity(
            () => UserService.updateUser(widget.user['id'], userData),
        errorMessage: 'Impossible de mettre à jour l\'utilisateur',
      );

      if (mounted) {
        if (result['success'] == true) {
          _showSuccessSnackBar('Utilisateur mis à jour avec succès');
          Navigator.pop(context, true); // Retourner true pour indiquer le succès
        } else {
          _showErrorSnackBar(result['message'] ?? 'Erreur lors de la mise à jour');
        }
      }
    } on NoInternetException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur inattendue lors de la mise à jour');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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