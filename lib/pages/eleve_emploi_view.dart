import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/emploi_du_temps_service.dart';
import '../services/user_service.dart';

class EleveEmploiView extends StatefulWidget {
  const EleveEmploiView({Key? key}) : super(key: key);

  @override
  State<EleveEmploiView> createState() => _EleveEmploiViewState();
}

class _EleveEmploiViewState extends State<EleveEmploiView> {
  // 🔥 DONNÉES OPTIMISÉES
  List<Map<String, dynamic>> emplois = [];
  Map<String, dynamic>? eleveData;
  Map<String, dynamic>? user;
  int? eleveMetierId;
  bool isLoading = true;
  DateTime selectedWeek = DateTime.now();
  String typeAffichage = 'semaine';

  // 🔥 CACHE INTELLIGENT POUR COULEURS
  final Map<String, Color> _couleursCache = {};
  final Map<String, Map<String, dynamic>?> _coursCache = {}; // Cache des cours par slot
  String? _lastCacheKey; // Pour invalidation intelligente

  final List<String> creneauxHoraires = [
    '8h - 9h', '9h - 10h', '10h - 11h', '11h - 12h',
    '12h - 13h', '13h - 14h', '14h - 15h', '15h - 16h', '16h - 17h',
  ];

  final List<String> joursSemai = [
    'LUNDI', 'MARDI', 'MERCREDI', 'JEUDI', 'VENDREDI', 'SAMEDI'
  ];

