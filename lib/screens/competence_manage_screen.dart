import 'package:flutter/material.dart';
import '../services/competence_service.dart';
import 'create_competence_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CompetenceManageScreen extends StatefulWidget {
  const CompetenceManageScreen({super.key});

  @override
  State<CompetenceManageScreen> createState() => _CompetenceManageScreenState();
}

class _CompetenceManageScreenState extends State<CompetenceManageScreen> {
  List<Map<String, dynamic>> competences = [];
  List<Map<String, dynamic>> metiers = [];
  List<Map<String, dynamic>> formateurs = [];
  List<Map<String, dynamic>> salles = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedMetier = 'Tous'; // Changé de selectedCompetence à selectedMetier

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final results = await Future.wait([
        CompetenceService.getAllCompetences(),
        CompetenceService.getMetiers(),
        CompetenceService.getFormateurs(),
        CompetenceService.getSalles(),
      ]);

      setState(() {
        competences = results[0];
        metiers = results[1];
        formateurs = results[2];
        salles = results[3];
        isLoading = false;
      });

      print('✅ TOTAL compétences chargées: ${competences.length}');
      print('✅ TOTAL métiers chargés: ${metiers.length}');
      print('✅ TOTAL formateurs chargés: ${formateurs.length}');
      print('✅ TOTAL salles chargées: ${salles.length}');

      // Debug des formateurs
      if (formateurs.isNotEmpty) {
        print('🧑‍💼 Premier formateur: ${formateurs[0]}');
      }

      // Debug des salles
      if (salles.isNotEmpty) {
        print('🏢 Première salle: ${salles[0]}');
      }

      // Debug pour voir les données
      for (int i = 0; i < competences.length && i < 3; i++) {
        final competence = competences[i];
        print('💼 Compétence $i: ${competence['nom']} - Métier: ${_getMetierName(competence['metier_id'])} - ID: ${competence['id']}');
        print('   - Formateur: ${_getFormateurName(competence['formateur_id'])}');
        print('   - Salle: ${_getSalleName(competence['salle_id'])}');
      }

