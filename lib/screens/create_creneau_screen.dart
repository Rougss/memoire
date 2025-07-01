import 'package:flutter/material.dart';
import '../services/emploi_du_temps_service.dart';

class CreateCreneauScreen extends StatefulWidget {
  const CreateCreneauScreen({Key? key}) : super(key: key);

  @override
  State<CreateCreneauScreen> createState() => _CreateCreneauScreenState();
}

class _CreateCreneauScreenState extends State<CreateCreneauScreen> {
  final PageController _pageController = PageController();

  // 🆕 ÉTAPES MODIFIÉES : 5 étapes au lieu de 4
  int _currentStep = 0;
  final List<String> _steps = [
    'Sélection du métier',
    'Sélection des compétences',
    'Configuration intelligente',
    'Aperçu planification',
    'Confirmation'
  ];

  // 🆕 NOUVELLES VARIABLES POUR MÉTIERS
  List<Map<String, dynamic>> _metiersDisponibles = [];
  Map<String, dynamic>? _metierSelectionne;

  // Variables pour compétences
  List<Map<String, dynamic>> _competencesDisponibles = [];
  List<Map<String, dynamic>> _competencesSelectionnees = [];

  // Variables pour configuration
  List<Map<String, dynamic>> _annees = [];
  int? _selectedAnneeId;
  DateTime? _dateDebut;
  int _maxSeancesParCompetence = 3;
  Map<int, int> _dureeParCompetence = {};

  // Planification générée
  List<Map<String, dynamic>> _planificationGeneree = [];

  // États
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _debugAnnees() {
    print('=== DEBUG ANNÉES ===');
    print('Nombre d\'années: ${_annees.length}');
    for (var annee in _annees) {
      print('ID: ${annee['id']}, Intitulé: ${annee['intitule']}');
    }
    print('Année sélectionnée: $_selectedAnneeId');
    print('==================');
  }

