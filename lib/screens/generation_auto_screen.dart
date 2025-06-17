// lib/screens/generation_auto_screen.dart

import 'package:flutter/material.dart';
import '../services/emploi_du_temps_service.dart';
import '../services/departement_service.dart';

class GenerationAutoScreen extends StatefulWidget {
  const GenerationAutoScreen({Key? key}) : super(key: key);

  @override
  State<GenerationAutoScreen> createState() => _GenerationAutoScreenState();
}

class _GenerationAutoScreenState extends State<GenerationAutoScreen> with TickerProviderStateMixin {
  // Variables du formulaire
  int? _selectedDepartementId;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  // Données depuis l'API
  List<Map<String, dynamic>> _departements = [];

  // États de chargement et génération
  bool _isLoadingData = true;
  bool _isGenerating = false;
  Map<String, dynamic>? _resultGeneration;

  // Animations
  late AnimationController _progressController;
  late AnimationController _resultController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDepartements();
    _initializeDates();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _initializeDates() {
    final now = DateTime.now();
    _dateDebut = now;
    _dateFin = now.add(const Duration(days: 7)); // Une semaine par défaut
  }

  Future<void> _loadDepartements() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final departements = await DepartementService.getAllDepartements();
      setState(() {
        _departements = departements;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      _showError('Erreur lors du chargement des départements: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_dateDebut ?? DateTime.now()) : (_dateFin ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
          // Si la date de fin est antérieure, l'ajuster
          if (_dateFin != null && _dateFin!.isBefore(picked)) {
            _dateFin = picked.add(const Duration(days: 7));
          }
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _genererAutomatiquement() async {
    if (_selectedDepartementId == null) {
      _showError('Veuillez sélectionner un département');
      return;
    }

    if (_dateDebut == null || _dateFin == null) {
      _showError('Veuillez sélectionner les dates');
      return;
    }

    if (_dateFin!.isBefore(_dateDebut!)) {
      _showError('La date de fin doit être postérieure à la date de début');
      return;
    }

    setState(() {
      _isGenerating = true;
      _resultGeneration = null;
    });

    // Démarrer l'animation de progression
    _progressController.reset();
    _progressController.forward();

    try {
      final result = await EmploiDuTempsService.genererAutomatique(
        departementId: _selectedDepartementId!,
        dateDebut: _formatDate(_dateDebut),
        dateFin: _formatDate(_dateFin),
      );

      setState(() {
        _resultGeneration = result;
        _isGenerating = false;
      });

      // Démarrer l'animation de résultat
      _resultController.forward();

      if (result['success'] == true) {
        _showSuccess('Emploi du temps généré avec succès !');
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showError('Erreur lors de la génération: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Génération Automatique',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explication de la fonctionnalité
            _buildExplicationCard(),

            const SizedBox(height: 24),

            // Formulaire de configuration
            _buildConfigurationCard(),

            const SizedBox(height: 24),

            // Bouton de génération
            if (!_isGenerating && _resultGeneration == null)
              _buildGenerateButton(),

            // Indicateur de progression
            if (_isGenerating)
              _buildProgressIndicator(),

            // Résultats
            if (_resultGeneration != null)
              _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildExplicationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Intelligence Artificielle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Notre système IA va automatiquement créer l\'emploi du temps optimal en prenant en compte :',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          Column(
            children: [
              _buildFeatureItem('📚 Les compétences des formateurs'),
              _buildFeatureItem('🏫 La disponibilité des salles'),
              _buildFeatureItem('⏰ Les créneaux horaires optimaux'),
              _buildFeatureItem('🎯 L\'équilibre des charges de travail'),
              _buildFeatureItem('🔄 L\'évitement des conflits'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationCard() {
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
            const Text(
              '⚙️ Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 20),

            // Sélection du département
            _buildDepartementSelector(),

            const SizedBox(height: 20),

            // Sélection des dates
            _buildDateRangeSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartementSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Département',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFFAFAFA),
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedDepartementId,
            decoration: const InputDecoration(
              hintText: 'Sélectionner votre département',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(Icons.business_rounded, color: Color(0xFF10B981)),
            ),
            items: _departements.map((dept) {
              return DropdownMenuItem<int>(
                value: dept['id'],
                child: Text(dept['nom_departement'] ?? 'N/A'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDepartementId = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Période de génération',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Row(
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
        ),

        const SizedBox(height: 12),

        // Boutons rapides
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDateButton('Cette semaine', 7),
            _buildQuickDateButton('2 semaines', 14),
            _buildQuickDateButton('1 mois', 30),
          ],
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
                    size: 18, color: Color(0xFF10B981)),
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

  Widget _buildQuickDateButton(String label, int days) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _dateDebut = DateTime.now();
          _dateFin = DateTime.now().add(Duration(days: days));
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
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
        onPressed: _genererAutomatiquement,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Générer automatiquement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 48,
            color: Color(0xFF10B981),
          ),

          const SizedBox(height: 16),

          const Text(
            'Génération en cours...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'L\'IA analyse les contraintes et optimise l\'emploi du temps',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_progressAnimation.value * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: Color(0xFF10B981),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Génération terminée !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _resultGeneration?['message'] ?? 'Emploi du temps généré avec succès',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Voir l\'emploi du temps'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _resultGeneration = null;
                      });
                      _resultController.reset();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Générer à nouveau'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}