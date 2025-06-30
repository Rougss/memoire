import 'package:flutter/material.dart';
import '../services/type_formation_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'create_type_formation_screen.dart';

class TypeFormationManageScreen extends StatefulWidget {
  const TypeFormationManageScreen({super.key});

  @override
  State<TypeFormationManageScreen> createState() => _TypeFormationManageScreenState();
}

class _TypeFormationManageScreenState extends State<TypeFormationManageScreen> {
  List<Map<String, dynamic>> typeFormations = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTypeFormations();
  }

  Future<void> _loadTypeFormations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await TypeFormationService.getAllTypeFormations();
      setState(() {
        typeFormations = data;
        isLoading = false;
      });

      print('✅ TOTAL types de formation chargés: ${typeFormations.length}');

      // Debug pour voir les données
      for (int i = 0; i < typeFormations.length && i < 3; i++) {
        final type = typeFormations[i];
        print('📚 Type de formation $i: ${type['intitule']} - ID: ${type['id']}');
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

  List<Map<String, dynamic>> get filteredTypeFormations {
    return typeFormations.where((type) {
      final queryLower = searchQuery.toLowerCase();
      final intitule = (type['intitule']?.toString() ?? '').toLowerCase();

      return intitule.contains(queryLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des types de formation',
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
            MaterialPageRoute(builder: (context) => const CreateTypeFormationScreen()),
          ).then((_) => _loadTypeFormations());
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau type'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Header avec recherche
          _buildSearchHeader(),

          // Liste des types de formation
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
                    'Chargement des types de formation...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : filteredTypeFormations.isEmpty
                ? _buildEmptyState()
                : _buildTypeFormationsList(),
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
            hintText: 'Rechercher un type de formation...',
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

  Widget _buildTypeFormationsList() {
    return Column(
      children: [
        // Compteur
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${filteredTypeFormations.length} type(s) de formation trouvé(s) sur ${typeFormations.length} au total',
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
            onRefresh: _loadTypeFormations,
            color: const Color(0xFF8B5CF6),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredTypeFormations.length,
              itemBuilder: (context, index) {
                return _buildTypeFormationCard(filteredTypeFormations[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFormationCard(Map<String, dynamic> typeFormation) {
    final String intitule = typeFormation['intitule']?.toString() ?? 'N/A';

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
            // Icône de type de formation
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF8B5CF6),
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Informations type de formation
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

                  const SizedBox(height: 4),

                  // Métiers associés (si disponible)
                  if (typeFormation['metiers'] != null && typeFormation['metiers'].isNotEmpty)
                    Text(
                      '${typeFormation['metiers'].length} métier(s) associé(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
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
                      Icon(Icons.edit_rounded, size: 18, color: Color(0xFF3B82F6)),
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
              onSelected: (value) => _handleTypeFormationAction(value, typeFormation),
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
              Icons.school_outlined,
              size: 60,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun type de formation trouvé',
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
                : 'Commencez par ajouter des types de formation',
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

  void _handleTypeFormationAction(String action, Map<String, dynamic> typeFormation) {
    switch (action) {
      case 'view':
        _showTypeFormationDetails(typeFormation);
        break;
      case 'edit':
        _showEditTypeFormationDialog(typeFormation);
        break;
      case 'delete':
        _confirmDeleteTypeFormation(typeFormation);
        break;
    }
  }

  void _showTypeFormationDetails(Map<String, dynamic> typeFormation) {
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
                Icons.school_rounded,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                typeFormation['intitule']?.toString() ?? 'Type de formation',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', typeFormation['id']?.toString() ?? 'N/A'),
            _buildDetailRow('Intitulé', typeFormation['intitule']?.toString() ?? 'N/A'),
            _buildDetailRow('Nombre de métiers', (typeFormation['metiers']?.length ?? 0).toString()),
            if (typeFormation['created_at'] != null)
              _buildDetailRow('Créé le', typeFormation['created_at']?.toString() ?? 'N/A'),
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

  void _showEditTypeFormationDialog(Map<String, dynamic> typeFormation) {
    final intituleController = TextEditingController(text: typeFormation['intitule']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Color(0xFF3B82F6)),
            SizedBox(width: 12),
            Text('Modifier le type de formation'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: intituleController,
                decoration: const InputDecoration(
                  labelText: 'Intitulé *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'intitulé est obligatoire';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _updateTypeFormation(
              context,
              typeFormation['id'],
              intituleController.text,
              formKey,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _updateTypeFormation(BuildContext dialogContext, int id, String intitule, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    try {
      await TypeFormationService.updateTypeFormation(
        id: id,
        intitule: intitule.trim(),
      );

      Navigator.pop(dialogContext);
      await _loadTypeFormations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Type de formation modifié avec succès'),
            backgroundColor: Color(0xFF3B82F6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteTypeFormation(Map<String, dynamic> typeFormation) {
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
              'Êtes-vous sûr de vouloir supprimer ce type de formation ?',
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
                    typeFormation['intitule']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${typeFormation['metiers']?.length ?? 0} métier(s) associé(s)',
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
            onPressed: () => _deleteTypeFormation(context, typeFormation['id']),
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

  void _deleteTypeFormation(BuildContext dialogContext, int id) async {
    try {
      await TypeFormationService.deleteTypeFormation(id);

      Navigator.pop(dialogContext);
      await _loadTypeFormations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Type de formation supprimé avec succès'),
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