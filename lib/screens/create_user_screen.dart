import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/user.dart';
import '../services/role_service.dart';
import '../services/user_service.dart';
import '../services/specialite_service.dart'; // À créer
import '../services/metier_service.dart'; // À créer

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({Key? key}) : super(key: key);

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs de texte de base
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _contactUrgenceController = TextEditingController();

  // Variables d'état
  List<Role> _roles = [];
  Role? _selectedRole;
  bool _isLoading = false;
  bool _isLoadingRoles = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _errorMessage = '';

  // Variables pour les champs spécifiques
  DateTime? _selectedDate;
  String? _selectedGenre = 'M';
  List<dynamic> _specialites = [];
  List<dynamic> _metiers = [];
  int? _selectedSpecialiteId;
  int? _selectedMetierId;
  bool _isLoadingSpecialites = false;
  bool _isLoadingMetiers = false;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _lieuNaissanceController.dispose();
    _contactUrgenceController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await RoleService.getAllRoles();
      setState(() {
        _roles = roles;
        _isLoadingRoles = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des rôles: $e';
        _isLoadingRoles = false;
      });
    }
  }

  Future<void> _loadSpecialites() async {
    setState(() {
      _isLoadingSpecialites = true;
    });

    try {
      // Remplacez par votre service réel
      // final specialites = await SpecialiteService.getAllSpecialites();
      // Exemple de données fictives pour le moment
      final specialites = [
        {'id': 1, 'nom': 'Informatique'},
        {'id': 2, 'nom': 'Électronique'},
        {'id': 3, 'nom': 'Mécanique'},
        {'id': 4, 'nom': 'Génie Civil'},
      ];

      setState(() {
        _specialites = specialites;
        _isLoadingSpecialites = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSpecialites = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des spécialités: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadMetiers() async {
    setState(() {
      _isLoadingMetiers = true;
    });

    try {
      // Remplacez par votre service réel
      // final metiers = await MetierService.getAllMetiers();
      // Exemple de données fictives pour le moment
      final metiers = [
        {'id': 1, 'nom': 'Développeur Web'},
        {'id': 2, 'nom': 'Technicien Réseau'},
        {'id': 3, 'nom': 'Designer Graphique'},
        {'id': 4, 'nom': 'Électricien'},
      ];

      setState(() {
        _metiers = metiers;
        _isLoadingMetiers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMetiers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des métiers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onRoleSelected(Role role) {
    setState(() {
      _selectedRole = role;
      _selectedSpecialiteId = null;
      _selectedMetierId = null;
    });

    // Charger les données spécifiques selon le rôle
    if (role.intitule.toLowerCase() == 'formateur') {
      _loadSpecialites();
    } else if (role.intitule.toLowerCase() == 'elève' || role.intitule.toLowerCase() == 'élève') {
      _loadMetiers();
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un rôle'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation spécifique selon le rôle
    if (_selectedRole!.intitule.toLowerCase() == 'formateur' && _selectedSpecialiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une spécialité pour le formateur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((_selectedRole!.intitule.toLowerCase() == 'elève' || _selectedRole!.intitule.toLowerCase() == 'élève') && _selectedMetierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un métier pour l\'élève'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newUser = User(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        telephone: _telephoneController.text.trim(),
        adresse: _adresseController.text.trim(),
        roleId: _selectedRole!.id!,
        motDePasse: _passwordController.text,
        dateNaissance: _selectedDate,
        genre: _selectedGenre,
        lieuNaissance: _lieuNaissanceController.text.trim().isEmpty ? null : _lieuNaissanceController.text.trim(),
        // Champs spécifiques selon le rôle
        specialiteId: _selectedSpecialiteId,
        metierId: _selectedMetierId,
        contactUrgence: _contactUrgenceController.text.trim().isEmpty ? null : _contactUrgenceController.text.trim(),
      );

      await UserService.createUser(newUser as Map<String, dynamic>);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur ${newUser.prenom} ${newUser.nom} créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRoleSelector() {
    if (_isLoadingRoles) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Chargement des rôles...'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rôle de l\'utilisateur *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roles.map((role) {
                final isSelected = _selectedRole?.id == role.id;
                Color roleColor = _getRoleColor(role.intitule);

                return FilterChip(
                  selected: isSelected,
                  label: Text(role.intitule),
                  avatar: Icon(
                    _getRoleIcon(role.intitule),
                    size: 18,
                    color: isSelected ? Colors.white : roleColor,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _onRoleSelected(role);
                    } else {
                      setState(() {
                        _selectedRole = null;
                        _selectedSpecialiteId = null;
                        _selectedMetierId = null;
                      });
                    }
                  },
                  selectedColor: roleColor,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : roleColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificFields() {
    if (_selectedRole == null) return const SizedBox.shrink();

    List<Widget> specificFields = [];

    switch (_selectedRole!.intitule.toLowerCase()) {
      case 'formateur':
        specificFields.add(_buildFormateurFields());
        break;
      case 'elève':
      case 'élève':
        specificFields.add(_buildEleveFields());
        break;
      case 'surveillant':
        specificFields.add(_buildSurveilantFields());
        break;
      case 'administrateur':
      case 'directeur des etudes':
      // Pas de champs spécifiques pour ces rôles
        break;
    }

    if (specificFields.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations spécifiques - ${_selectedRole!.intitule}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...specificFields,
          ],
        ),
      ),
    );
  }

  Widget _buildFormateurFields() {
    return Column(
      children: [
        // Spécialité (obligatoire pour formateur)
        _isLoadingSpecialites
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<int>(
          value: _selectedSpecialiteId,
          decoration: const InputDecoration(
            labelText: 'Spécialité *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school),
          ),
          items: _specialites.map((specialite) {
            return DropdownMenuItem<int>(
              value: specialite['id'],
              child: Text(specialite['nom']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSpecialiteId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'La spécialité est obligatoire pour un formateur';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEleveFields() {
    return Column(
      children: [
        // Contact d'urgence
        TextFormField(
          controller: _contactUrgenceController,
          decoration: const InputDecoration(
            labelText: 'Contact d\'urgence',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.emergency),
          ),
        ),
        const SizedBox(height: 16),
        // Métier (obligatoire pour élève)
        _isLoadingMetiers
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<int>(
          value: _selectedMetierId,
          decoration: const InputDecoration(
            labelText: 'Métier *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
          items: _metiers.map((metier) {
            return DropdownMenuItem<int>(
              value: metier['id'],
              child: Text(metier['nom']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMetierId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Le métier est obligatoire pour un élève';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSurveilantFields() {
    // Pour le moment, pas de champs spécifiques pour surveillant
    // Vous pouvez ajouter des champs si nécessaire
    return const Text(
      'Aucun champ spécifique requis pour ce rôle.',
      style: TextStyle(
        fontStyle: FontStyle.italic,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildAdditionalFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations complémentaires',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Date de naissance
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 ans
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Sélectionner une date',
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Genre
            DropdownButtonFormField<String>(
              value: _selectedGenre,
              decoration: const InputDecoration(
                labelText: 'Genre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Masculin')),
                DropdownMenuItem(value: 'F', child: Text('Féminin')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGenre = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Lieu de naissance
            TextFormField(
              controller: _lieuNaissanceController,
              decoration: const InputDecoration(
                labelText: 'Lieu de naissance',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'administrateur':
        return Colors.red;
      case 'directeur des etudes':
        return Colors.purple;
      case 'formateur':
        return Colors.blue;
      case 'surveillant':
        return Colors.orange;
      case 'elève':
      case 'élève':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'administrateur':
        return Icons.admin_panel_settings;
      case 'directeur des etudes':
        return Icons.school;
      case 'formateur':
        return Icons.person_outline;
      case 'surveillant':
        return Icons.security;
      case 'elève':
      case 'élève':
        return Icons.person;
      default:
        return Icons.group;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un utilisateur'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingRoles && _errorMessage.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? _buildErrorWidget()
          : _buildForm(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = '';
                _isLoadingRoles = true;
              });
              _loadRoles();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informations personnelles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nomController,
                            decoration: const InputDecoration(
                              labelText: 'Nom *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom est obligatoire';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _prenomController,
                            decoration: const InputDecoration(
                              labelText: 'Prénom *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le prénom est obligatoire';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'email est obligatoire';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Format d\'email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adresseController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sélection du rôle
            _buildRoleSelector(),

            const SizedBox(height: 16),

            // Champs spécifiques selon le rôle
            _buildRoleSpecificFields(),

            const SizedBox(height: 16),

            // Informations complémentaires
            _buildAdditionalFields(),

            const SizedBox(height: 16),

            // Mot de passe
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mot de passe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est obligatoire';
                        }
                        if (value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez confirmer le mot de passe';
                        }
                        if (value != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bouton de création
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Création en cours...'),
                  ],
                )
                    : const Text(
                  'Créer l\'utilisateur',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}