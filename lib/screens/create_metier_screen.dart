import 'package:flutter/material.dart';
import '../services/metier_service.dart';

class CreateMetierScreen extends StatefulWidget {
  final Map<String, dynamic>? metierToEdit;

  const CreateMetierScreen({super.key, this.metierToEdit});

  @override
  State<CreateMetierScreen> createState() => _CreateMetierScreenState();
}

class _CreateMetierScreenState extends State<CreateMetierScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _intituleController = TextEditingController();
  final _dureeController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedNiveauId;
  int? _selectedDepartementId;

  List<Map<String, dynamic>> _niveaux = [];
  List<Map<String, dynamic>> _departements = [];

  bool _isLoading = false;
  bool _isLoadingData = true;

  late AnimationController _slideController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  bool get isEditing => widget.metierToEdit != null;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();

    if (isEditing) {
      _populateFields();
    }
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Démarrer les animations
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _bounceController.forward();
    });
  }

  void _populateFields() {
    if (widget.metierToEdit != null) {
      final metier = widget.metierToEdit!;
      _intituleController.text = metier['intitule']?.toString() ?? '';
      _dureeController.text = metier['duree']?.toString() ?? '';
      _descriptionController.text = metier['description']?.toString() ?? '';
      _selectedNiveauId = metier['niveau_id'];
      _selectedDepartementId = metier['departement_id'];
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);

    try {
      final results = await Future.wait([
        MetierService.getNiveaux(),
        MetierService.getDepartements(),
      ]);

      setState(() {
        _niveaux = results[0];
        _departements = results[1];
        _isLoadingData = false;
      });

      print('✅ Données chargées: ${_niveaux.length} niveaux, ${_departements.length} départements');
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showError('Erreur lors du chargement des données: $e');
    }
  }

  @override
  void dispose() {
    _intituleController.dispose();
    _dureeController.dispose();
    _descriptionController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedNiveauId == null) {
      _showError('Veuillez sélectionner un niveau');
      return;
    }

    if (_selectedDepartementId == null) {
      _showError('Veuillez sélectionner un département');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await MetierService.updateMetier(
          id: widget.metierToEdit!['id'],
          intitule: _intituleController.text.trim(),
          duree: _dureeController.text.trim(),
          niveauId: _selectedNiveauId!,
          departementId: _selectedDepartementId!,
          description: _descriptionController.text.trim(),
        );
      } else {
        await MetierService.createMetier(
          intitule: _intituleController.text.trim(),
          duree: _dureeController.text.trim(),
          niveauId: _selectedNiveauId!,
          departementId: _selectedDepartementId!,
          description: _descriptionController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing ? 'Métier modifié avec succès !' : 'Métier créé avec succès !',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Erreur : $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar avec dégradé
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      isEditing ? 'Modifier le métier' : 'Nouveau métier',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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
            backgroundColor: const Color(0xFF6366F1),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Contenu principal
          SliverFillRemaining(
            hasScrollBody: false,
            child: _isLoadingData
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des données...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Carte principale du formulaire
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Icône principale animée
                              ScaleTransition(
                                scale: _bounceAnimation,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.work_outlined,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Instructions
                              Text(
                                isEditing ? 'Modifier les informations' : 'Informations du métier',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Champ intitulé
                              _buildTextField(
                                controller: _intituleController,
                                label: 'Intitulé du métier',
                                hint: 'Ex: Développement Web, Électricité...',
                                icon: Icons.work_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez entrer un intitulé';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'L\'intitulé doit contenir au moins 2 caractères';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _dureeController,
                                label: 'Durée de formation',
                                hint: 'Ex: 2 ans, 18 mois...',
                                icon: Icons.schedule_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez entrer la durée';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              _buildDropdown(
                                label: 'Niveau',
                                hint: 'Sélectionner un niveau',
                                icon: Icons.school_rounded,
                                value: _selectedNiveauId,
                                items: _niveaux,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedNiveauId = value;
                                  });
                                },
                              ),

                              const SizedBox(height: 20),

                              // Dropdown département
                              _buildDropdown(
                                label: 'Département',
                                hint: 'Sélectionner ',
                                icon: Icons.business_rounded,
                                value: _selectedDepartementId,
                                items: _departements,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDepartementId = value;
                                  });
                                },
                                displayKey: 'nom_departement',
                              ),

                              const SizedBox(height: 20),

                              // Champ description (optionnel)
                              _buildTextField(
                                controller: _descriptionController,
                                label: 'Description (optionnel)',
                                hint: 'Décrivez brièvement ce métier...',
                                icon: Icons.description_rounded,
                                maxLines: 3,
                                required: false,
                              ),

                              const SizedBox(height: 40),

                              // Bouton de création/modification
                              _buildSubmitButton(),

                              const SizedBox(height: 16),

                              // Bouton annuler
                              TextButton(
                                onPressed: _isLoading ? null : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Annuler',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required int? value,
    required List<Map<String, dynamic>> items,
    required Function(int?) onChanged,
    String displayKey = 'intitule',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<int>(
            value: value,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem<int>(
                value: item['id'],
                child: Text(
                  item[displayKey]?.toString() ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isLoading
          ? Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF94A3B8),
              Color(0xFF64748B),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'En cours...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      )
          : Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _submitForm,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Modifier le métier' : 'Créer le métier',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}