      // CORRECTION : Forcer un rebuild après chargement des données
      if (mounted) {
        setState(() {
          // Trigger rebuild pour mettre à jour l'interface
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('❌ Erreur lors du chargement: $e');
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

  // Filtrage combiné : recherche + métier (pas compétence)
  List<Map<String, dynamic>> get filteredCompetences {
    return competences.where((competence) {
      final queryLower = searchQuery.toLowerCase();
      final nom = (competence['nom']?.toString() ?? '').toLowerCase();
      final code = (competence['code']?.toString() ?? '').toLowerCase();
      final metierName = _getMetierName(competence['metier_id']);

      // Filtrage par recherche (nom ou code)
      final matchesSearch = searchQuery.isEmpty ||
          nom.contains(queryLower) ||
          code.contains(queryLower);

      // Filtrage par métier (pas par compétence)
      final matchesMetier = selectedMetier == 'Tous' ||
          metierName == selectedMetier;

      return matchesSearch && matchesMetier;
    }).toList();
  }

  String _getMetierName(int? metierId) {
    if (metierId == null) return 'Aucun métier';

    final metier = metiers.firstWhere(
          (m) => m['id'] == metierId,
      orElse: () => {'intitule': 'Métier inconnu'},
    );

    return metier['intitule']?.toString() ?? 'Métier inconnu';
  }

  String _getFormateurName(int? formateurId) {
    if (formateurId == null) return 'Aucun formateur';

    // CORRECTION : Vérifier si les données sont chargées
    if (formateurs.isEmpty) {
      print('⚠️ Liste formateurs vide, retour ID: $formateurId');
      return 'ID: $formateurId';
    }

    final formateur = formateurs.firstWhere(
          (f) => f['id'] == formateurId,
      orElse: () {
        print('⚠️ Formateur ID $formateurId non trouvé dans la liste');
        return {'prenom': 'Formateur', 'nom': 'ID: $formateurId'};
      },
    );

    final prenom = formateur['prenom']?.toString() ?? '';
    final nom = formateur['nom']?.toString() ?? '';
    final fullName = '$prenom $nom'.trim();

    print('🎯 Formateur trouvé pour ID $formateurId: $fullName');
    return fullName.isNotEmpty ? fullName : 'Formateur ID: $formateurId';
  }

  String _getSalleName(int? salleId) {
    if (salleId == null) return 'Aucune salle';

    // CORRECTION : Vérifier si les données sont chargées
    if (salles.isEmpty) {
      print('⚠️ Liste salles vide, retour ID: $salleId');
      return 'ID: $salleId';
    }

    final salle = salles.firstWhere(
          (s) => s['id'] == salleId,
      orElse: () {
        print('⚠️ Salle ID $salleId non trouvée dans la liste');
        return {'intitule': 'Salle ID: $salleId'};
      },
    );

    final salleName = salle['intitule']?.toString() ?? salle['nom']?.toString() ?? 'Salle ID: $salleId';
    print('🎯 Salle trouvée pour ID $salleId: $salleName');
    return salleName;
  }

  // Obtenir la liste des métiers pour le filtre (pas compétences)
  List<String> get availableMetiers {
    final List<String> metiersList = ['Tous'];

    // Ajouter tous les métiers existants
    for (var metier in metiers) {
      final metierName = metier['intitule']?.toString();
      if (metierName != null && !metiersList.contains(metierName)) {
        metiersList.add(metierName);
      }
    }

    return metiersList;
  }

  // Couleur pour chaque métier
  Color _getMetierColor(String metier) {
    switch (metier.toLowerCase()) {
      case 'développement web':
        return const Color(0xFF3B82F6); // Bleu
      case 'développement mobile':
        return const Color(0xFF10B981); // Vert
      case 'data science':
        return const Color(0xFF8B5CF6); // Violet
      case 'cybersécurité':
        return const Color(0xFFEF4444); // Rouge
      case 'réseau':
        return const Color(0xFFF59E0B); // Orange
      case 'intelligence artificielle':
        return const Color(0xFF06B6D4); // Cyan
      case 'tous':
        return const Color(0xFF64748B); // Gris
      default:
        return const Color(0xFF64748B); // Gris par défaut
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des compétences',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateCompetenceScreen()),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle compétence'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Header avec recherche et filtres
          _buildSearchAndFilters(),

          // Liste des compétences
          Expanded(
            child: isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitThreeInOut(
                    color: Color(0xFF8B5CF6),
                    size: 30.0,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des compétences...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : filteredCompetences.isEmpty
                ? _buildEmptyState()
                : _buildCompetencesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher par nom ou code...',
                hintStyle: TextStyle(color: Color(0xFF64748B)),
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
          ),
          const SizedBox(height: 16),

          // Filtres par métier - VERSION HORIZONTALE COMPACTE
          const Text(
            'Filtrer par métier',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableMetiers.length,
              itemBuilder: (context, index) {
                final metier = availableMetiers[index];
                final isSelected = selectedMetier == metier;
                final color = _getMetierColor(metier);

                return Container(
                  margin: EdgeInsets.only(right: index < availableMetiers.length - 1 ? 8 : 0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedMetier = metier;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            metier,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetencesList() {
    return Column(
      children: [
        // Compteur avec info sur le filtre
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(text: '${filteredCompetences.length} compétence(s) trouvée(s)'),
                if (selectedMetier != 'Tous') ...[
                  const TextSpan(text: ' pour '),
                  TextSpan(
                    text: selectedMetier,
                    style: TextStyle(
                      color: _getMetierColor(selectedMetier),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                TextSpan(text: ' sur ${competences.length} total'),
              ],
            ),
          ),
        ),

        // Liste
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF8B5CF6),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredCompetences.length,
              itemBuilder: (context, index) {
                return _buildCompetenceCard(filteredCompetences[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompetenceCard(Map<String, dynamic> competence) {
    final String nom = competence['nom']?.toString() ?? 'N/A';
    final String code = competence['code']?.toString() ?? 'N/A';
    final String numeroCompetence = competence['numero_competence']?.toString() ?? 'N/A';
    final int? metierId = competence['metier_id'];
    final int? formateurId = competence['formateur_id'];
    final int? salleId = competence['salle_id'];
    final String metierName = _getMetierName(metierId);
    final Color metierColor = _getMetierColor(metierName);

    // Gérer quota_horaire comme string ou number
    double? quotaHoraire;
    if (competence['quota_horaire'] != null) {
      if (competence['quota_horaire'] is String) {
        quotaHoraire = double.tryParse(competence['quota_horaire']);
      } else if (competence['quota_horaire'] is num) {
        quotaHoraire = competence['quota_horaire'].toDouble();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et nom
            Row(
              children: [
                // Icône de compétence avec couleur du métier
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: metierColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: metierColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Nom de la compétence
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Code de la compétence
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Code: $code',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF64748B)),
                          SizedBox(width: 12),
                          Text('Voir les détails'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18, color: Color(0xFF8B5CF6)),
                          SizedBox(width: 12),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 18, color: Color(0xFFEF4444)),
                          SizedBox(width: 12),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleCompetenceAction(value, competence),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Détails de la compétence AVEC VRAIS NOMS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Première ligne : N° compétence et quota horaire
                  Row(
                    children: [
                      // Numéro de compétence
                      Expanded(
                        child: _buildDetailChip(
                          icon: Icons.numbers_rounded,
                          label: 'N°',
                          value: numeroCompetence,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quota horaire
                      Expanded(
                        child: _buildDetailChip(
                          icon: Icons.schedule_rounded,
                          label: 'Quota',
                          value: quotaHoraire != null ? '${quotaHoraire.toStringAsFixed(0)}h' : 'Non défini',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Deuxième ligne : Métier
                  _buildDetailChip(
                    icon: Icons.work_rounded,
                    label: 'Métier',
                    value: metierName,
                    color: metierColor,
                    isFullWidth: true,
                  ),

                  const SizedBox(height: 8),

                  // Troisième ligne : VRAIS NOMS (pas juste IDs)
                  Row(
                    children: [
                      // Formateur - AFFICHER LE VRAI NOM
                      Expanded(
                        child: _buildDetailChip(
                          icon: Icons.person_rounded,
                          label: 'Formateur',
                          value: _getFormateurName(formateurId), // VRAI NOM !
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Salle - AFFICHER LE VRAI NOM
                      Expanded(
                        child: _buildDetailChip(
                          icon: Icons.meeting_room_rounded,
                          label: 'Salle',
                          value: _getSalleName(salleId), // VRAI NOM !
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    // DEBUG : Print de ce qui est affiché
    print('🎨 _buildDetailChip - Label: $label, Value: $value');

    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value, // VERIFICATION : C'est bien value qui est affiché (maintenant avec vrais noms)
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
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
              Icons.psychology_outlined,
              size: 60,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune compétence trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty || selectedMetier != 'Tous'
                ? 'Essayez de modifier vos filtres'
                : 'Commencez par ajouter des compétences',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          if (searchQuery.isNotEmpty || selectedMetier != 'Tous') ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  selectedMetier = 'Tous';
                });
              },
              child: const Text('Effacer les filtres'),
            ),
          ],
        ],
      ),
    );
  }

  void _handleCompetenceAction(String action, Map<String, dynamic> competence) {
    switch (action) {
      case 'view':
        _showCompetenceDetails(competence);
        break;
      case 'edit':
        _showEditCompetenceDialog(competence);
        break;
      case 'delete':
        _confirmDeleteCompetence(competence);
        break;
    }
  }

  void _showCompetenceDetails(Map<String, dynamic> competence) {
    final metierName = _getMetierName(competence['metier_id']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                competence['nom']?.toString() ?? 'Compétence',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', competence['id']?.toString() ?? 'N/A'),
            _buildDetailRow('Nom', competence['nom']?.toString() ?? 'N/A'),
            _buildDetailRow('Code', competence['code']?.toString() ?? 'N/A'),
            _buildDetailRow('N° Compétence', competence['numero_competence']?.toString() ?? 'N/A'),
            _buildDetailRow('Quota horaire', competence['quota_horaire']?.toString() ?? 'Non défini'),
            _buildDetailRow('Métier', metierName),
            _buildDetailRow('Formateur', _getFormateurName(competence['formateur_id'])), // VRAI NOM
            _buildDetailRow('Salle', _getSalleName(competence['salle_id'])), // VRAI NOM
            if (competence['created_at'] != null)
              _buildDetailRow('Créé le', _formatDate(competence['created_at']?.toString())),
          ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showEditCompetenceDialog(Map<String, dynamic> competence) {
    // Navigation vers l'écran d'édition (à implémenter)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Édition à implémenter - utilisez "Nouvelle compétence" pour le moment'),
        backgroundColor: Color(0xFF8B5CF6),
      ),
    );
  }

  void _confirmDeleteCompetence(Map<String, dynamic> competence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Confirmer la suppression'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir supprimer cette compétence ?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    competence['nom']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${competence['code']?.toString() ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F1D1D),
                    ),
                  ),
                  Text(
                    'Métier: ${_getMetierName(competence['metier_id'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F1D1D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Cette action est irréversible.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _deleteCompetence(context, competence['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deleteCompetence(BuildContext dialogContext, int id) async {
    try {
      await CompetenceService.deleteCompetence(id);

      Navigator.pop(dialogContext);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compétence supprimée avec succès'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(dialogContext);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}