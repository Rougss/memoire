import 'package:flutter/material.dart';
import '../services/competence_service.dart';

class CreateCompetenceScreen extends StatefulWidget {
  const CreateCompetenceScreen({super.key});

  @override
  State<CreateCompetenceScreen> createState() => _CreateCompetenceScreenState();
}

class _CreateCompetenceScreenState extends State<CreateCompetenceScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _codeController = TextEditingController();
  final _numeroCompetenceController = TextEditingController();
  final _quotaHoraireController = TextEditingController();

  int? _selectedMetierId;
  int? _selectedFormateurId;
  int? _selectedSalleId;

  List<Map<String, dynamic>> _metiers = [];
  List<Map<String, dynamic>> _formateurs = [];
  List<Map<String, dynamic>> _salles = [];

  bool _isLoading = false;
  bool _isLoadingData = true;

  late AnimationController _slideController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initAnimations();
  }

  void _initAnimations() {
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

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        CompetenceService.getMetiers(),
        CompetenceService.getFormateurs(),
        CompetenceService.getSalles(),
      ]);

      setState(() {
        _metiers = results[0];
        _formateurs = results[1];
        _salles = results[2];
        _isLoadingData = false;
      });

      print('✅ Métiers chargés: ${_metiers.length}');
      print('✅ Formateurs chargés: ${_formateurs.length}');
      print('✅ Salles chargées: ${_salles.length}');
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      print('❌ Erreur chargement initial: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _codeController.dispose();
    _numeroCompetenceController.dispose();
    _quotaHoraireController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      double? quotaHoraire;
      if (_quotaHoraireController.text.trim().isNotEmpty) {
        quotaHoraire = double.tryParse(_quotaHoraireController.text.trim());
      }

      await CompetenceService.createCompetence(
        nom: _nomController.text.trim(),
        code: _codeController.text.trim(),
        numeroCompetence: _numeroCompetenceController.text.trim(),
        quotaHoraire: quotaHoraire,
        metierId: _selectedMetierId!,
        formateurId: _selectedFormateurId!,
        salleId: _selectedSalleId!,
      );

      if (mounted) {
        // Animation de succès
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
                const Expanded(
                  child: Text(
                    'Compétence créée avec succès !',
                    style: TextStyle(fontWeight: FontWeight.w600),
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

        // Retour avec animation
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

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
                    errorMessage.replaceAll('Exception: ', ''),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                      Color(0xFF8B5CF6),
                      Color(0xFF7C3AED),
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      'Nouvelle compétence',
                                      style: TextStyle(
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
            backgroundColor: const Color(0xFF8B5CF6),
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
                  CircularProgressIndicator(color: Color(0xFF8B5CF6)),
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
                                        Color(0xFF8B5CF6),
                                        Color(0xFF7C3AED),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.psychology_outlined,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Instructions
                              const Text(
                                'Informations de la compétence',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Champ nom de la compétence
                              _buildTextField(
                                controller: _nomController,
                                label: 'Nom de la compétence',
                                hint: 'Ex: Développement Frontend, Base de données...',
                                icon: Icons.psychology_rounded,
                                isRequired: true,
                              ),

                              const SizedBox(height: 24),

                              // Champ code
                              _buildTextField(
                                controller: _codeController,
                                label: 'Code de la compétence',
                                hint: 'Ex: DEV-FRONT, DB-ADMIN...',
                                icon: Icons.qr_code_rounded,
                                isRequired: true,
                              ),

                              const SizedBox(height: 24),

                              // Champ numéro de compétence
                              _buildTextField(
                                controller: _numeroCompetenceController,
                                label: 'Numéro de compétence',
                                hint: 'Ex: C001, C002...',
                                icon: Icons.numbers_rounded,
                                isRequired: true,
                              ),

                              const SizedBox(height: 24),

                              // Champ quota horaire
                              _buildTextField(
                                controller: _quotaHoraireController,
                                label: 'Quota horaire (optionnel)',
                                hint: 'Ex: 40, 60...',
                                icon: Icons.schedule_rounded,
                                isRequired: false,
                                keyboardType: TextInputType.number,
                              ),

                              const SizedBox(height: 24),

                              // Dropdown métier
                              _buildDropdown<int>(
                                value: _selectedMetierId,
                                label: 'Métier',
                                hint: 'Sélectionnez un métier...',
                                icon: Icons.work_rounded,
                                items: [
                                  ..._metiers.map((metier) {
                                    return DropdownMenuItem<int>(
                                      value: metier['id'],
                                      child: Text(
                                        metier['intitule']?.toString() ?? 'N/A',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMetierId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Veuillez sélectionner un métier';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // Dropdown formateur
                              _buildDropdown<int>(
                                value: _selectedFormateurId,
                                label: 'Formateur',
                                hint: 'Sélectionnez un formateur...',
                                icon: Icons.person_rounded,
                                items: [
                                  ..._formateurs.map((formateur) {
                                    final nom = formateur['prenom']?.toString() ?? '';
                                    final prenom = formateur['nom']?.toString() ?? '';
                                    return DropdownMenuItem<int>(
                                      value: formateur['id'],
                                      child: Text(
                                        '$prenom $nom',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedFormateurId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Veuillez sélectionner un formateur';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // Dropdown salle
                              _buildDropdown<int>(
                                value: _selectedSalleId,
                                label: 'Salle',
                                hint: 'Sélectionnez une salle...',
                                icon: Icons.meeting_room_rounded,
                                items: [
                                  ..._salles.map((salle) {
                                    return DropdownMenuItem<int>(
                                      value: salle['id'],
                                      child: Text(
                                        salle['intitule']?.toString() ?? 'N/A',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSalleId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Veuillez sélectionner une salle';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 40),

                              // Bouton de création
                              AnimatedSwitcher(
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
                                          'Création en cours...',
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
                                        Color(0xFF8B5CF6),
                                        Color(0xFF7C3AED),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
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
                                      child: const Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Créer la compétence',
                                              style: TextStyle(
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
                              ),

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
    required bool isRequired,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
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
            keyboardType: keyboardType,
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
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF8B5CF6),
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
                  color: Color(0xFF8B5CF6),
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
            validator: (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return 'Ce champ est obligatoire';
              }
              if (isRequired && value!.trim().length < 2) {
                return 'Minimum 2 caractères requis';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String? Function(T?) validator,
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
          child: DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
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
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF8B5CF6),
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
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            items: items,
            onChanged: onChanged,
            validator: validator,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF64748B),
            ),
            iconSize: 24,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 300,
          ),
        ),
      ],
    );
  }
}