import 'package:flutter/material.dart';
import '../services/semestre_service.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'create_semestre_screen.dart';

class SemestreManageScreen extends StatefulWidget {
  const SemestreManageScreen({super.key});

  @override
  State<SemestreManageScreen> createState() => _SemestreManageScreenState();
}

class _SemestreManageScreenState extends State<SemestreManageScreen> {
  List<Map<String, dynamic>> semestres = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSemestres();
  }

  Future<void> _loadSemestres() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await SemestreService.getAllSemestres();
      setState(() {
        semestres = data;
        isLoading = false;
      });

      print('✅ TOTAL semestres chargés: ${semestres.length}');

      // Debug pour voir les données
      for (int i = 0; i < semestres.length && i < 3; i++) {
        final sem = semestres[i];
        print('📅 Semestre $i: ${sem['intitule']} - ID: ${sem['id']}');
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

  List<Map<String, dynamic>> get filteredSemestres {
    return semestres.where((sem) {
      final queryLower = searchQuery.toLowerCase();
      final intitule = (sem['intitule']?.toString() ?? '').toLowerCase();

      return intitule.contains(queryLower);
    }).toList();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Non définie';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Non définie';
    }
  }

  bool _isSemestreActif(Map<String, dynamic> semestre) {
    if (semestre['date_debut'] == null || semestre['date_fin'] == null) {
      return false;
    }

    try {
      final now = DateTime.now();
      final dateDebut = DateTime.parse(semestre['date_debut']);
      final dateFin = DateTime.parse(semestre['date_fin']);

      return now.isAfter(dateDebut) && now.isBefore(dateFin);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des semestres',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateSemestreScreen()),
          ).then((_) => _loadSemestres());
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau semestre'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Header avec recherche
          _buildSearchHeader(),

          // Liste des semestres
          Expanded(
            child: isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitThreeInOut(
                    color: Color(0xFF7C3AED),
                    size: 30.0,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des semestres...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : filteredSemestres.isEmpty
                ? _buildEmptyState()
                : _buildSemestresList(),
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
            hintText: 'Rechercher un semestre...',
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

  Widget _buildSemestresList() {
    return Column(
      children: [
        // Compteur
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${filteredSemestres.length} semestre(s) trouvé(s) sur ${semestres.length} au total',
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
            onRefresh: _loadSemestres,
            color: const Color(0xFF7C3AED),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredSemestres.length,
              itemBuilder: (context, index) {
                return _buildSemestreCard(filteredSemestres[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSemestreCard(Map<String, dynamic> semestre) {
    final String intitule = semestre['intitule']?.toString() ?? 'N/A';
    final bool isActif = _isSemestreActif(semestre);
    final String dateDebut = _formatDate(semestre['date_debut']?.toString());
    final String dateFin = _formatDate(semestre['date_fin']?.toString());

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
          color: isActif ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
          width: isActif ? 2 : 1,
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
                // Icône de semestre avec statut
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActif
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActif ? Icons.schedule_rounded : Icons.calendar_month_rounded,
                    color: isActif ? const Color(0xFF10B981) : const Color(0xFF7C3AED),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Informations semestre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Intitulé avec badge actif
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              intitule,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (isActif) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ACTIF',
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

                      const SizedBox(height: 8),

                      // Dates
                      Row(
                        children: [
                          Icon(
                            Icons.date_range_rounded,
                            size: 14,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$dateDebut → $dateFin',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
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
                          Icon(Icons.edit_rounded, size: 18, color: Color(0xFF7C3AED)),
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
                  onSelected: (value) => _handleSemestreAction(value, semestre),
                ),
              ],
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
            'Aucun semestre trouvé',
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
                : 'Commencez par ajouter des semestres',
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

  void _handleSemestreAction(String action, Map<String, dynamic> semestre) {
    switch (action) {
      case 'view':
        _showSemestreDetails(semestre);
        break;
      case 'edit':
        _showEditSemestreDialog(semestre);
        break;
      case 'delete':
        _confirmDeleteSemestre(semestre);
        break;
    }
  }

  void _showSemestreDetails(Map<String, dynamic> semestre) {
    final bool isActif = _isSemestreActif(semestre);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isActif ? Icons.schedule_rounded : Icons.calendar_month_rounded,
                color: const Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                semestre['intitule']?.toString() ?? 'Semestre',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', semestre['id']?.toString() ?? 'N/A'),
            _buildDetailRow('Intitulé', semestre['intitule']?.toString() ?? 'N/A'),
            _buildDetailRow('Date de début', _formatDate(semestre['date_debut']?.toString())),
            _buildDetailRow('Date de fin', _formatDate(semestre['date_fin']?.toString())),
            _buildDetailRow('Statut', isActif ? 'Actif' : 'Inactif'),
            if (semestre['created_at'] != null)
              _buildDetailRow('Créé le', _formatDate(semestre['created_at']?.toString())),
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

  void _showEditSemestreDialog(Map<String, dynamic> semestre) {
    final intituleController = TextEditingController(text: semestre['intitule']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime? dateDebut;
    DateTime? dateFin;

    // Parser les dates existantes
    try {
      if (semestre['date_debut'] != null) {
        dateDebut = DateTime.parse(semestre['date_debut']);
      }
      if (semestre['date_fin'] != null) {
        dateFin = DateTime.parse(semestre['date_fin']);
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: Color(0xFF7C3AED)),
              SizedBox(width: 12),
              Text('Modifier le semestre'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Intitulé
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

                // Date de début
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateDebut ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        dateDebut = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded),
                        const SizedBox(width: 12),
                        Text(
                          dateDebut != null
                              ? 'Début: ${_formatDate(dateDebut.toString())}'
                              : 'Sélectionner date de début',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date de fin
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateFin ?? DateTime.now(),
                      firstDate: dateDebut ?? DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        dateFin = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded),
                        const SizedBox(width: 12),
                        Text(
                          dateFin != null
                              ? 'Fin: ${_formatDate(dateFin.toString())}'
                              : 'Sélectionner date de fin',
                        ),
                      ],
                    ),
                  ),
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
              onPressed: () => _updateSemestre(
                context,
                semestre['id'],
                intituleController.text,
                dateDebut,
                dateFin,
                formKey,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSemestre(BuildContext dialogContext, int id, String intitule,
      DateTime? dateDebut, DateTime? dateFin, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    try {
      await SemestreService.updateSemestre(
        id: id,
        intitule: intitule.trim(),
        dateDebut: dateDebut,
        dateFin: dateFin,
      );

      Navigator.pop(dialogContext);
      await _loadSemestres();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semestre modifié avec succès'),
            backgroundColor: Color(0xFF7C3AED),
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

  void _confirmDeleteSemestre(Map<String, dynamic> semestre) {
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
              'Êtes-vous sûr de vouloir supprimer ce semestre ?',
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
                    semestre['intitule']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Période: ${_formatDate(semestre['date_debut']?.toString())} → ${_formatDate(semestre['date_fin']?.toString())}',
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
            onPressed: () => _deleteSemestre(context, semestre['id']),
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

  void _deleteSemestre(BuildContext dialogContext, int id) async {
    try {
      await SemestreService.deleteSemestre(id);

      Navigator.pop(dialogContext);
      await _loadSemestres();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semestre supprimé avec succès'),
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