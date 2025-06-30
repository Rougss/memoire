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
  List<Map<String, dynamic>> emplois = [];
  Map<String, dynamic>? eleveData;
  Map<String, dynamic>? user;
  int? eleveMetierId;
  bool isLoading = true;
  DateTime selectedWeek = DateTime.now();
  String typeAffichage = 'semaine'; // 'jour' ou 'semaine'

  final List<String> creneauxHoraires = [
    '8h - 9h',
    '9h - 10h',
    '10h - 11h',
    '11h - 12h',
    '12h - 13h',
    '13h - 14h', // PAUSE
    '14h - 15h',
    '15h - 16h',
    '16h - 17h',
  ];

  final List<String> joursSemai = [
    'LUNDI', 'MARDI', 'MERCREDI', 'JEUDI', 'VENDREDI', 'SAMEDI'
  ];

  Map<String, Color> _couleursCache = {};
  final List<Color> _paletteColors = [
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFFBBF24),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF06B6D4),
    const Color(0xFF84CC16),
    const Color(0xFF6366F1),
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

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      // 🔥 NETTOYER LES CACHES AVANT DE RECHARGER
      _couleursCache.clear();
      emplois.clear();

      print('🧹 Cache nettoyé - Rechargement des données...');

      // 1. Récupérer les données utilisateur depuis SharedPreferences
      await _loadUserData();

      // 2. Récupérer les données spécifiques de l'élève
      await _loadEleveData();

      // 3. Récupérer tous les emplois du temps
      final emploisResult = await EmploiDuTempsService.getEmploisEleve();

      setState(() {
        emplois = emploisResult;
        isLoading = false;
      });

      print('✅ ${emplois.length} emplois chargés pour l\'élève');
      print('🎯 Métier élève ID: $eleveMetierId');

    } catch (e) {
      setState(() => isLoading = false);
      _showError('Erreur de chargement: $e');
    }
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
          // Récupérer l'ID du métier/filière de l'élève
          eleveMetierId = eleveData?['metier']?['id'];
        });
      }
    }
  }

  // 🎯 FILTRAGE PAR FILIÈRE DE L'ÉLÈVE - VERSION CORRIGÉE
  Map<String, dynamic>? _getCoursForSlot(String jour, String creneau) {
    final jourIndex = joursSemai.indexOf(jour);
    if (jourIndex == -1) return null;

    // 🔥 CALCULER LA DATE RÉELLE DU JOUR
    DateTime dateRealDuJour;
    if (typeAffichage == 'jour') {
      // En mode jour, selectedWeek contient déjà la date exacte du jour affiché
      dateRealDuJour = selectedWeek;
    } else {
      // En mode semaine, calculer la date à partir du lundi (selectedWeek)
      dateRealDuJour = selectedWeek.add(Duration(days: jourIndex));
    }

    final dateString = _formatDateDisplay(dateRealDuJour);
    print('🔍 Recherche cours pour: $jour ($dateString) à $creneau');

    // Extraire l'heure du créneau
    final heureCreneauDebut = int.tryParse(creneau.split('h')[0]) ?? 0;

    // Gérer la pause déjeuner
    if (creneau == '13h - 14h') {
      return {'type': 'pause'};
    }

    // 🔥 RECHERCHE DANS LES EMPLOIS - LOGIQUE STRICTE
    Map<String, dynamic>? coursCorrespondant;

    for (var emploi in emplois) {
      try {
        final dateEmploi = DateTime.tryParse(emploi['date_debut'] ?? '');
        if (dateEmploi == null) {
          print('❌ Date emploi invalide: ${emploi['date_debut']}');
          continue;
        }

        // 🔥 VÉRIFICATION STRICTE DE LA DATE
        if (!_sameDay(dateEmploi, dateRealDuJour)) {
          continue; // Pas le bon jour
        }

        print('📅 Emploi trouvé pour le bon jour: ${_formatDateDisplay(dateEmploi)}');

        // Extraire heures de début et fin
        final heureDebutStr = emploi['heure_debut']?.toString() ?? '';
        final heureFinStr = emploi['heure_fin']?.toString() ?? '';

        if (heureDebutStr.isEmpty || heureFinStr.isEmpty) {
          print('❌ Heures manquantes pour emploi ${emploi['id']}');
          continue;
        }

        int heureEmploiDebut, heureEmploiFin;

        if (heureDebutStr.contains('T')) {
          heureEmploiDebut = int.tryParse(heureDebutStr.split('T')[1].substring(0, 2)) ?? 0;
          heureEmploiFin = int.tryParse(heureFinStr.split('T')[1].substring(0, 2)) ?? 0;
        } else {
          heureEmploiDebut = int.tryParse(heureDebutStr.split(':')[0]) ?? 0;
          heureEmploiFin = int.tryParse(heureFinStr.split(':')[0]) ?? 0;
        }

        print('⏰ Vérification horaire: $heureCreneauDebut dans [$heureEmploiDebut-$heureEmploiFin]');

        // Vérifier si le créneau est couvert par ce cours
        if (heureCreneauDebut >= heureEmploiDebut && heureCreneauDebut < heureEmploiFin) {
          print('✅ Horaire correspond !');

          // 🎯 FILTRAGE PAR FILIÈRE DE L'ÉLÈVE
          final competences = emploi['competences'] as List<dynamic>? ?? [];
          bool coursValidePourEleve = false;

          if (competences.isEmpty) {
            print('📝 Cours sans compétences = cours commun');
            coursValidePourEleve = true;
          } else {
            for (var competence in competences) {
              final metierCours = competence['metier'];

              if (metierCours == null) {
                print('📝 Compétence sans métier = cours commun');
                coursValidePourEleve = true;
                break;
              } else if (eleveMetierId != null && metierCours['id'] == eleveMetierId) {
                print('🎯 Cours pour le métier ${metierCours['intitule']} = MATCH !');
                coursValidePourEleve = true;
                break;
              } else {
                print('❌ Cours pour métier ${metierCours['intitule']} (ID: ${metierCours['id']}) ≠ élève métier (ID: $eleveMetierId)');
              }
            }
          }

          if (coursValidePourEleve) {
            final coursNom = competences.isNotEmpty ? competences[0]['nom'] : 'Cours libre';
            print('✅ COURS TROUVÉ: $coursNom');
            coursCorrespondant = emploi;
            break; // Prendre le premier cours trouvé
          } else {
            print('❌ Cours pas pour cette filière');
          }
        } else {
          print('❌ Horaire ne correspond pas');
        }

      } catch (e) {
        print('❌ Erreur traitement emploi ${emploi['id']}: $e');
        continue;
      }
    }

    if (coursCorrespondant == null) {
      print('🔍 Aucun cours trouvé pour $jour ($dateString) à $creneau');
    }

    return coursCorrespondant;
  }

  bool _sameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Color _getCouleurCours(Map<String, dynamic> emploi) {
    if (emploi['type'] == 'pause') {
      return const Color(0xFF6B7280);
    }

    if (emploi['type'] == 'ferie') {
      return const Color(0xFFEF4444);
    }

    final competences = emploi['competences'] as List<dynamic>? ?? [];
    if (competences.isEmpty) return Colors.grey.shade300;

    final premierCours = competences[0];
    final competenceId = premierCours['id']?.toString() ?? '';
    final codeCours = premierCours['code']?.toString() ?? '';
    final nomCours = premierCours['nom']?.toString() ?? '';

    final cleUnique = '$competenceId-$codeCours-$nomCours';

    if (_couleursCache.containsKey(cleUnique)) {
      return _couleursCache[cleUnique]!;
    }

    final hashCode = cleUnique.hashCode.abs();
    final colorIndex = hashCode % _paletteColors.length;
    final couleur = _paletteColors[colorIndex];

    _couleursCache[cleUnique] = couleur;
    return couleur;
  }

  String _formatDateDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
            onPressed: () {
              setState(() {
                typeAffichage = typeAffichage == 'semaine' ? 'jour' : 'semaine';
                // 🔥 RECALCULER LA DATE SELON LE NOUVEAU MODE
                final now = DateTime.now();
                if (typeAffichage == 'jour') {
                  // Passer en mode jour = afficher aujourd'hui
                  selectedWeek = now;
                } else {
                  // Passer en mode semaine = afficher la semaine actuelle
                  selectedWeek = now.subtract(Duration(days: now.weekday - 1));
                }
                // 🔥 FORCER LE REBUILD COMPLET
                _forceRebuild();
              });
            },
            tooltip: typeAffichage == 'semaine' ? 'Vue jour' : 'Vue semaine',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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

      // Récupérer l'année depuis les emplois filtrés
      final emploisEleve = emplois.where((emploi) {
        final competences = emploi['competences'] as List<dynamic>? ?? [];
        for (var competence in competences) {
          final metierCours = competence['metier'];
          if (metierCours != null && metierCours['id'] == eleveMetierId) {
            return true;
          }
        }
        return false;
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
                onPressed: () {
                  setState(() {
                    if (typeAffichage == 'semaine') {
                      selectedWeek = selectedWeek.subtract(const Duration(days: 7));
                    } else {
                      selectedWeek = selectedWeek.subtract(const Duration(days: 1));
                    }
                    // 🔥 FORCER LE REBUILD COMPLET
                    _forceRebuild();
                  });
                },
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
                onPressed: () {
                  setState(() {
                    if (typeAffichage == 'semaine') {
                      selectedWeek = selectedWeek.add(const Duration(days: 7));
                    } else {
                      selectedWeek = selectedWeek.add(const Duration(days: 1));
                    }
                    // 🔥 FORCER LE REBUILD COMPLET
                    _forceRebuild();
                  });
                },
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
                // 🔥 FORCER LE REBUILD COMPLET
                _forceRebuild();
              });
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

  // 🔥 MÉTHODE POUR FORCER LE REBUILD COMPLET
  void _forceRebuild() {
    // Nettoyer TOUT
    _couleursCache.clear();

    // Marquer comme nécessitant un rebuild
    if (mounted) {
      setState(() {
        // Force la reconstruction complète du widget
      });
    }

    print('🔄 REBUILD FORCÉ - Cache nettoyé pour la nouvelle période');
    print('📅 Nouvelle période: ${_formatDateDisplay(selectedWeek)} (${typeAffichage})');
  }

  Widget _buildGrilleEmploi() {
    if (typeAffichage == 'jour') {
      return _buildVueJour();
    } else {
      return _buildVueSemaine();
    }
  }

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
            // Créneaux du jour
            ...creneauxHoraires.map((creneau) {
              final cours = _getCoursForSlot(nomJour, creneau);
              return _buildCreneauJour(creneau, cours);
            }).toList(),
          ],
        ),
      ),
    );
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
                  children: creneauxHoraires.map((creneau) {
                    return _buildCreneauRow(creneau);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          ...joursSemai.map((jour) {
            final cours = isPause ? {'type': 'pause'} : _getCoursForSlot(jour, creneau);
            return _buildCoursCell(cours, isPause);
          }).toList(),
        ],
      ),
    );
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
}