import 'package:flutter/material.dart';
import '../services/emploi_du_temps_service.dart';

class CreateCreneauScreen extends StatefulWidget {
  const CreateCreneauScreen({Key? key}) : super(key: key);

  @override
  State<CreateCreneauScreen> createState() => _CreateCreneauScreenState();
}

class _CreateCreneauScreenState extends State<CreateCreneauScreen> {
  final _formKey = GlobalKey<FormState>();

  // Variables du formulaire
  DateTime? _dateDebut;
  DateTime? _dateFin;
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;

  int? _selectedAnneeId;
  List<int> _selectedCompetences = [];

  // Données depuis l'API
  List<Map<String, dynamic>> _annees = [];
  List<Map<String, dynamic>> _competences = [];

  // États de chargement
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Créneaux prédéfinis
  final List<Map<String, String>> _creneauxPredefinis = [
    {'debut': '08:00', 'fin': '10:00', 'nom': 'Matin 1 (8h-10h)'},
    {'debut': '10:15', 'fin': '12:15', 'nom': 'Matin 2 (10h15-12h15)'},
    {'debut': '14:00', 'fin': '16:00', 'nom': 'Après-midi 1 (14h-16h)'},
    {'debut': '16:15', 'fin': '18:15', 'nom': 'Après-midi 2 (16h15-18h15)'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _dateDebut = now;
    _dateFin = now;
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Charger les vraies données en parallèle
      await Future.wait([
        _loadAnnees(),
        _loadCompetences(),
      ]);

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      _showError('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _loadAnnees() async {
    try {
      // D'abord récupérer les infos du formateur connecté pour avoir son département
      final userInfo = await EmploiDuTempsService.getUserInfo();

      if (userInfo['success'] == true && userInfo['data'] != null) {
        final formateurData = userInfo['data'];
        final departementsGeres = formateurData['departements_geres'] as List?;

        if (departementsGeres != null && departementsGeres.isNotEmpty) {
          // Prendre le premier département géré
          final departementId = departementsGeres[0]['id'] as int;

          // Maintenant récupérer les années de ce département
          final response = await EmploiDuTempsService.getAnneesByDepartement(departementId);
          setState(() {
            _annees = response;
          });
          print('✅ ${_annees.length} années chargées pour le département $departementId');
        } else {
          // Fallback : récupérer toutes les années disponibles
          final response = await EmploiDuTempsService.getAllAnnees();
          setState(() {
            _annees = response;
          });
          print('✅ ${_annees.length} années chargées (toutes)');
        }
      } else {
        throw Exception('Impossible de récupérer les infos utilisateur');
      }
    } catch (e) {
      print('❌ Erreur chargement années: $e');
      _showError('Impossible de charger les années');
    }
  }

  Future<void> _loadCompetences() async {
    try {
      // Appel API réel pour récupérer les compétences
      final competences = await EmploiDuTempsService.getCompetences();
      setState(() {
        _competences = competences;
      });
      print('✅ ${_competences.length} compétences chargées depuis l\'API');
    } catch (e) {
      print('❌ Erreur chargement compétences: $e');
      // Les compétences sont optionnelles, on peut continuer sans
      setState(() {
        _competences = [];
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_dateDebut ?? DateTime.now()) : (_dateFin ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
          // Si la date de fin est antérieure, l'ajuster
          if (_dateFin != null && _dateFin!.isBefore(picked)) {
            _dateFin = picked;
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_heureDebut ?? const TimeOfDay(hour: 8, minute: 0))
          : (_heureFin ?? const TimeOfDay(hour: 10, minute: 0)),
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

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _heureDebut = picked;
        } else {
          _heureFin = picked;
        }
      });
    }
  }

  void _selectCreneauPredefini(String debut, String fin) {
    final debutParts = debut.split(':');
    final finParts = fin.split(':');

    setState(() {
      _heureDebut = TimeOfDay(
        hour: int.parse(debutParts[0]),
        minute: int.parse(debutParts[1]),
      );
      _heureFin = TimeOfDay(
        hour: int.parse(finParts[0]),
        minute: int.parse(finParts[1]),
      );
    });
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _creerCreneau() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAnneeId == null) {
      _showError('Veuillez sélectionner une année');
      return;
    }

    if (_dateDebut == null || _dateFin == null) {
      _showError('Veuillez sélectionner les dates');
      return;
    }

    if (_heureDebut == null || _heureFin == null) {
      _showError('Veuillez sélectionner les heures');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('📝 Création créneau avec:');
      print('   - Année ID: $_selectedAnneeId');
      print('   - Date: ${_formatDate(_dateDebut)} → ${_formatDate(_dateFin)}');
      print('   - Heure: ${_formatTimeOfDay(_heureDebut)} → ${_formatTimeOfDay(_heureFin)}');
      print('   - Compétences: $_selectedCompetences');

      // 👈 CORRECTION : Utiliser les vraies valeurs du formulaire
      final result = await EmploiDuTempsService.creerCreneau(
        anneeId: _selectedAnneeId!,                    // 👈 Vraie année sélectionnée
        heureDebut: _formatTimeOfDay(_heureDebut!),    // 👈 Vraie heure de début
        heureFin: _formatTimeOfDay(_heureFin!),        // 👈 Vraie heure de fin
        dateDebut: _formatDate(_dateDebut!),           // 👈 Vraie date de début
        dateFin: _formatDate(_dateFin!),               // 👈 Vraie date de fin
        competences: _selectedCompetences.isNotEmpty   // 👈 Vraies compétences sélectionnées
            ? _selectedCompetences
            : null,
      );

      print('✅ Créneau créé: ${result['message']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(result['message'] ?? 'Créneau créé avec succès !'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Erreur création: $e');
      _showError('Erreur lors de la création: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Créer un créneau',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
            SizedBox(height: 16),
            Text('Chargement des données...'),
          ],
        ),
      )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug info
            if (_annees.isEmpty || _competences.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Années: ${_annees.length}, Compétences: ${_competences.length}',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),

            // Section Année
            _buildSection(
              title: '🎓 Année d\'étude',
              child: _buildAnneeSelector(),
            ),

            const SizedBox(height: 24),

            // Section Dates
            _buildSection(
              title: '📅 Période',
              child: _buildDateSelector(),
            ),

            const SizedBox(height: 24),

            // Section Heures avec créneaux prédéfinis
            _buildSection(
              title: '⏰ Horaires',
              child: Column(
                children: [
                  _buildCreneauxPredefinis(),
                  const SizedBox(height: 16),
                  _buildTimeSelector(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section Compétences (optionnel)
            if (_competences.isNotEmpty)
              _buildSection(
                title: '📚 Compétences (optionnel)',
                child: _buildCompetencesSelector(),
              ),

            const SizedBox(height: 32),

            // Bouton de création
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAnneeSelector() {
    if (_annees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Aucune année disponible. Vérifiez vos permissions.'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFAFAFA),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedAnneeId,
        decoration: const InputDecoration(
          hintText: 'Sélectionner une année',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(Icons.school_rounded, color: Color(0xFF3B82F6)),
        ),
        items: _annees.map((annee) {
          return DropdownMenuItem<int>(
            value: annee['id'],
            child: Text(annee['intitule'] ?? annee['nom'] ?? 'Année ${annee['id']}'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedAnneeId = value;
          });
          print('📚 Année sélectionnée: $value');
        },
        validator: (value) {
          if (value == null) {
            return 'Veuillez sélectionner une année';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            label: 'Date de début',
            date: _dateDebut,
            onTap: () => _selectDate(context, true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateField(
            label: 'Date de fin',
            date: _dateFin,
            onTap: () => _selectDate(context, false),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFFAFAFA),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 18, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Sélectionner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: date != null ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreneauxPredefinis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créneaux suggérés',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _creneauxPredefinis.map((creneau) {
            final isSelected = _heureDebut != null && _heureFin != null &&
                _formatTimeOfDay(_heureDebut) == '${creneau['debut']}:00' &&
                _formatTimeOfDay(_heureFin) == '${creneau['fin']}:00';

            return GestureDetector(
              onTap: () => _selectCreneauPredefini(creneau['debut']!, creneau['fin']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  creneau['nom']!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTimeField(
            label: 'Heure de début',
            time: _heureDebut,
            onTap: () => _selectTime(context, true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTimeField(
            label: 'Heure de fin',
            time: _heureFin,
            onTap: () => _selectTime(context, false),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFFAFAFA),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 18, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(
                  time != null
                      ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                      : 'Sélectionner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: time != null ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetencesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vous pouvez associer des compétences à ce créneau',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _competences.length,
            itemBuilder: (context, index) {
              final competence = _competences[index];
              final isSelected = _selectedCompetences.contains(competence['id']);

              return CheckboxListTile(
                title: Text(competence['nom'] ?? 'Compétence ${competence['id']}'),
                subtitle: Text(competence['code'] ?? ''),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedCompetences.add(competence['id']);
                    } else {
                      _selectedCompetences.remove(competence['id']);
                    }
                  });
                  print('🎯 Compétences sélectionnées: $_selectedCompetences');
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF3B82F6),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
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
        onPressed: _isLoading ? null : _creerCreneau,
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
              'Créer le créneau',
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
}