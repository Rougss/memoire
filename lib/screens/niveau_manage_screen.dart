import 'package:flutter/material.dart';
import '../services/niveau_service.dart';
import 'create_niveau_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class NiveauManageScreen extends StatefulWidget {
  const NiveauManageScreen({super.key});

  @override
  State<NiveauManageScreen> createState() => _NiveauManageScreenState();
}

class _NiveauManageScreenState extends State<NiveauManageScreen> {
  List<Map<String, dynamic>> niveaux = [];
  List<Map<String, dynamic>> typesFormation = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedTypeFormation = 'Tous';

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
        NiveauService.getAllNiveaux(),
        NiveauService.getTypesFormation(),
      ]);

      setState(() {
        niveaux = results[0];
        typesFormation = results[1];
        isLoading = false;
      });

      print('✅ TOTAL niveaux chargés: ${niveaux.length}');
      print('✅ TOTAL types formation chargés: ${typesFormation.length}');

      // Debug pour voir les données
      for (int i = 0; i < niveaux.length && i < 3; i++) {
        final niveau = niveaux[i];
        print('📚 Niveau $i: ${niveau['intitule']} - Type: ${_getTypeFormationName(niveau['type_formation_id'])} - ID: ${niveau['id']}');
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

  // Filtrage combiné : recherche + type de formation
  List<Map<String, dynamic>> get filteredNiveaux {
    return niveaux.where((niveau) {
      final queryLower = searchQuery.toLowerCase();
      final intitule = (niveau['intitule']?.toString() ?? '').toLowerCase();
      final typeFormationName = _getTypeFormationName(niveau['type_formation_id']);

      // Filtrage par recherche (intitulé)
      final matchesSearch = searchQuery.isEmpty || intitule.contains(queryLower);

      // Filtrage par type de formation
      final matchesTypeFormation = selectedTypeFormation == 'Tous' ||
          typeFormationName == selectedTypeFormation;

      return matchesSearch && matchesTypeFormation;
    }).toList();
  }

  String _getTypeFormationName(int? typeFormationId) {
    if (typeFormationId == null) return 'Aucun type';

    final type = typesFormation.firstWhere(
          (t) => t['id'] == typeFormationId,
      orElse: () => {'intitule': 'Type inconnu'},
    );

    return type['intitule']?.toString() ?? 'Type inconnu';
  }

  // Obtenir la liste des types de formation pour le filtre
  List<String> get availableTypeFormations {
    final List<String> types = ['Tous'];

    // Ajouter tous les types de formation existants
    for (var type in typesFormation) {
      final typeName = type['intitule']?.toString();
      if (typeName != null && !types.contains(typeName)) {
        types.add(typeName);
      }
    }

    return types;
  }

  // Couleur pour chaque type de formation
  Color _getTypeFormationColor(String typeFormation) {
    switch (typeFormation) {
      case 'BTS':
        return const Color(0xFF3B82F6); // Bleu
      case 'BTI':
        return const Color(0xFF10B981); // Vert
      case 'Licence':
        return const Color(0xFF8B5CF6); // Violet
      case 'Master':
        return const Color(0xFFF59E0B); // Orange
      case 'Formation Professionnelle':
        return const Color(0xFFEF4444); // Rouge
      case 'Aucun type':
        return const Color(0xFF64748B); // Gris
      default:
        return const Color(0xFF06B6D4); // Cyan par défaut
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des niveaux',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF06B6D4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateNiveauScreen()),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau niveau'),
        backgroundColor: const Color(0xFF06B6D4),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Header avec recherche et filtres
          _buildSearchAndFilters(),

          // Liste des niveaux
          Expanded(
            child: isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitThreeInOut(
                    color: Color(0xFF06B6D4),
                    size: 30.0,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des niveaux...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : filteredNiveaux.isEmpty
                ? _buildEmptyState()
                : _buildNiveauxList(),
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
                hintText: 'Rechercher par nom de niveau...',
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

          // Filtres par type de formation
          const Text(
            'Filtrer par type de formation',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTypeFormations.map((typeFormation) {
              final isSelected = selectedTypeFormation == typeFormation;
              final color = _getTypeFormationColor(typeFormation);

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedTypeFormation = typeFormation;
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
                        typeFormation,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNiveauxList() {
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
                TextSpan(text: '${filteredNiveaux.length} niveau(x) trouvé(s)'),
                if (selectedTypeFormation != 'Tous') ...[
                  const TextSpan(text: ' pour '),
                  TextSpan(
                    text: selectedTypeFormation,
                    style: TextStyle(
                      color: _getTypeFormationColor(selectedTypeFormation),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                TextSpan(text: ' sur ${niveaux.length} total'),
              ],
            ),
          ),
        ),

        // Liste
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF06B6D4),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredNiveaux.length,
              itemBuilder: (context, index) {
                return _buildNiveauCard(filteredNiveaux[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNiveauCard(Map<String, dynamic> niveau) {
    final String intitule = niveau['intitule']?.toString() ?? 'N/A';
    final int? typeFormationId = niveau['type_formation_id'];
    final String typeFormationName = _getTypeFormationName(typeFormationId);
    final Color typeColor = _getTypeFormationColor(typeFormationName);

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
            // Icône de niveau avec couleur du type
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.stairs_rounded,
                color: typeColor,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Informations niveau
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Type de formation avec couleur spécifique
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: typeColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: typeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          typeFormationName,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
              onSelected: (value) => _handleNiveauAction(value, niveau),
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
              Icons.stairs_outlined,
              size: 60,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun niveau trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty || selectedTypeFormation != 'Tous'
                ? 'Essayez de modifier vos filtres'
                : 'Commencez par ajouter des niveaux',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          if (searchQuery.isNotEmpty || selectedTypeFormation != 'Tous') ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  selectedTypeFormation = 'Tous';
                });
              },
              child: const Text('Effacer les filtres'),
            ),
          ],
        ],
      ),
    );
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

  void _handleNiveauAction(String action, Map<String, dynamic> niveau) {
    switch (action) {
      case 'view':
        _showNiveauDetails(niveau);
        break;
      case 'edit':
        _showEditNiveauDialog(niveau);
        break;
      case 'delete':
        _confirmDeleteNiveau(niveau);
        break;
    }
  }

  void _showNiveauDetails(Map<String, dynamic> niveau) {
    final typeFormationName = _getTypeFormationName(niveau['type_formation_id']);

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
                Icons.stairs_rounded,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                niveau['intitule']?.toString() ?? 'Niveau',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', niveau['id']?.toString() ?? 'N/A'),
            _buildDetailRow('Intitulé', niveau['intitule']?.toString() ?? 'N/A'),
            _buildDetailRow('Type de formation', typeFormationName),
            if (niveau['updated_at'] != null)
              _buildDetailRow('Modifié le', _formatDate(niveau['updated_at']?.toString())),
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

  void _showEditNiveauDialog(Map<String, dynamic> niveau) {
    final intituleController = TextEditingController(text: niveau['intitule']?.toString() ?? '');
    int? selectedTypeFormationId = niveau['type_formation_id'];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: Color(0xFF8B5CF6)),
              SizedBox(width: 12),
              Text('Modifier le niveau'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: intituleController,
                    decoration: const InputDecoration(
                      labelText: 'Intitulé *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'intitulé est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedTypeFormationId,
                    decoration: const InputDecoration(
                      labelText: 'Type de formation',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Aucun type'),
                      ),
                      ...typesFormation.map((type) {
                        return DropdownMenuItem<int>(
                          value: type['id'],
                          child: Text(type['intitule']?.toString() ?? 'N/A'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTypeFormationId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => _updateNiveau(
                context,
                niveau['id'],
                intituleController.text,
                selectedTypeFormationId,
                formKey,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateNiveau(BuildContext dialogContext, int id, String intitule, int? typeFormationId, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    try {
      await NiveauService.updateNiveau(
        id: id,
        intitule: intitule.trim(),
        typeFormationId: typeFormationId,
      );

      Navigator.pop(dialogContext);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Niveau modifié avec succès'),
            backgroundColor: Color(0xFF8B5CF6),
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

  void _confirmDeleteNiveau(Map<String, dynamic> niveau) {
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
              'Êtes-vous sûr de vouloir supprimer ce niveau ?',
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
                    niveau['intitule']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${_getTypeFormationName(niveau['type_formation_id'])}',
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
            onPressed: () => _deleteNiveau(context, niveau['id']),
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

  void _deleteNiveau(BuildContext dialogContext, int id) async {
    try {
      await NiveauService.deleteNiveau(id);

      Navigator.pop(dialogContext);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Niveau supprimé avec succès'),
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