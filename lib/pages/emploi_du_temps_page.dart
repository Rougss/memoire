import 'package:flutter/material.dart';
import 'package:memoire/screens/analyse_emploi_du_temps_screen.dart';
import '../screens/create_creneau_screen.dart';
import '../screens/generation_auto_screen.dart';
import '../screens/quota_dashboard_screen.dart';
import '../services/emploi_du_temps_service.dart';
import 'emploi_grille_view.dart';

class EmploiDuTempsPage extends StatefulWidget {
  const EmploiDuTempsPage({Key? key}) : super(key: key);

  @override
  State<EmploiDuTempsPage> createState() => _EmploiDuTempsPageState();
}

class _EmploiDuTempsPageState extends State<EmploiDuTempsPage> {
  List<Map<String, dynamic>> emplois = [];
  bool isLoading = true;
  String searchQuery = '';
  DateTime selectedWeek = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeWeek();
    _loadEmplois();
  }

  void _initializeWeek() {
    final now = DateTime.now();
    selectedWeek = now.subtract(Duration(days: now.weekday - 1));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadEmplois() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await EmploiDuTempsService.getAllEmplois();
      setState(() {
        emplois = data;
        isLoading = false;
      });

      print('✅ ${emplois.length} emplois chargés');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('❌ Erreur chargement emplois: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredEmplois {
    return emplois.where((emploi) {
      final anneeNom = emploi['annee']?['intitule']?.toString().toLowerCase() ?? '';
      final departement = emploi['annee']?['departement']?['nom_departement']?.toString().toLowerCase() ?? '';
      final date = emploi['date_debut']?.toString() ?? '';
      final query = searchQuery.toLowerCase();

      return anneeNom.contains(query) ||
          departement.contains(query) ||
          date.contains(query);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get emploisParJour {
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'Lundi': [],
      'Mardi': [],
      'Mercredi': [],
      'Jeudi': [],
      'Vendredi': [],
      'Samedi': [],
    };

    for (var emploi in filteredEmplois) {
      final dateStr = emploi['date_debut']?.toString();
      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr);
          final dayName = _getDayName(date.weekday);
          if (grouped.containsKey(dayName)) {
            grouped[dayName]!.add(emploi);
          }
        } catch (e) {
          print('Erreur parsing date: $e');
        }
      }
    }

    grouped.forEach((day, emploisList) {
      emploisList.sort((a, b) {
        final heureA = a['heure_debut']?.toString() ?? '';
        final heureB = b['heure_debut']?.toString() ?? '';
        return heureA.compareTo(heureB);
      });
    });

    return grouped;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Lundi';
      case 2: return 'Mardi';
      case 3: return 'Mercredi';
      case 4: return 'Jeudi';
      case 5: return 'Vendredi';
      case 6: return 'Samedi';
      case 7: return 'Dimanche';
      default: return 'Inconnu';
    }
  }

  Color _getColorForDepartment(String? departement) {
    if (departement == null) return Colors.grey.shade300;

    final colors = {
      'informatique': Colors.blue.shade100,
      'génie civil': Colors.green.shade100,
      'électricité': Colors.yellow.shade100,
      'mécanique': Colors.orange.shade100,
      'commerce': Colors.purple.shade100,
    };

    final dept = departement.toLowerCase();
    for (var key in colors.keys) {
      if (dept.contains(key)) {
        return colors[key]!;
      }
    }

    return Colors.teal.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion Emploi du Temps',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.view_week_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmploiGrilleView()),
              );
            },
            tooltip: 'Vue grille',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEmplois,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickActions(),
          _buildSearchBar(),
          _buildWeekSelector(),
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            )
                : filteredEmplois.isEmpty
                ? _buildEmptyState()
                : _buildEmployesList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "manual",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateCreneauScreen()),
              ).then((_) => _loadEmplois());
            },
            backgroundColor: const Color(0xFF3B82F6),
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Ajouter un créneau',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              title: 'Quotas',
              subtitle: 'Suivi des heures',
              icon: Icons.hourglass_bottom_rounded,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuotasDashboardScreen()),
                );
              },
            ),
          ),

          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              title: 'Rapport',
              subtitle: 'Générer un rapport',
              icon: Icons.assessment_rounded,
              color: Colors.green,
              onTap: () {
                _showRapportDialog();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Rechercher par département, classe, date...',
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            '${filteredEmplois.length} créneaux trouvés',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedWeek = selectedWeek.subtract(const Duration(days: 7));
                  });
                },
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Semaine précédente',
              ),
              Flexible(
                child: Text(
                  'Semaine du ${_formatDate(selectedWeek)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  Widget _buildEmployesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEmplois.length,
      itemBuilder: (context, index) {
        return _buildEmploiCard(filteredEmplois[index], index);
      },
    );
  }

  // Fonctions utilitaires pour formater les dates et heures
  String _formatDateFromString(String dateString) {
    if (dateString.isEmpty) return 'Date non définie';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString.split('T')[0]; // Fallback
    }
  }

  String _formatTimeFromString(String timeString) {
    if (timeString.isEmpty) return '--:--';

    try {
      // Si c'est un datetime complet, extraire l'heure
      if (timeString.contains('T')) {
        final parts = timeString.split('T');
        if (parts.length > 1) {
          final timePart = parts[1].split('.')[0]; // Enlever les millisecondes
          return timePart.substring(0, 5); // Prendre HH:MM seulement
        }
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  Widget _buildEmploiCard(Map<String, dynamic> emploi, int index) {
    // Extraction des données avec vérifications
    final annee = emploi['annee'] ?? {};
    final departement = annee['departement'] ?? {};
    final competences = List<Map<String, dynamic>>.from(emploi['competences'] ?? []);

    final nomDepartement = departement['nom_departement']?.toString() ?? 'Aucun département';
    final intituleAnnee = annee['intitule']?.toString() ?? 'Année non définie';

    // Formatage des dates et heures
    final dateDebut = _formatDateFromString(emploi['date_debut']?.toString() ?? '');
    final dateFin = _formatDateFromString(emploi['date_fin']?.toString() ?? '');
    final heureDebut = _formatTimeFromString(emploi['heure_debut']?.toString() ?? '');
    final heureFin = _formatTimeFromString(emploi['heure_fin']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec département et classe
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getColorForDepartment(nomDepartement),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        nomDepartement.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          intituleAnnee,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Année Scolaire: 2024/2025',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Informations détaillées
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date et horaires
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateDebut == dateFin ? dateDebut : 'Du $dateDebut au $dateFin',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.green.shade600, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$heureDebut - $heureFin',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (competences.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Compétences enseignées:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...competences.map((competence) => _buildCompetenceItem(competence)).toList(),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Aucune compétence assignée à ce créneau',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetenceItem(Map<String, dynamic> competence) {
    final nomCompetence = competence['nom']?.toString() ?? 'Compétence non définie';
    final codeCompetence = competence['code']?.toString() ?? 'N/A';
    final formateur = competence['formateur'] ?? {};
    final salle = competence['salle'] ?? {};

    final nomFormateur = formateur['nom']?.toString() ?? '';
    final prenomFormateur = formateur['prenom']?.toString() ?? '';
    final formateurComplet = '$prenomFormateur $nomFormateur'.trim();

    final intituleSalle = salle['intitule']?.toString() ?? '';
    final batiment = salle['batiment'] ?? {};
    final intituleBatiment = batiment['intitule']?.toString() ?? '';

    // 🔥 CORRECTION : Récupérer le département depuis la compétence
    final metier = competence['metier'] ?? {};
    final departementCompetence = metier['departement'] ?? {};
    final nomDepartementCompetence = departementCompetence['nom_departement']?.toString() ?? '';
    final intituleMetier = metier['intitule']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // 🔥 CORRECTION : Utiliser le département de la compétence pour la couleur
        color: _getColorForDepartment(nomDepartementCompetence).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getColorForDepartment(nomDepartementCompetence).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  codeCompetence,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nomCompetence,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 🔥 NOUVEAU : Afficher le département de la compétence
          if (nomDepartementCompetence.isNotEmpty)
            _buildInfoRow(Icons.business, 'Département', nomDepartementCompetence, Colors.indigo.shade600),

          if (formateurComplet.isNotEmpty)
            _buildInfoRow(Icons.person, 'Formateur', formateurComplet, Colors.purple.shade600),

          if (intituleMetier.isNotEmpty)
            _buildInfoRow(Icons.work, 'Métier', intituleMetier, Colors.orange.shade600),

          if (intituleSalle.isNotEmpty)
            _buildInfoRow(Icons.room, 'Salle',
                intituleBatiment.isNotEmpty
                    ? '$intituleSalle ($intituleBatiment)'
                    : intituleSalle,
                Colors.red.shade600),

          // Si aucune info supplémentaire
          if (formateurComplet.isEmpty && intituleMetier.isEmpty && intituleSalle.isEmpty && nomDepartementCompetence.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Aucune information supplémentaire',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 60,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun emploi du temps trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Commencez par créer des créneaux pour vos classes',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateCreneauScreen()),
              ).then((_) => _loadEmplois());
            },
            icon: const Icon(Icons.add),
            label: const Text('Créer un créneau'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRapportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Générer un rapport'),
        content: const Text('Fonctionnalité de rapport à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}