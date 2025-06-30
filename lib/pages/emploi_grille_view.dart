import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/emploi_du_temps_service.dart';


class EmploiGrilleView extends StatefulWidget {
  const EmploiGrilleView({Key? key}) : super(key: key);

  @override
  State<EmploiGrilleView> createState() => _EmploiGrilleViewState();
}

class _EmploiGrilleViewState extends State<EmploiGrilleView> {
  List<Map<String, dynamic>> emplois = [];
  List<Map<String, dynamic>> annees = [];
  Map<String, dynamic>? selectedAnnee;
  bool isLoading = true;
  DateTime selectedWeek = DateTime.now();
  Map<String, dynamic>? selectedMetier;
  List<Map<String, dynamic>> metiersDuDepartement = [];

  // 🆕 VARIABLES DRAG & DROP
  Map<String, dynamic>? _draggedCours;
  String? _draggedFromSlot;
  bool _isDragging = false;
  String? _hoveredSlot;

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

  void _loadMetiersDuDepartement() {
    print('🔍 Chargement des métiers pour l\'année: ${selectedAnnee?['intitule']}');

    Set<Map<String, dynamic>> metiersUniques = {};
    int emploisAnalyses = 0;

    for (var emploi in emplois) {
      final anneeEmploi = emploi['annee'];
      if (selectedAnnee != null && anneeEmploi != null) {
        if (anneeEmploi['id'] == selectedAnnee!['id']) {
          emploisAnalyses++;
          final competences = emploi['competences'] as List<dynamic>? ?? [];
          print('📋 Emploi ${emploi['id']} - ${competences.length} compétences');

          for (var competence in competences) {
            final metier = competence['metier'];
            if (metier != null) {
              print('🎯 Métier trouvé: ${metier['intitule']} (ID: ${metier['id']})');

              bool dejaPresent = metiersUniques.any((m) => m['id'] == metier['id']);
              if (!dejaPresent) {
                metiersUniques.add({
                  'id': metier['id'],
                  'intitule': metier['intitule'],
                  'departement': metier['departement'],
                });
                print('✅ Nouveau métier ajouté: ${metier['intitule']}');
              } else {
                print('⚠️ Métier déjà présent: ${metier['intitule']}');
              }
            } else {
              print('❌ Compétence sans métier: ${competence['nom']}');
            }
          }
        }
      }
    }

    print('📊 RÉSULTATS:');
    print('   - Emplois analysés: $emploisAnalyses');
    print('   - Métiers uniques trouvés: ${metiersUniques.length}');
    for (var metier in metiersUniques) {
      print('   - ${metier['intitule']} (ID: ${metier['id']})');
    }

    setState(() {
      metiersDuDepartement = metiersUniques.toList();
      if (metiersDuDepartement.isNotEmpty && selectedMetier == null) {
        selectedMetier = metiersDuDepartement.first;
        print('🎯 Métier auto-sélectionné: ${selectedMetier!['intitule']}');
      }
    });
  }

