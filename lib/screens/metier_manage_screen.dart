import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/metier_service.dart';
import 'create_metier_screen.dart';

class MetierManageScreen extends StatefulWidget {
  const MetierManageScreen({super.key});

  @override
  State<MetierManageScreen> createState() => _MetierManageScreenState();
}

class _MetierManageScreenState extends State<MetierManageScreen> {
  List<Map<String, dynamic>> metiers = [];
  List<Map<String, dynamic>> departements = []; // 🔥 AJOUT : Cache des départements
  List<Map<String, dynamic>> niveaux = []; // 🔥 AJOUT : Cache des niveaux
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllData(); // 🔥 CHANGEMENT : Charger tout en même temps
  }

  // 🔥 NOUVELLE MÉTHODE : Charger métiers ET départements/niveaux
  Future<void> _loadAllData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Charger métiers, départements et niveaux en parallèle
      final results = await Future.wait([
        MetierService.getAllMetiers(),
        MetierService.getDepartements(),
        MetierService.getNiveaux(),
      ]);

      setState(() {
        metiers = results[0];
        departements = results[1];
        niveaux = results[2];
        isLoading = false;
      });

      print('✅ TOTAL chargé: ${metiers.length} métiers, ${departements.length} départements, ${niveaux.length} niveaux');

      // Debug pour voir les données
      for (int i = 0; i < metiers.length && i < 3; i++) {
        final metier = metiers[i];
        final deptName = _getDepartementName(metier['departement_id']);
        final niveauName = _getNiveauName(metier['niveau_id']);
        print('💼 Métier $i: ${metier['intitule']} - Dept: $deptName - Niveau: $niveauName');
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

  // 🔥 NOUVELLE MÉTHODE : Récupérer le nom du département par ID
  String _getDepartementName(int? departementId) {
    if (departementId == null) return 'Aucun département';

    try {
      final dept = departements.firstWhere(
            (d) => d['id'] == departementId,
        orElse: () => <String, dynamic>{},
      );
      return dept['nom_departement']?.toString() ?? 'Département $departementId';
    } catch (e) {
      return 'Département $departementId';
    }
  }

  // 🔥 NOUVELLE MÉTHODE : Récupérer le nom du niveau par ID
  String _getNiveauName(int? niveauId) {
    if (niveauId == null) return 'Aucun niveau';

    try {
      final niveau = niveaux.firstWhere(
            (n) => n['id'] == niveauId,
        orElse: () => <String, dynamic>{},
      );
      return niveau['intitule']?.toString() ?? 'Niveau $niveauId';
    } catch (e) {
      return 'Niveau $niveauId';
    }
  }

  Future<void> _loadMetiers() async {
    // 🔥 CHANGEMENT : Recharger toutes les données
    await _loadAllData();
  }

  List<Map<String, dynamic>> get filteredMetiers {
    return metiers.where((metier) {
      final queryLower = searchQuery.toLowerCase();
      final intitule = (metier['intitule']?.toString() ?? '').toLowerCase();
      final duree = (metier['duree']?.toString() ?? '').toLowerCase();
      final departement = (metier['departement']?['nom_departement']?.toString() ?? '').toLowerCase();
      final niveau = (metier['niveau']?['intitule']?.toString() ?? '').toLowerCase();

      return intitule.contains(queryLower) ||
          duree.contains(queryLower) ||
          departement.contains(queryLower) ||
          niveau.contains(queryLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des métiers',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateMetierScreen()),
          ).then((_) => _loadAllData()); // 🔥 CHANGEMENT : Utiliser la nouvelle méthode
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau métier'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Header avec recherche
          _buildSearchHeader(),

          // Liste des métiers
          Expanded(
            child: isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitThreeInOut(
                    color: Color(0xFF6366F1),
                    size: 30.0,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des métiers...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : filteredMetiers.isEmpty
                ? _buildEmptyState()
                : _buildMetiersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
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
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Rechercher un métier...',
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
    );
  }

  Widget _buildMetiersList() {
    return Column(
      children: [
        // Compteur
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${filteredMetiers.length} métier(s) trouvé(s) sur ${metiers.length} au total',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Liste
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData, // 🔥 CHANGEMENT : Utiliser la nouvelle méthode
            color: const Color(0xFF6366F1),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredMetiers.length,
              itemBuilder: (context, index) {
                return _buildMetierCard(filteredMetiers[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetierCard(Map<String, dynamic> metier) {
    final String intitule = metier['intitule']?.toString() ?? 'N/A';
    final String duree = metier['duree']?.toString() ?? 'N/A';

    // 🔥 CORRECTION : Utiliser les méthodes de mapping pour récupérer les vrais noms
    final String departement = _getDepartementName(metier['departement_id']);
    final String niveau = _getNiveauName(metier['niveau_id']);
    final String description = metier['description']?.toString() ?? '';

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
        child: Row(
          children: [
            // Icône de métier
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.work_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Informations métier
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intitulé
                  Text(
                    intitule,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Durée et niveau - Responsive
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          duree,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          niveau,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Département - 🔥 MAINTENANT AVEC LE VRAI NOM
                  Text(
                    departement,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
                      Icon(Icons.edit_rounded, size: 18, color: Color(0xFF6366F1)),
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
              onSelected: (value) => _handleMetierAction(value, metier),
            ),
          ],
        ),
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
              Icons.work_outline,
              size: 60,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun métier trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Essayez de modifier votre recherche'
                : 'Commencez par ajouter des métiers',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                });
              },
              child: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }

  void _handleMetierAction(String action, Map<String, dynamic> metier) {
    switch (action) {
      case 'view':
        _showMetierDetails(metier);
        break;
      case 'edit':
        _showEditMetierDialog(metier);
        break;
      case 'delete':
        _confirmDeleteMetier(metier);
        break;
    }
  }

  void _showMetierDetails(Map<String, dynamic> metier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.work_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                metier['intitule']?.toString() ?? 'Métier',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', metier['id']?.toString() ?? 'N/A'),
            _buildDetailRow('Intitulé', metier['intitule']?.toString() ?? 'N/A'),
            _buildDetailRow('Durée', metier['duree']?.toString() ?? 'N/A'),
            _buildDetailRow('Département', _getDepartementName(metier['departement_id'])),
            _buildDetailRow('Niveau', _getNiveauName(metier['niveau_id'])),
            if (metier['description'] != null && metier['description'].toString().isNotEmpty)
              _buildDetailRow('Description', metier['description']?.toString() ?? 'N/A'),
            if (metier['created_at'] != null)
              _buildDetailRow('Créé le', metier['created_at']?.toString().split('T')[0] ?? 'N/A'),
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
            width: 100,
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

  void _showEditMetierDialog(Map<String, dynamic> metier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMetierScreen(metierToEdit: metier),
      ),
    ).then((_) => _loadAllData()); // 🔥 CHANGEMENT : Utiliser la nouvelle méthode
  }

  void _confirmDeleteMetier(Map<String, dynamic> metier) {
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
              'Êtes-vous sûr de vouloir supprimer ce métier ?',
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
                    metier['intitule']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Durée: ${metier['duree']?.toString() ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F1D1D),
                    ),
                  ),
                  Text(
                    'Département: ${metier['departement']?['nom_departement']?.toString() ?? 'N/A'}',
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
              '⚠️ Cette action est irréversible et supprimera toutes les compétences associées.',
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
            onPressed: () => _deleteMetier(context, metier['id']),
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

  void _deleteMetier(BuildContext dialogContext, int id) async {
    try {
      await MetierService.deleteMetier(id);

      Navigator.pop(dialogContext);
      await _loadAllData(); // 🔥 CHANGEMENT : Utiliser la nouvelle méthode

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Métier supprimé avec succès'),
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
}