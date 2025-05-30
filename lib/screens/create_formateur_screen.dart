import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_service.dart';

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
        // Ajout de spécialités par défaut en cas d'erreur
        _specialites = [
          {'id': 1, 'nom': 'Informatique'},
          {'id': 2, 'nom': 'Mathématiques'},
          {'id': 3, 'nom': 'Français'},
          {'id': 4, 'nom': 'Anglais'},
          {'id': 5, 'nom': 'Sciences'},
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion. Spécialités par défaut chargées.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: _loadSpecialites,
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
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
        const SnackBar(content: Text('Veuillez sélectionner une spécialité')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Formateur créé avec succès!\nMot de passe: ${result['data']['password']}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Erreur lors de la création du formateur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Créer un Formateur'),
        backgroundColor: Colors.blue.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_errorMessage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSpecialites,
              tooltip: 'Réessayer',
            ),
        ],
      ),
      body: _isLoadingSpecialites
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des spécialités...')
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message d'erreur si nécessaire
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_errorMessage!)),
                      TextButton(
                        onPressed: _loadSpecialites,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),

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

              // Informations professionnelles
              _buildSectionTitle('Informations professionnelles'),
              const SizedBox(height: 16),

              // Spécialité
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
                        Icon(Icons.school, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text(
                            _specialites.isEmpty
                                ? 'Aucune spécialité disponible'
                                : 'Sélectionner une spécialité'
                        ),
                      ],
                    ),
                    value: _selectedSpecialiteId,
                    isExpanded: true,
                    items: _specialites.map((specialite) {
                      return DropdownMenuItem<int>(
                        value: specialite['id'],
                        child: Text(specialite['nom']?.toString() ?? 'Sans nom'),
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

              // Affichage du nombre de spécialités chargées
              if (_specialites.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${_specialites.length} spécialité(s) disponible(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Bouton de création
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || _specialites.isEmpty) ? null : _createFormateur,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Créer le Formateur',
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
    super.dispose();
  }
}