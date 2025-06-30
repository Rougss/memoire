import 'package:flutter/material.dart';
import 'package:memoire/screens/create_specialite_screen.dart';
import '../services/salle_service.dart';
import 'create_salle_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';


class SalleManageScreen extends StatefulWidget {
  const SalleManageScreen({super.key});

  @override
  State<SalleManageScreen> createState() => _SalleManageScreenState();
}

class _SalleManageScreenState extends State<SalleManageScreen> {
  List<Map<String, dynamic>> salles = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSalles();
  }

  Future<void> _loadSalles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await SalleService.getAllSalles();
      setState(() {
        salles = data;
        isLoading = false;
      });

      print('✅ TOTAL salles chargées: ${salles.length}');

      // Debug pour voir exactement ce qui est retourné
      for (int i = 0; i < salles.length && i < 3; i++) {
        final salle = salles[i];
        print('🏢 Salle $i: ${salle['intitule']} - ${salle['nombre_de_place']} places - Bâtiment: ${salle['batiment']?['nom'] ?? 'N/A'}');
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

  List<Map<String, dynamic>> get filteredSalles {
    return salles.where((salle) {
      final intitule = (salle['intitule']?.toString() ?? '').toLowerCase();
      final batimentNom = (salle['batiment']?['intitule']?.toString() ?? '').toLowerCase();
      final nombrePlace = (salle['nombre_de_place']?.toString() ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();

      return intitule.contains(query) ||
          batimentNom.contains(query) ||
          nombrePlace.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des Salles',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.red.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateSalleScreen())
          );
          if (result == true) {
            _loadSalles();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle Salle'),
        backgroundColor: Colors.red.shade500,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Header avec recherche
          _buildSearchHeader(),

          // Liste des salles
          Expanded(
            child: isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitThreeInOut(
                    color: Colors.red,
                    size: 30.0,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des salles...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : filteredSalles.isEmpty
                ? _buildEmptyState()
                : _buildSallesList(),
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
            hintText: 'Rechercher une salle...',
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

  Widget _buildSallesList() {
    return Column(
      children: [
        // Compteur
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${filteredSalles.length} salle(s) trouvée(s) sur ${salles.length} au total',
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
            onRefresh: _loadSalles,
            color: const Color(0xFF10B981),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredSalles.length,
              itemBuilder: (context, index) {
                return _buildSalleCard(filteredSalles[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalleCard(Map<String, dynamic> salle) {
    final String intitule = salle['intitule']?.toString() ?? 'N/A';
    final int nombrePlace = salle['nombre_de_place'] ?? 0;
    final String batimentNom = salle['batiment']?['intitule']?.toString() ?? 'Bâtiment non défini';
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
            // Icône de salle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.meeting_room_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Informations salle
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

                  // Nombre de places
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$nombrePlace places',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Bâtiment
                  Row(
                    children: [
                      const Icon(
                        Icons.business_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          batimentNom,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
              onSelected: (value) => _handleSalleAction(value, salle),
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
              Icons.meeting_room_outlined,
              size: 60,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune salle trouvée',
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
                : 'Commencez par ajouter des salles',
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

  void _handleSalleAction(String action, Map<String, dynamic> salle) {
    switch (action) {
      case 'view':
        _showSalleDetails(salle);
        break;
      case 'edit':
        _showEditSalleDialog(salle);
        break;
      case 'delete':
        _confirmDeleteSalle(salle);
        break;
    }
  }

  void _showSalleDetails(Map<String, dynamic> salle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.meeting_room_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                salle['intitule']?.toString() ?? 'Salle',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', salle['id']?.toString() ?? 'N/A'),
            _buildDetailRow('Intitulé', salle['intitule']?.toString() ?? 'N/A'),
            _buildDetailRow('Nombre de places', salle['nombre_de_place']?.toString() ?? 'N/A'),
            _buildDetailRow('Bâtiment', salle['batiment']?['intitule']?.toString() ?? 'N/A'),            if (salle['batiment']?['adresse'] != null)
              _buildDetailRow('Adresse', salle['batiment']['adresse'].toString()),
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

  void _showEditSalleDialog(Map<String, dynamic> salle) {
    final intituleController = TextEditingController(text: salle['intitule']?.toString() ?? '');
    final nombrePlaceController = TextEditingController(text: salle['nombre_de_place']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Color(0xFF3B82F6)),
            SizedBox(width: 12),
            Text('Modifier la salle'),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: nombrePlaceController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de places *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nombre de places est obligatoire';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 1) {
                    return 'Veuillez saisir un nombre valide (≥ 1)';
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
            onPressed: () => _updateSalle(
              context,
              salle['id'],
              intituleController.text,
              nombrePlaceController.text,
              salle['batiment_id'] ?? 1, // Garder le même bâtiment pour la modification simple
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

  void _updateSalle(BuildContext dialogContext, int id, String intitule, String nombrePlaceStr, int batimentId, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    final nombrePlace = int.parse(nombrePlaceStr);

    try {
      await SalleService.updateSalle(
        id: id,
        intitule: intitule.trim(),
        nombreDePlace: nombrePlace,
        batimentId: batimentId,
      );

      Navigator.pop(dialogContext);
      await _loadSalles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salle modifiée avec succès'),
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

  void _confirmDeleteSalle(Map<String, dynamic> salle) {
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
              'Êtes-vous sûr de vouloir supprimer cette salle ?',
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
                    salle['intitule']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${salle['nombre_de_place']} places - ${salle['batiment']?['intitule'] ?? 'Bâtiment N/A'}',
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
            onPressed: () => _deleteSalle(context, salle['id']),
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

  void _deleteSalle(BuildContext dialogContext, int id) async {
    try {
      await SalleService.deleteSalle(id);

      Navigator.pop(dialogContext);
      await _loadSalles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salle supprimée avec succès'),
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