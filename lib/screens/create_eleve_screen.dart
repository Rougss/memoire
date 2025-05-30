import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_service.dart';

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
  List<Map<String, dynamic>> _salles = [];
  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final metiers = await UserService.getMetiers();
      final salles = await UserService.getSalles();
      setState(() {
        _metiers = metiers;
        _salles = salles;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

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
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateNaissance) {
      setState(() {
        _dateNaissance = picked;
      });
    }
  }

  Future<void> _createEleve() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMetierId == null) {
      _showError('Veuillez sélectionner un métier');
      return;
    }
    if (_selectedSalleId == null) {
      _showError('Veuillez sélectionner une salle');
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
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'email': _emailController.text,
        'telephone': _telephoneController.text,
        'date_naissance': _dateNaissance?.toIso8601String().split('T')[0],
        'genre': _genre,
        'lieu_naissance': _lieuNaissanceController.text,
        'role_id': eleveRole['id'],
        'metier_id': _selectedMetierId,
        'salle_id': _selectedSalleId,
        'contact_urgence': _contactUrgenceController.text,
      };

      final result = await UserService.createUser(userData);

      if (mounted) {
        _showSuccess('Élève créé avec succès!\nMot de passe: ${result['data']['password']}');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Créer un Élève'),
        backgroundColor: Colors.green.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo de profil
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _selectedImage != null
                        ? ClipOval(
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Informations personnelles
              _buildSectionTitle('Informations personnelles'),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _nomController,
                label: 'Nom',
                icon: Icons.person,
                required: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _prenomController,
                label: 'Prénom',
                icon: Icons.person_outline,
                required: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                required: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _telephoneController,
                label: 'Téléphone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Genre
              Text(
                'Genre',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Masculin'),
                      value: 'M',
                      groupValue: _genre,
                      onChanged: (value) => setState(() => _genre = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Féminin'),
                      value: 'F',
                      groupValue: _genre,
                      onChanged: (value) => setState(() => _genre = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date de naissance
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        _dateNaissance != null
                            ? '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}'
                            : 'Date de naissance',
                        style: TextStyle(
                          color: _dateNaissance != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _lieuNaissanceController,
                label: 'Lieu de naissance',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 30),

              // Informations académiques
              _buildSectionTitle('Informations académiques'),
              const SizedBox(height: 16),

              // Métier
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    hint: Row(
                      children: [
                        Icon(Icons.work, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        const Text('Sélectionner un métier'),
                      ],
                    ),
                    value: _selectedMetierId,
                    isExpanded: true,
                    items: _metiers.map((metier) {
                      return DropdownMenuItem<int>(
                        value: metier['id'],
                        child: Text(metier['nom'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedMetierId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Salle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    hint: Row(
                      children: [
                        Icon(Icons.meeting_room, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        const Text('Sélectionner une salle'),
                      ],
                    ),
                    value: _selectedSalleId,
                    isExpanded: true,
                    items: _salles.map((salle) {
                      return DropdownMenuItem<int>(
                        value: salle['id'],
                        child: Text(salle['nom'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSalleId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Contact d'urgence
              _buildSectionTitle('Contact d\'urgence'),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _contactUrgenceController,
                label: 'Contact d\'urgence',
                icon: Icons.emergency,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40),

              // Bouton de création
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createEleve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Créer l\'Élève',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: required
          ? (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est requis';
        }
        return null;
      }
          : null,
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _lieuNaissanceController.dispose();
    _contactUrgenceController.dispose();
    super.dispose();
  }
}