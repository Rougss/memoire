import 'package:flutter/material.dart';
import '../services/annee_service.dart';
import 'create_annee_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AnneeManageScreen extends StatefulWidget {
  const AnneeManageScreen({super.key});

  @override
  State<AnneeManageScreen> createState() => _AnneeManageScreenState();
}

class _AnneeManageScreenState extends State<AnneeManageScreen> {
  List<Map<String, dynamic>> annees = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAnnees();
  }

  Future<void> _loadAnnees() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await AnneeService.getAllAnnees();
      setState(() {
        annees = data;
        isLoading = false;
      });

      print('✅ TOTAL années chargées: ${annees.length}');

      // Debug pour voir les données
      for (int i = 0; i < annees.length && i < 3; i++) {
        final annee = annees[i];
        print('📅 Année $i: ${annee['intitule']} - ID: ${annee['id']}');
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

  List<Map<String, dynamic>> get filteredAnnees {
    return annees.where((annee) {
      final queryLower = searchQuery.toLowerCase();
      final intitule = (annee['intitule']?.toString() ?? '').toLowerCase();
      final anneeValue = (annee['annee']?.toString() ?? '').toLowerCase();

      return intitule.contains(queryLower) || anneeValue.contains(queryLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des années',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateAnneeScreen()),
          ).then((_) => _loadAnnees());
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle année'),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Header avec recherche
          _buildSearchHeader(),

          // Liste des années
          Expanded(
            child: isLoading
                ? const  Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitThreeInOut(
                    color: Colors.yellow,
                    size: 30.0,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des années...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : filteredAnnees.isEmpty
                ? _buildEmptyState()
                : _buildAnneesList(),
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
            hintText: 'Rechercher une année...',
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

  Widget _buildAnneesList() {
    // Trier les années par ordre décroissant (plus récentes en premier)
    final sortedAnnees = List<Map<String, dynamic>>.from(filteredAnnees);
    sortedAnnees.sort((a, b) {
      final anneeA = int.tryParse(a['annee']?.toString() ?? '0') ?? 0;
      final anneeB = int.tryParse(b['annee']?.toString() ?? '0') ?? 0;
      return anneeB.compareTo(anneeA); // Ordre décroissant
    });

    return Column(
      children: [
        // Compteur
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${filteredAnnees.length} année(s) trouvée(s) sur ${annees
                .length} total',
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
            onRefresh: _loadAnnees,
            color: const Color(0xFFF59E0B),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedAnnees.length,
              itemBuilder: (context, index) {
                return _buildAnneeCard(sortedAnnees[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnneeCard(Map<String, dynamic> annee) {
    final String intitule = annee['intitule']?.toString() ?? 'N/A';
    final String anneeValue = annee['annee']?.toString() ?? 'N/A';
    final bool isCurrentYear = _isCurrentAcademicYear(anneeValue);

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
          color: isCurrentYear
              ? const Color(0xFFF59E0B).withOpacity(0.3)
              : const Color(0xFFF1F5F9),
          width: isCurrentYear ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icône d'année
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCurrentYear
                    ? const Color(0xFFF59E0B).withOpacity(0.2)
                    : const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCurrentYear
                    ? Icons.event_available_rounded
                    : Icons.calendar_today_rounded,
                color: const Color(0xFFF59E0B),
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Informations année
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intitulé
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          intitule,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentYear) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Actuelle',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Année de début
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Début: $anneeValue',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  if (annee['created_at'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Créée le: ${_formatDate(
                          annee['created_at'].toString())}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
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
              itemBuilder: (context) =>
              [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 18,
                          color: Color(0xFF64748B)),
                      SizedBox(width: 12),
                      Text('Voir les détails'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18,
                          color: Color(0xFFF59E0B)),
                      SizedBox(width: 12),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 18,
                          color: Color(0xFFEF4444)),
                      SizedBox(width: 12),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleAnneeAction(value, annee),
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
              Icons.calendar_month_outlined,
              size: 60,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune année trouvée',
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
                : 'Commencez par ajouter des années académiques',
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

  bool _isCurrentAcademicYear(String anneeValue) {
    final currentYear = DateTime
        .now()
        .year;
    final currentMonth = DateTime
        .now()
        .month;

    // L'année académique commence généralement en septembre/octobre
    // Si on est avant juillet, on considère l'année académique précédente
    final academicYear = currentMonth >= 7 ? currentYear : currentYear - 1;

    return anneeValue == academicYear.toString();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month
          .toString()
          .padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _handleAnneeAction(String action, Map<String, dynamic> annee) {
    switch (action) {
      case 'view':
        _showAnneeDetails(annee);
        break;
      case 'edit':
        _showEditAnneeDialog(annee);
        break;
      case 'delete':
        _confirmDeleteAnnee(annee);
        break;
    }
  }

  void _showAnneeDetails(Map<String, dynamic> annee) {
    final anneeValue = annee['annee']?.toString() ?? '';
    final nextYear = int.tryParse(anneeValue) != null
        ? (int.parse(anneeValue) + 1).toString()
        : 'N/A';

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    annee['intitule']?.toString() ?? 'Année',
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', annee['id']?.toString() ?? 'N/A'),
                _buildDetailRow(
                    'Intitulé', annee['intitule']?.toString() ?? 'N/A'),
                _buildDetailRow('Année de début', anneeValue),
                _buildDetailRow('Année de fin', nextYear),
                _buildDetailRow('Période complète', '$anneeValue-$nextYear'),
                if (annee['created_at'] != null)
                  _buildDetailRow(
                      'Créée le', _formatDate(annee['created_at']?.toString())),
                if (annee['updated_at'] != null)
                  _buildDetailRow('Modifiée le',
                      _formatDate(annee['updated_at']?.toString())),
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

  void _showEditAnneeDialog(Map<String, dynamic> annee) {
    final intituleController = TextEditingController(
        text: annee['intitule']?.toString() ?? '');
    final anneeController = TextEditingController(
        text: annee['annee']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.edit_rounded, color: Color(0xFFF59E0B)),
                SizedBox(width: 12),
                Text('Modifier l\'année'),
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
                      controller: anneeController,
                      decoration: const InputDecoration(
                        labelText: 'Année de début *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value
                            .trim()
                            .isEmpty) {
                          return 'L\'année est obligatoire';
                        }
                        if (value
                            .trim()
                            .length != 4) {
                          return 'L\'année doit contenir 4 chiffres';
                        }
                        final year = int.tryParse(value.trim());
                        if (year == null || year < 2000 || year > 2050) {
                          return 'Année invalide (2000-2050)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: intituleController,
                      decoration: const InputDecoration(
                        labelText: 'Intitulé *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value
                            .trim()
                            .isEmpty) {
                          return 'L\'intitulé est obligatoire';
                        }
                        return null;
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
                onPressed: () =>
                    _updateAnnee(
                      context,
                      annee['id'],
                      intituleController.text,
                      anneeController.text,
                      formKey,
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Modifier'),
              ),
            ],
          ),
    );
  }

  void _updateAnnee(BuildContext dialogContext,
      int id,
      String intitule,
      String annee,
      GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    try {
      await AnneeService.updateAnnee(
        id: id,
        intitule: intitule.trim(),
        annee: annee.trim(),
      );

      Navigator.pop(dialogContext);
      await _loadAnnees();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Année modifiée avec succès'),
            backgroundColor: Color(0xFFF59E0B),
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

  void _confirmDeleteAnnee(Map<String, dynamic> annee) {
    final anneeValue = annee['annee']?.toString() ?? '';
    final nextYear = int.tryParse(anneeValue) != null
        ? (int.parse(anneeValue) + 1).toString()
        : 'N/A';

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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
                  'Êtes-vous sûr de vouloir supprimer cette année ?',
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
                        annee['intitule']?.toString() ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Période: $anneeValue-$nextYear',
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
                onPressed: () => _deleteAnnee(context, annee['id']),
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

  void _deleteAnnee(BuildContext dialogContext, int id) async {
    try {
      await AnneeService.deleteAnnee(id);

      Navigator.pop(dialogContext);
      await _loadAnnees();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Année supprimée avec succès'),
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