  final List<Color> _paletteColors = [
    const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFFBBF24),
    const Color(0xFF8B5CF6), const Color(0xFFEC4899), const Color(0xFF06B6D4),
    const Color(0xFF84CC16), const Color(0xFF6366F1),
  ];

  @override
  void initState() {
    super.initState();
    _initializeWeek();
    _loadData();
  }

  void _initializeWeek() {
    final now = DateTime.now();
    selectedWeek = now.subtract(Duration(days: now.weekday - 1));
  }

  /// 🔥 CHARGEMENT OPTIMISÉ AVEC CACHE
  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      // 🔥 INVALIDATION CACHE INTELLIGENTE
      final newCacheKey = _generateCacheKey();
      if (_lastCacheKey != newCacheKey) {
        _invalidateCache();
        _lastCacheKey = newCacheKey;
      }

      // 1. Charger données utilisateur (avec cache SharedPreferences)
      await _loadUserData();

      // 2. Charger données élève (avec cache service)
      await _loadEleveData();

      // 3. 🔥 CHARGEMENT OPTIMISÉ AVEC DATES
      final dateDebut = _formatDateForApi(selectedWeek);
      final dateFin = _formatDateForApi(selectedWeek.add(const Duration(days: 6)));

      final emploisResult = await EmploiDuTempsService.getEmploisEleve(
        dateDebut: dateDebut,
        dateFin: dateFin,
        perPage: 50,
      );

      setState(() {
        emplois = emploisResult;
        isLoading = false;
      });

      print('✅ ${emplois.length} emplois chargés pour l\'élève (${dateDebut} à ${dateFin})');

    } catch (e) {
      setState(() => isLoading = false);
      _showError('Erreur de chargement: $e');
    }
  }

  /// 🔥 GÉNÉRATION CLÉ CACHE INTELLIGENTE
  String _generateCacheKey() {
    final weekStart = _formatDateForApi(selectedWeek);
    return '${typeAffichage}_${weekStart}_${eleveMetierId ?? 'no_metier'}';
  }

  /// 🔥 INVALIDATION CACHE CIBLÉE
  void _invalidateCache() {
    _coursCache.clear();
    _couleursCache.clear();
    print('🧹 Cache invalidé pour nouvelle période/vue');
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData != null) {
      setState(() {
        user = jsonDecode(userData);
      });
    }
  }

  Future<void> _loadEleveData() async {
    if (user != null && user!['id'] != null) {
      final result = await UserService.getEleveByUserId(user!['id']);

      if (result['success'] && result['data'] != null) {
        setState(() {
          eleveData = result['data'];
          eleveMetierId = eleveData?['metier']?['id'];
        });
      }
    }
  }

  /// 🔥 FILTRAGE OPTIMISÉ AVEC CACHE
  Map<String, dynamic>? _getCoursForSlot(String jour, String creneau) {
    final slotKey = '${jour}_${creneau}';

    // 🔥 VÉRIFIER CACHE D'ABORD
    if (_coursCache.containsKey(slotKey)) {
      return _coursCache[slotKey];
    }

    final jourIndex = joursSemai.indexOf(jour);
    if (jourIndex == -1) {
      _coursCache[slotKey] = null;
      return null;
    }

    // Gestion pause déjeuner
    if (creneau == '13h - 14h') {
      final pauseData = {'type': 'pause'};
      _coursCache[slotKey] = pauseData;
      return pauseData;
    }

    // 🔥 CALCUL OPTIMISÉ DE LA DATE
    DateTime dateRealDuJour;
    if (typeAffichage == 'jour') {
      dateRealDuJour = selectedWeek;
    } else {
      dateRealDuJour = selectedWeek.add(Duration(days: jourIndex));
    }

    final heureCreneauDebut = int.tryParse(creneau.split('h')[0]) ?? 0;

    // 🔥 RECHERCHE OPTIMISÉE
    Map<String, dynamic>? coursCorrespondant = _findMatchingCours(
        dateRealDuJour,
        heureCreneauDebut
    );

    // 🔥 MISE EN CACHE
    _coursCache[slotKey] = coursCorrespondant;
    return coursCorrespondant;
  }

  /// 🔥 RECHERCHE COURS OPTIMISÉE
  Map<String, dynamic>? _findMatchingCours(DateTime dateRecherce, int heureCreneauDebut) {
    for (var emploi in emplois) {
      try {
        final dateEmploi = DateTime.tryParse(emploi['date_debut'] ?? '');
        if (dateEmploi == null || !_sameDay(dateEmploi, dateRecherce)) continue;

        // 🔥 PARSING HEURE OPTIMISÉ
        final heureDebutStr = emploi['heure_debut']?.toString() ?? '';
        final heureFinStr = emploi['heure_fin']?.toString() ?? '';

        if (heureDebutStr.isEmpty) continue;

        final heureEmploiDebut = _parseHeure(heureDebutStr);
        final heureEmploiFin = _parseHeure(heureFinStr);

        // Vérifier si le créneau correspond
        if (heureCreneauDebut >= heureEmploiDebut && heureCreneauDebut < heureEmploiFin) {
          // 🔥 FILTRAGE MÉTIER OPTIMISÉ
          if (_isCoursValidePourEleve(emploi)) {
            return emploi;
          }
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// 🔥 PARSING HEURE OPTIMISÉ
  int _parseHeure(String heureStr) {
    if (heureStr.contains('T')) {
      return int.tryParse(heureStr.split('T')[1].substring(0, 2)) ?? 0;
    } else {
      return int.tryParse(heureStr.split(':')[0]) ?? 0;
    }
  }

  /// 🔥 VALIDATION COURS POUR ÉLÈVE OPTIMISÉE
  bool _isCoursValidePourEleve(Map<String, dynamic> emploi) {
    final competences = emploi['competences'] as List<dynamic>? ?? [];

    if (competences.isEmpty) return true; // Cours commun

    for (var competence in competences) {
      final metierCours = competence['metier'];
      if (metierCours == null) return true; // Cours commun

      if (eleveMetierId != null && metierCours['id'] == eleveMetierId) {
        return true; // Cours pour ce métier
      }
    }
    return false;
  }

  bool _sameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 🔥 COULEUR COURS AVEC CACHE INTELLIGENT
  Color _getCouleurCours(Map<String, dynamic> emploi) {
    if (emploi['type'] == 'pause') return const Color(0xFF6B7280);
    if (emploi['type'] == 'ferie') return const Color(0xFFEF4444);

    final competences = emploi['competences'] as List<dynamic>? ?? [];
    if (competences.isEmpty) return Colors.grey.shade300;

    final premierCours = competences[0];

    // 🔥 CLÉ CACHE OPTIMISÉE
    final cleUnique = '${premierCours['id']}_${premierCours['code']}'.hashCode.toString();

    if (_couleursCache.containsKey(cleUnique)) {
      return _couleursCache[cleUnique]!;
    }

    // 🔥 GÉNÉRATION COULEUR DÉTERMINISTE
    final hashCode = cleUnique.hashCode.abs();
    final colorIndex = hashCode % _paletteColors.length;
    final couleur = _paletteColors[colorIndex];

    _couleursCache[cleUnique] = couleur;
    return couleur;
  }

  /// 🔥 CHANGEMENT DE PÉRIODE OPTIMISÉ
  void _changerPeriode(int delta) {
    setState(() {
      if (typeAffichage == 'semaine') {
        selectedWeek = selectedWeek.add(Duration(days: 7 * delta));
      } else {
        selectedWeek = selectedWeek.add(Duration(days: delta));
      }
    });

    // 🔥 RECHARGEMENT INTELLIGENT (seulement si nécessaire)
    _loadDataIfNeeded();
  }

  /// 🔥 CHARGEMENT CONDITIONNEL
  Future<void> _loadDataIfNeeded() async {
    final newCacheKey = _generateCacheKey();
    if (_lastCacheKey != newCacheKey) {
      await _loadData();
    }
  }

  /// 🔥 CHANGEMENT MODE VUE OPTIMISÉ
  void _changerModeVue() {
    setState(() {
      typeAffichage = typeAffichage == 'semaine' ? 'jour' : 'semaine';
      final now = DateTime.now();

      if (typeAffichage == 'jour') {
        selectedWeek = now;
      } else {
        selectedWeek = now.subtract(Duration(days: now.weekday - 1));
      }
    });

    // 🔥 INVALIDATION ET RECHARGEMENT
    _invalidateCache();
    _loadData();
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mon Emploi du Temps',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(typeAffichage == 'semaine' ? Icons.view_day : Icons.view_week),
            onPressed: _changerModeVue,
            tooltip: typeAffichage == 'semaine' ? 'Vue jour' : 'Vue semaine',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _invalidateCache();
              _loadData();
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: SpinKitWave(
          color: Color(0xFF3B82F6),
          size: 30.0,
        ),
      )
          : Column(
        children: [
          _buildHeader(),
          _buildControls(),
          Expanded(child: _buildGrilleEmploi()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String metierInfo = '';
    String anneeInfo = '';

    if (eleveData != null) {
      metierInfo = eleveData!['metier']?['intitule'] ?? 'Non défini';

      // 🔥 OPTIMISATION : Chercher l'année dans les emplois cachés
      final emploisEleve = emplois.where((emploi) {
        return _isCoursValidePourEleve(emploi);
      }).toList();

      if (emploisEleve.isNotEmpty) {
        final annee = emploisEleve.first['annee'];
        if (annee != null) {
          anneeInfo = annee['intitule'] ?? 'N/A';
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF1E40AF),
          ],
        ),
      ),
      child: Column(
        children: [
          if (metierInfo.isNotEmpty) ...[
            Text(
              'FILIÈRE: ${metierInfo.toUpperCase()}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (anneeInfo.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Classe: $anneeInfo',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

          // 🔥 AJOUT : Info cache
          if (_coursCache.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade600.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '📦 ${_coursCache.length} créneaux en cache',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Boutons de navigation
          Row(
            children: [
              IconButton(
                onPressed: () => _changerPeriode(-1),
                icon: const Icon(Icons.chevron_left),
                tooltip: typeAffichage == 'semaine' ? 'Semaine précédente' : 'Jour précédent',
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeAffichage == 'semaine'
                        ? 'Semaine du ${_formatDateDisplay(selectedWeek)}'
                        : _formatDateDisplay(selectedWeek),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ),

              IconButton(
                onPressed: () => _changerPeriode(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: typeAffichage == 'semaine' ? 'Semaine suivante' : 'Jour suivant',
              ),
            ],
          ),

          // Bouton retour aujourd'hui
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                final now = DateTime.now();
                if (typeAffichage == 'semaine') {
                  selectedWeek = now.subtract(Duration(days: now.weekday - 1));
                } else {
                  selectedWeek = now;
                }
              });
              _invalidateCache();
              _loadData();
            },
            icon: const Icon(Icons.today, size: 16),
            label: const Text('Auj'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrilleEmploi() {
    if (typeAffichage == 'jour') {
      return _buildVueJour();
    } else {
      return _buildVueSemaine();
    }
  }

  /// 🔥 VUE JOUR OPTIMISÉE
  Widget _buildVueJour() {
    final jourIndex = selectedWeek.weekday - 1;
    final nomJour = jourIndex < joursSemai.length ? joursSemai[jourIndex] : 'DIMANCHE';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Header du jour
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Center(
                child: Text(
                  '$nomJour ${_formatDateDisplay(selectedWeek)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // 🔥 OPTIMISATION : Générer les créneaux une seule fois
            ..._buildCreneauxJour(nomJour),
          ],
        ),
      ),
    );
  }

  /// 🔥 GÉNÉRATION CRÉNEAUX OPTIMISÉE
  List<Widget> _buildCreneauxJour(String nomJour) {
    return creneauxHoraires.map((creneau) {
      final cours = _getCoursForSlot(nomJour, creneau);
      return _buildCreneauJour(creneau, cours);
    }).toList();
  }

  Widget _buildCreneauJour(String creneau, Map<String, dynamic>? cours) {
    bool isPause = creneau == '13h - 14h';
    Color couleur = cours != null ? _getCouleurCours(cours) : Colors.white;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: couleur,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Heure
            Container(
              width: 80,
              child: Text(
                creneau,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isPause ? Colors.grey.shade600 : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Contenu du cours
            Expanded(
              child: cours != null ? _buildCoursContent(cours, isPause) : Container(),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 VUE SEMAINE OPTIMISÉE
  Widget _buildVueSemaine() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderRow(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildCreneauxSemaine(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 GÉNÉRATION CRÉNEAUX SEMAINE OPTIMISÉE
  List<Widget> _buildCreneauxSemaine() {
    return creneauxHoraires.map((creneau) {
      return _buildCreneauRow(creneau);
    }).toList();
  }

  Widget _buildHeaderRow() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade400, width: 2)),
            ),
            child: const Text(
              'Horaires',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ...joursSemai.map((jour) {
            return Container(
              width: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade400, width: 1)),
              ),
              child: Text(
                jour,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCreneauRow(String creneau) {
    bool isPause = creneau == '13h - 14h';

    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPause ? Colors.grey.shade200 : Colors.grey.shade100,
              border: Border(right: BorderSide(color: Colors.grey.shade400, width: 2)),
            ),
            child: Text(
              creneau,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: isPause ? Colors.grey.shade600 : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 🔥 OPTIMISATION : Générer cellules en une passe
          ..._buildCellsForCreneau(creneau, isPause),
        ],
      ),
    );
  }

  /// 🔥 GÉNÉRATION CELLULES OPTIMISÉE
  List<Widget> _buildCellsForCreneau(String creneau, bool isPause) {
    return joursSemai.map((jour) {
      final cours = isPause ? {'type': 'pause'} : _getCoursForSlot(jour, creneau);
      return _buildCoursCell(cours, isPause);
    }).toList();
  }

  Widget _buildCoursCell(Map<String, dynamic>? cours, bool isPause) {
    Color couleur = cours != null ? _getCouleurCours(cours) : Colors.white;

    return Container(
      width: 140,
      height: 80,
      decoration: BoxDecoration(
        color: couleur,
        border: Border(right: BorderSide(color: Colors.grey.shade400)),
      ),
      child: cours != null ? _buildCoursContent(cours, isPause) : null,
    );
  }

  /// 🔥 CONTENU COURS OPTIMISÉ
  Widget _buildCoursContent(Map<String, dynamic> cours, bool isPause) {
    if (isPause) {
      return const Center(
        child: Text(
          'PAUSE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    final competences = cours['competences'] as List<dynamic>? ?? [];
    if (competences.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(4),
        child: const Center(
          child: Text(
            'Cours\nLibre',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final premierCours = competences[0];
    final nomCours = premierCours['nom']?.toString() ?? '';
    final codeCours = premierCours['code']?.toString() ?? '';
    final salle = premierCours['salle'] ?? {};
    final nomSalle = salle['intitule']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            nomCours.isNotEmpty ? nomCours.toUpperCase() : codeCours.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (nomSalle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              nomSalle,
              style: const TextStyle(
                fontSize: 8,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 🔥 NETTOYAGE MÉMOIRE
    _coursCache.clear();
    _couleursCache.clear();
    super.dispose();
  }
}