  // 🆕 Méthode mise à jour pour filtrer par métier ET année
  List<Map<String, dynamic>> _getEmploisFiltres() {
    return emplois.where((emploi) {
      // Filtre par année
      final anneeEmploi = emploi['annee'];
      if (selectedAnnee != null && anneeEmploi != null) {
        if (anneeEmploi['id'] != selectedAnnee!['id']) return false;
      }

      // Filtre par métier si sélectionné
      if (selectedMetier != null) {
        final competences = emploi['competences'] as List<dynamic>? ?? [];
        bool contientMetier = competences.any((competence) {
          final metier = competence['metier'];
          return metier != null && metier['id'] == selectedMetier!['id'];
        });
        if (!contientMetier) return false;
      }

      return true;
    }).toList();
  }


  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        EmploiDuTempsService.getAllAnnees(),
        EmploiDuTempsService.getAllEmplois(),
      ]);

      setState(() {
        annees = results[0];
        emplois = results[1];

        if (annees.isNotEmpty) {
          selectedAnnee = annees.first;
        }

        isLoading = false;
      });

      // 🆕 Charger les métiers après avoir chargé les données
      _loadMetiersDuDepartement();

      print('✅ ${emplois.length} emplois chargés pour la grille');
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Erreur de chargement: $e');
    }
  }

  Map<String, dynamic>? _getCoursForSlot(String jour, String creneau) {
    final jourIndex = joursSemai.indexOf(jour);
    if (jourIndex == -1) return null;

    final dateRealDuJour = selectedWeek.add(Duration(days: jourIndex));
    final heureCreneauDebut = int.tryParse(creneau.split('h')[0]) ?? 0;

    if (creneau == '13h - 14h') {
      return {'type': 'pause'};
    }

    // 🆕 Utiliser les emplois filtrés au lieu de tous les emplois
    final emploisFiltres = _getEmploisFiltres();

    for (var emploi in emploisFiltres) {
      try {
        final dateEmploi = DateTime.tryParse(emploi['date_debut'] ?? '');
        if (dateEmploi == null) continue;

        if (!_sameDay(dateEmploi, dateRealDuJour)) continue;

        final heureDebutStr = emploi['heure_debut']?.toString() ?? '';
        final heureFinStr = emploi['heure_fin']?.toString() ?? '';

        if (heureDebutStr.isEmpty || heureFinStr.isEmpty) continue;

        int heureEmploiDebut, heureEmploiFin;

        if (heureDebutStr.contains('T')) {
          heureEmploiDebut = int.tryParse(heureDebutStr.split('T')[1].substring(0, 2)) ?? 0;
          heureEmploiFin = int.tryParse(heureFinStr.split('T')[1].substring(0, 2)) ?? 0;
        } else {
          heureEmploiDebut = int.tryParse(heureDebutStr.split(':')[0]) ?? 0;
          heureEmploiFin = int.tryParse(heureFinStr.split(':')[0]) ?? 0;
        }

        if (heureCreneauDebut >= heureEmploiDebut && heureCreneauDebut < heureEmploiFin) {
          return emploi;
        }

      } catch (e) {
        print('Erreur traitement emploi: $e');
        continue;
      }
    }

    return null;
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

  // 🆕 GÉNÉRER UNE CLÉ UNIQUE POUR CHAQUE SLOT
  String _getSlotKey(String jour, String creneau) {
    // 🔧 UTILISER UN SÉPARATEUR UNIQUE : double underscore
    final creneauClean = creneau.replaceAll(' ', '').replaceAll('-', '').replaceAll('h', 'H');
    return '${jour}__$creneauClean'; // Double underscore comme séparateur
  }

  // 🆕 OBTENIR LA DATE ET HEURE D'UN SLOT
  Map<String, String> _getSlotDateTime(String jour, String creneau) {
    final jourIndex = joursSemai.indexOf(jour);
    final dateRealDuJour = selectedWeek.add(Duration(days: jourIndex));
    final heureDebut = int.tryParse(creneau.split('h')[0]) ?? 0;

    return {
      'date': '${dateRealDuJour.year}-${dateRealDuJour.month.toString().padLeft(2, '0')}-${dateRealDuJour.day.toString().padLeft(2, '0')}',
      'heure_debut': '${heureDebut.toString().padLeft(2, '0')}:00:00',
      'heure_fin': '${(heureDebut + 1).toString().padLeft(2, '0')}:00:00',
    };
  }

  // 🎯 DÉPLACER UN COURS
  Future<void> _deplacerCours(Map<String, dynamic> cours, String targetSlot) async {
    print('🎯 _deplacerCours appelé avec cours: ${cours['id']}, target: $targetSlot');

    if (cours['type'] == 'pause') {
      print('❌ Tentative de déplacer une pause');
      return;
    }

    // 🔧 CORRECTION : Parser le nouveau format JOUR__HhHh avec double underscore
    final targetParts = targetSlot.split('__'); // Utiliser __ comme dans _getSlotKey()
    if (targetParts.length != 2) {
      print('❌ Format targetSlot invalide: $targetSlot, parts: $targetParts');
      return;
    }

    final targetJour = targetParts[0];
    final targetCreneauClean = targetParts[1]; // ex: "8H9H"

    // 🔧 RECONSTITUER LE CRÉNEAU ORIGINAL
    String targetCreneau = '';
    if (targetCreneauClean == '8H9H') targetCreneau = '8h - 9h';
    else if (targetCreneauClean == '9H10H') targetCreneau = '9h - 10h';
    else if (targetCreneauClean == '10H11H') targetCreneau = '10h - 11h';
    else if (targetCreneauClean == '11H12H') targetCreneau = '11h - 12h';
    else if (targetCreneauClean == '12H13H') targetCreneau = '12h - 13h';
    else if (targetCreneauClean == '13H14H') targetCreneau = '13h - 14h';
    else if (targetCreneauClean == '14H15H') targetCreneau = '14h - 15h';
    else if (targetCreneauClean == '15H16H') targetCreneau = '15h - 16h';
    else if (targetCreneauClean == '16H17H') targetCreneau = '16h - 17h';
    else {
      print('❌ Créneau non reconnu: $targetCreneauClean');
      return;
    }

    print('🎯 Jour: $targetJour, Créneau: $targetCreneau');

    // Vérifier si c'est la pause déjeuner
    if (targetCreneau == '13h - 14h') {
      print('❌ Tentative de placement pendant la pause');
      _showError('Impossible de placer un cours pendant la pause déjeuner');
      return;
    }

    final slotDateTime = _getSlotDateTime(targetJour, targetCreneau);
    print('🎯 DateTime calculé: $slotDateTime');

    setState(() => isLoading = true);

    try {
      print('📡 Appel API deplacerCours...');
      final response = await EmploiDuTempsService.deplacerCours(
        cours['id'],
        slotDateTime['date']!,
        slotDateTime['heure_debut']!,
        slotDateTime['heure_fin']!,
        'Déplacement via glisser-déposer',
      );

      print('📡 Réponse API: $response');

      if (response['success'] == true) {
        print('✅ Déplacement réussi !');
        _showSuccess('Cours déplacé avec succès !');
        await _loadData(); // Recharger les données
      } else {
        print('❌ Échec déplacement: ${response['message']}');
        _showConflictDialog(response);
      }
    } catch (e) {
      print('❌ Exception lors du déplacement: $e');
      _showError('Erreur lors du déplacement: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔄 AFFICHER LES CONFLITS ET SUGGESTIONS
  void _showConflictDialog(Map<String, dynamic> response) {
    final conflicts = response['conflicts'] as List<dynamic>? ?? [];
    final suggestions = response['suggestions'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text(
                'Conflit détecté',
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Impossible de déplacer le cours :',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Afficher les conflits
              ...conflicts.map<Widget>((conflict) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          conflict['message'] ?? 'Conflit détecté',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Suggestions si disponibles
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Créneaux alternatifs disponibles :',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...suggestions.take(3).map<Widget>((suggestion) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${suggestion['jour_nom']} ${suggestion['heure_debut']?.substring(0, 5)} - ${suggestion['heure_fin']?.substring(0, 5)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Utiliser la suggestion
                            _utiliserSuggestion(suggestion);
                          },
                          child: const Text('Utiliser'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // 🎯 UTILISER UNE SUGGESTION
  Future<void> _utiliserSuggestion(Map<String, dynamic> suggestion) async {
    if (_draggedCours == null) return;

    setState(() => isLoading = true);

    try {
      final response = await EmploiDuTempsService.deplacerCours(
        _draggedCours!['id'],
        suggestion['date'],
        suggestion['heure_debut'],
        suggestion['heure_fin'],
        'Déplacement via suggestion alternative',
      );

      if (response['success']) {
        _showSuccess('Cours déplacé avec succès !');
        await _loadData();
      } else {
        _showError('Erreur lors du déplacement: ${response['message']}');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Emploi du Temps - Vue Grille',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 🆕 INDICATEUR DRAG & DROP
          if (_isDragging)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.drag_indicator, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Glissez pour déplacer', style: TextStyle(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),


          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _showPrintDialog,
            tooltip: 'Imprimer',
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
          color: Color(0xFF1E293B),
          size: 30.0,
        ),
      )
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildControls(),
          Expanded(child: _buildGrilleEmploiDragDrop()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String departementInfo = '';
    String metierInfo = '';
    String anneeInfo = '';

    if (selectedAnnee != null) {
      anneeInfo = selectedAnnee!['intitule'] ?? 'N/A';

      final emploisAnnee = emplois.where((e) =>
      e['annee'] != null && e['annee']['id'] == selectedAnnee!['id']
      ).toList();

      if (emploisAnnee.isNotEmpty) {
        for (var emploi in emploisAnnee) {
          final competences = emploi['competences'] as List<dynamic>? ?? [];
          if (competences.isNotEmpty) {
            final premiereCom = competences[0];
            final metier = premiereCom['metier'];
            if (metier != null) {
              metierInfo = metier['intitule']?.toString() ?? '';

              final departement = metier['departement'];
              if (departement != null) {
                departementInfo = departement['nom_departement']?.toString() ?? '';
                break;
              }
            }
          }
        }

        if (departementInfo.isEmpty) {
          final premierEmploi = emploisAnnee.first;
          final annee = premierEmploi['annee'];
          if (annee != null && annee['departement'] != null) {
            departementInfo = annee['departement']['nom_departement'] ?? '';
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (departementInfo.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'DÉPARTEMENT ${departementInfo.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),

                if (metierInfo.isNotEmpty)
                  Expanded(
                    child: Text(
                      'FILIERE: ${metierInfo.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (selectedAnnee != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Classe: $anneeInfo',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
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
        children: [
          const SizedBox(width: 16),

          Center(
            child: IconButton(
              onPressed: () {
                setState(() {
                  selectedWeek = selectedWeek.subtract(const Duration(days: 7));
                });
              },
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Semaine précédente',
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Semaine du ${_formatDate(selectedWeek)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                selectedWeek = selectedWeek.add(const Duration(days: 7));
              });
            },
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Semaine suivante',
          ),
        ],
      ),
    );
  }

  // 🆕 GRILLE AVEC DRAG & DROP
  Widget _buildGrilleEmploiDragDrop() {
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
                    return _buildCreneauRowDragDrop(creneau);
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

  // 🆕 LIGNE DE CRÉNEAUX AVEC DRAG & DROP
  Widget _buildCreneauRowDragDrop(String creneau) {
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
            final slotKey = _getSlotKey(jour, creneau);
            return _buildCoursCellDragDrop(cours, isPause, slotKey);
          }).toList(),
        ],
      ),
    );
  }

  // 🆕 CELLULE DE COURS AVEC DRAG & DROP
  Widget _buildCoursCellDragDrop(Map<String, dynamic>? cours, bool isPause, String slotKey) {
    Color couleur = cours != null ? _getCouleurCours(cours) : Colors.white;
    bool isHovered = _hoveredSlot == slotKey;
    bool canAcceptDrop = !isPause && cours == null && _isDragging;

    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) {
        print('🎯 DragTarget onWillAccept: $slotKey, data: ${data != null}');
        if (isPause || data == null) {
          print('❌ Refusé: isPause=$isPause, data null=${data == null}');
          return false;
        }
        setState(() => _hoveredSlot = slotKey);
        return true;
      },
      onLeave: (data) {
        print('🚪 DragTarget onLeave: $slotKey');
        setState(() => _hoveredSlot = null);
      },
      onAccept: (data) {
        print('✅ DragTarget onAccept: $slotKey, cours: ${data['id']}');
        setState(() {
          _hoveredSlot = null;
          _isDragging = false;
        });
        _deplacerCours(data, slotKey);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 140,
          height: 80,
          decoration: BoxDecoration(
            color: isHovered ? Colors.green.shade100 : couleur,
            border: Border.all(
              color: isHovered
                  ? Colors.green.shade400
                  : Colors.grey.shade400,
              width: isHovered ? 2 : 1,
            ),
            boxShadow: isHovered ? [
              BoxShadow(
                color: Colors.green.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Stack(
            children: [
              // Contenu du cours
              if (cours != null)
                _buildDraggableCoursContent(cours, isPause, slotKey),

              // Indicateur de zone de drop
              if (canAcceptDrop)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100.withOpacity(0.7),
                    border: Border.all(
                      color: Colors.blue.shade400,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_circle,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),
                ),

              // Message d'aide au hover
              if (isHovered && _isDragging)
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Relâcher ici',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 🆕 CONTENU DRAGGABLE DU COURS
  Widget _buildDraggableCoursContent(Map<String, dynamic> cours, bool isPause, String slotKey) {
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

    // Ne pas rendre draggable les cours vides
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

    return Draggable<Map<String, dynamic>>(
      data: cours,
      onDragStarted: () {
        print('🚀 Drag started pour cours: ${cours['id']}');
        setState(() {
          _draggedCours = cours;
          _draggedFromSlot = slotKey;
          _isDragging = true;
        });
      },
      onDragEnd: (details) {
        print('🏁 Drag ended. wasAccepted: ${details.wasAccepted}');
        setState(() {
          _draggedCours = null;
          _draggedFromSlot = null;
          _isDragging = false;
          _hoveredSlot = null;
        });
      },
      onDragUpdate: (details) {
        // Optionnel: pour debug la position
        // print('📍 Drag position: ${details.globalPosition}');
      },
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 130,
          height: 70,
          decoration: BoxDecoration(
            color: _getCouleurCours(cours),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade400, width: 2),
          ),
          child: _buildCoursContent(cours, isPause),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade300.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.grey.shade400,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
              Text(
                'Déplacement...',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            _buildCoursContent(cours, isPause),

            // Icône de drag en haut à droite
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.drag_indicator,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
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
    final formateur = premierCours['formateur'] ?? {};
    final salle = premierCours['salle'] ?? {};

    final nomFormateur = formateur['nom']?.toString() ?? '';
    final prenomFormateur = formateur['prenom']?.toString() ?? '';
    String formateurDisplay = '';
    if (prenomFormateur.isNotEmpty && nomFormateur.isNotEmpty) {
      formateurDisplay = '(M. ${nomFormateur.toUpperCase()})';
    }

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

          if (formateurDisplay.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              formateurDisplay,
              style: const TextStyle(
                fontSize: 8,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

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

  Widget _buildHeaderAmeliore() {
    String departementInfo = '';
    String metierInfo = selectedMetier?['intitule'] ?? '';
    String anneeInfo = selectedAnnee?['intitule'] ?? '';

    // Récupérer le département depuis le métier sélectionné
    if (selectedMetier != null && selectedMetier!['departement'] != null) {
      departementInfo = selectedMetier!['departement']['nom_departement'] ?? '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Informations du département
          if (departementInfo.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'DÉPARTEMENT ${departementInfo.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                // 🆕 SÉLECTEUR DE MÉTIER
                if (metiersDuDepartement.length > 1)
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: DropdownButton<Map<String, dynamic>>(
                        value: selectedMetier,
                        hint: const Text('Choisir métier'),
                        items: metiersDuDepartement.map((metier) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: metier,
                            child: Text(
                              metier['intitule'] ?? 'Métier ${metier['id']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (nouveauMetier) {
                          setState(() {
                            selectedMetier = nouveauMetier;
                          });
                        },
                        underline: Container(
                          height: 1,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          const SizedBox(height: 20),

          // Informations de la classe et métier actuel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (selectedAnnee != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Classe: $anneeInfo',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

              if (metierInfo.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Filière: $metierInfo',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          // 🆕 Affichage du nombre de métiers disponibles
          if (metiersDuDepartement.length > 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Text(
                '${metiersDuDepartement.length} métiers disponibles dans ce département',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }




  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imprimer l\'emploi du temps'),
        content: const Text('Fonctionnalité d\'impression à implémenter.\n\nVoulez-vous exporter en PDF ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showError('Export PDF - Fonctionnalité à implémenter');
            },
            child: const Text('Exporter PDF'),
          ),
        ],
      ),
    );
  }
}