  // 🆕 CHARGEMENT INITIAL : Charger années et métiers
  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);

    try {
      final results = await Future.wait([
        EmploiDuTempsService.getAllAnnees(),
        EmploiDuTempsService.getMetiersAvecCompetences(),
      ]);

      setState(() {
        _annees = results[0];
        _metiersDisponibles = results[1];
        _isLoadingData = false;
      });

      print('✅ ${_annees.length} années et ${_metiersDisponibles.length} métiers chargés');
      _debugAnnees(); // Ajout du debug
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showError('Erreur lors du chargement: $e');
    }
  }

  // 🆕 CHARGER LES COMPÉTENCES D'UN MÉTIER SÉLECTIONNÉ
  Future<void> _loadCompetencesDuMetier(Map<String, dynamic> metier) async {
    setState(() => _isLoading = true);

    try {
      final competencesDuMetier = await EmploiDuTempsService.getCompetencesAvecQuotaByMetier(
          metier['id']
      );

      setState(() {
        _competencesDisponibles = competencesDuMetier;
        _competencesSelectionnees.clear();
        _dureeParCompetence.clear();
        _isLoading = false;
      });

      print('📚 ${competencesDuMetier.length} compétences chargées pour ${metier['intitule']}');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement des compétences: $e');
    }
  }

  // 🆕 PLANIFICATION AVEC VÉRIFICATION MÉTIER
  Future<void> _planifierCompetences() async {
    if (_competencesSelectionnees.isEmpty || _dateDebut == null ||
        _selectedAnneeId == null || _metierSelectionne == null) {
      _showError('Veuillez remplir tous les champs requis');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final competencesConfig = _competencesSelectionnees.map((comp) {
        final dureeParCours = _dureeParCompetence[comp['id']] ?? 2;
        return {
          'id': comp['id'],
          'duree_cours': dureeParCours,
          'max_seances': _maxSeancesParCompetence,
        };
      }).toList();

      final result = await EmploiDuTempsService.planifierCompetencesLimitees(
        anneeId: _selectedAnneeId!,
        dateDebut: _formatDateForApi(_dateDebut!),
        competences: competencesConfig,
        maxSeancesParCompetence: _maxSeancesParCompetence,
      );

      if (result['success'] == true) {
        final summary = result['data']['resume'] ?? {};
        final creneauxCrees = summary['creneaux_crees'] ?? 0;
        final quotasMisAJour = summary['quotas_mis_a_jour'] ?? [];

        _showSuccessWithDetails(
            'Emploi du temps créé pour ${_metierSelectionne!['intitule']} !',
            '$creneauxCrees créneaux créés\n${quotasMisAJour.length} quotas mis à jour'
        );

        Navigator.pop(context, true);
      } else {
        _showError(result['message'] ?? 'Erreur lors de la planification');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Méthodes utilitaires
  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      if (_currentStep == 3) { // Étape aperçu
        _simulerPlanificationLimitee();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _simulerPlanificationLimitee() {
    List<Map<String, dynamic>> simulation = [];

    for (var comp in _competencesSelectionnees) {
      final duree = _dureeParCompetence[comp['id']] ?? 2;
      final heuresRestantes = comp['heures_restantes'] ?? 0.0;
      final maxSeancesPossibles = (heuresRestantes / duree).floor();
      final seancesACreer = maxSeancesPossibles < _maxSeancesParCompetence
          ? maxSeancesPossibles
          : _maxSeancesParCompetence;

      for (int j = 0; j < seancesACreer; j++) {
        simulation.add({
          'competence': comp,
          'duree_heures': duree,
          'numero_seance': j + 1,
          'seances_dans_cet_emploi': seancesACreer,
          'heures_utilisees': seancesACreer * duree,
          'heures_restantes_apres': heuresRestantes - (seancesACreer * duree),
        });
      }
    }

    setState(() {
      _planificationGeneree = simulation;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessWithDetails(String title, String details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(details),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
          'Planification Intelligente',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildStepIndicator(),
          _buildInfoContextuelle(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1SelectionMetier(),
                _buildStep2SelectionCompetences(),
                _buildStep3ConfigurationIntelligente(),
                _buildStep4ApercuPlanification(),
                _buildStep5Confirmation(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (index) {
              bool isActive = index <= _currentStep;
              bool isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        border: isCurrent ? Border.all(color: const Color(0xFF3B82F6), width: 3) : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (index < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: index < _currentStep ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            _steps[_currentStep],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContextuelle() {
    if (_metierSelectionne == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Métier: ${_metierSelectionne!['intitule']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Département: ${_metierSelectionne!['departement']?['nom_departement'] ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
                if (_competencesSelectionnees.isNotEmpty)
                  Text(
                    '${_competencesSelectionnees.length} compétences sélectionnées',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 ÉTAPE 1 : SÉLECTION DU MÉTIER
  Widget _buildStep1SelectionMetier() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: '🎯 Choisir le métier',
            subtitle: 'Sélectionnez d\'abord le métier pour lequel vous voulez créer l\'emploi du temps',
            child: _metiersDisponibles.isEmpty
                ? _buildEmptyState('Aucun métier avec compétences disponibles')
                : Column(
              children: _metiersDisponibles.map((metier) {
                bool isSelected = _metierSelectionne != null &&
                    _metierSelectionne!['id'] == metier['id'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.work,
                        color: const Color(0xFF3B82F6),
                        size: 28,
                      ),
                    ),
                    title: Text(
                      metier['intitule'] ?? 'Métier',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isSelected ? const Color(0xFF3B82F6) : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Département: ${metier['departement']?['nom_departement'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${metier['competences_count']} compétences disponibles',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Radio<Map<String, dynamic>>(
                      value: metier,
                      groupValue: _metierSelectionne,
                      onChanged: (Map<String, dynamic>? value) {
                        setState(() {
                          _metierSelectionne = value;
                        });
                        if (value != null) {
                          _loadCompetencesDuMetier(value);
                        }
                      },
                      activeColor: const Color(0xFF3B82F6),
                    ),
                    onTap: () {
                      setState(() {
                        _metierSelectionne = metier;
                      });
                      _loadCompetencesDuMetier(metier);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          if (_metierSelectionne != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Métier sélectionné',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📋 ${_metierSelectionne!['intitule']}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Text(
                    '🏢 ${_metierSelectionne!['departement']?['nom_departement'] ?? 'Département non défini'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '📚 ${_metierSelectionne!['competences_count']} compétences seront disponibles à l\'étape suivante',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 ÉTAPE 2 : SÉLECTION DES COMPÉTENCES
  Widget _buildStep2SelectionCompetences() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_metierSelectionne != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.work, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Métier: ${_metierSelectionne!['intitule']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Compétences disponibles pour ce métier',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          _buildSectionCard(
            title: '📚 Compétences du métier',
            subtitle: 'Sélectionnez les compétences à inclure dans cet emploi du temps',
            child: _isLoading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
                : _competencesDisponibles.isEmpty
                ? _buildEmptyState('Aucune compétence avec quota restant pour ce métier')
                : Column(
              children: _competencesDisponibles.map((competence) {
                bool isSelected = _competencesSelectionnees.any((c) => c['id'] == competence['id']);
                double quotaRestant = (competence['heures_restantes'] ?? 0.0).toDouble();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      competence['nom'] ?? 'Compétence',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Code: ${competence['code'] ?? 'N/A'}'),
                        const SizedBox(height: 4),
                        Text('Formateur: ${competence['formateur']?['prenom']} ${competence['formateur']?['nom']}'),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${quotaRestant.toStringAsFixed(1)}h restantes',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _competencesSelectionnees.add(competence);
                            _dureeParCompetence[competence['id']] = 2;
                          } else {
                            _competencesSelectionnees.removeWhere((c) => c['id'] == competence['id']);
                            _dureeParCompetence.remove(competence['id']);
                          }
                        });
                      },
                      activeColor: const Color(0xFF3B82F6),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (_competencesSelectionnees.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_competencesSelectionnees.length} compétences sélectionnées',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total heures disponibles: ${_competencesSelectionnees.fold<double>(0, (sum, comp) => sum + (comp['heures_restantes'] ?? 0.0)).toStringAsFixed(1)}h',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ÉTAPE 3 : CONFIGURATION INTELLIGENTE
  Widget _buildStep3ConfigurationIntelligente() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionCard(
            title: '🎓 Configuration générale',
            subtitle: 'Année et date de début',
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white, // Ajout d'un fond blanc
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedAnneeId,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      hintText: 'Choisir une année',
                    ),
                    isExpanded: true, // Important : permet au dropdown de s'étendre
                    items: _annees.map((annee) {
                      return DropdownMenuItem<int>(
                        value: annee['id'],
                        child: Text(
                          annee['intitule'] ?? 'Année ${annee['id']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAnneeId = value;
                      });
                      print('Année sélectionnée: $value'); // Debug
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une année';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _dateDebut ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _dateDebut = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 12),
                        Text(
                          _dateDebut != null
                              ? 'Début: ${_formatDate(_dateDebut!)}'
                              : 'Sélectionner une date de début',
                          style: TextStyle(
                            fontSize: 16,
                            color: _dateDebut != null ? Colors.black : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionCard(
            title: '⚡ Configuration intelligente',
            subtitle: 'Limitation du nombre de séances',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Séances maximum par compétence:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [1, 2, 3, 4, 5].map((nombre) {
                    bool isSelected = _maxSeancesParCompetence == nombre;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _maxSeancesParCompetence = nombre;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$nombre',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  nombre == 1 ? 'séance' : 'séances',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Chaque compétence aura maximum $_maxSeancesParCompetence séance(s) dans cet emploi du temps.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionCard(
            title: '⚙️ Configuration par compétence',
            subtitle: 'Définissez la durée de chaque cours',
            child: _competencesSelectionnees.isEmpty
                ? _buildEmptyState('Aucune compétence sélectionnée')
                : Column(
              children: _competencesSelectionnees.map((competence) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Color(0xFF3B82F6),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  competence['nom'] ?? 'Compétence',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${competence['heures_restantes']?.toStringAsFixed(1)}h restantes',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Durée par cours:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [1, 2, 3, 4].map((duree) {
                          bool isSelected = _dureeParCompetence[competence['id']] == duree;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _dureeParCompetence[competence['id']] = duree;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF3B82F6)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF3B82F6)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    '${duree}h',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calculate, size: 16, color: Colors.green.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  _calculerSeancesLimitees(competence),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _calculerHeuresUtilisees(competence),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ÉTAPE 4 : APERÇU PLANIFICATION
  Widget _buildStep4ApercuPlanification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_planificationGeneree.isEmpty)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Simulation de la planification...'),
                ],
              ),
            )
          else
            _buildSectionCard(
              title: '📋 Aperçu de la planification intelligente',
              subtitle: '${_planificationGeneree.length} séances prévues (max $_maxSeancesParCompetence par compétence)',
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.green.shade600, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'Planification Intelligente',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Total séances', '${_planificationGeneree.length}'),
                        _buildSummaryRow('Compétences', '${_competencesSelectionnees.length}'),
                        _buildSummaryRow('Max par compétence', '$_maxSeancesParCompetence séances'),
                        _buildSummaryRow('Date début', _dateDebut != null ? _formatDate(_dateDebut!) : 'Non définie'),
                        _buildSummaryRow('Métier', _metierSelectionne?['intitule'] ?? 'Non défini'),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        ..._buildResumeQuotas(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      itemCount: _competencesSelectionnees.length,
                      itemBuilder: (context, index) {
                        final competence = _competencesSelectionnees[index];
                        final seancesCompetence = _planificationGeneree
                            .where((s) => s['competence']['id'] == competence['id'])
                            .toList();

                        if (seancesCompetence.isEmpty) return const SizedBox();

                        final premiereSeance = seancesCompetence.first;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${seancesCompetence.length}',
                                        style: const TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          competence['nom'] ?? 'Compétence',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '${seancesCompetence.length} séances • ${premiereSeance['duree_heures']}h chacune',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Heures utilisées:', style: TextStyle(fontSize: 12)),
                                        Text('${premiereSeance['heures_utilisees']}h',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Quota restant après:', style: TextStyle(fontSize: 12)),
                                        Text('${premiereSeance['heures_restantes_apres']?.toStringAsFixed(1)}h',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                                color: Colors.green.shade700)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ÉTAPE 5 : CONFIRMATION
  Widget _buildStep5Confirmation() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Planification pour ${_metierSelectionne?['intitule'] ?? 'le métier sélectionné'} prête !',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Votre emploi du temps sera généré avec un maximum de $_maxSeancesParCompetence séances par compétence',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.psychology, color: Colors.blue.shade600, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'Planification Intelligente',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Récapitulatif final:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '🎯 Métier: ${_metierSelectionne?['intitule'] ?? 'Non défini'}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '🏢 Département: ${_metierSelectionne?['departement']?['nom_departement'] ?? 'Non défini'}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '📚 ${_competencesSelectionnees.length} compétences sélectionnées',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '⚡ Maximum $_maxSeancesParCompetence séances par compétence',
                  style: const TextStyle(fontSize: 12),
                ),
                if (_dateDebut != null)
                  Text(
                    '📅 Date de début: ${_formatDate(_dateDebut!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes helper pour les calculs
  String _calculerSeancesLimitees(Map<String, dynamic> competence) {
    final heuresRestantes = competence['heures_restantes'] ?? 0.0;
    final duree = _dureeParCompetence[competence['id']] ?? 2;
    final maxSeancesPossibles = (heuresRestantes / duree).floor();
    final seancesACreer = maxSeancesPossibles < _maxSeancesParCompetence
        ? maxSeancesPossibles
        : _maxSeancesParCompetence;

    return '$seancesACreer séances de ${duree}h dans cet emploi du temps';
  }

  String _calculerHeuresUtilisees(Map<String, dynamic> competence) {
    final heuresRestantes = competence['heures_restantes'] ?? 0.0;
    final duree = _dureeParCompetence[competence['id']] ?? 2;
    final maxSeancesPossibles = (heuresRestantes / duree).floor();
    final seancesACreer = maxSeancesPossibles < _maxSeancesParCompetence
        ? maxSeancesPossibles
        : _maxSeancesParCompetence;

    final heuresUtilisees = seancesACreer * duree;
    final heuresRestantesApres = heuresRestantes - heuresUtilisees;

    return 'Utilise ${heuresUtilisees}h • Reste ${heuresRestantesApres.toStringAsFixed(1)}h';
  }

  List<Widget> _buildResumeQuotas() {
    double totalHeuresUtilisees = 0;
    double totalHeuresRestantes = 0;

    for (var competence in _competencesSelectionnees) {
      final duree = _dureeParCompetence[competence['id']] ?? 2;
      final heuresRestantes = competence['heures_restantes'] ?? 0.0;
      final maxSeancesPossibles = (heuresRestantes / duree).floor();
      final seancesACreer = maxSeancesPossibles < _maxSeancesParCompetence
          ? maxSeancesPossibles
          : _maxSeancesParCompetence;

      final heuresUtilisees = seancesACreer * duree;
      totalHeuresUtilisees += heuresUtilisees;
      totalHeuresRestantes += (heuresRestantes - heuresUtilisees);
    }

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total heures utilisées:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text('${totalHeuresUtilisees.toStringAsFixed(1)}h',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total heures restantes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text('${totalHeuresRestantes.toStringAsFixed(1)}h',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
        ],
      ),
    ];
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Précédent',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _canProceed() ? (_currentStep == _steps.length - 1 ? _planifierCompetences : _nextStep) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                _getButtonText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Sélection métier
        return _metierSelectionne != null;
      case 1: // Sélection compétences
        return _competencesSelectionnees.isNotEmpty;
      case 2: // Configuration
        return _selectedAnneeId != null &&
            _dateDebut != null &&
            _competencesSelectionnees.every((comp) =>
                _dureeParCompetence.containsKey(comp['id']));
      case 3: // Aperçu
        return _planificationGeneree.isNotEmpty;
      case 4: // Confirmation
        return true;
      default:
        return false;
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        if (_metierSelectionne != null) {
          final competencesCount = _metierSelectionne!['com!petences_count'] ?? 0;
          return 'Voir les compétences ($competencesCount disponibles)';
        }
        return 'Choisir le métier';
      case 1:
        return 'Configurer (${_competencesSelectionnees.length} sélectionnées)';
      case 2:
        return 'Voir l\'aperçu intelligent';
      case 3:
        return 'Confirmer la planification';
      case 4:
        return 'Créer l\'emploi du temps';
      default:
        return 'Suivant';
    }
  }
}