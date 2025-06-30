// lib/screens/quotas_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../services/emploi_du_temps_service.dart';

class QuotasDashboardScreen extends StatefulWidget {
  const QuotasDashboardScreen({Key? key}) : super(key: key);

  @override
  State<QuotasDashboardScreen> createState() => _QuotasDashboardScreenState();
}

class _QuotasDashboardScreenState extends State<QuotasDashboardScreen> {
  List<Map<String, dynamic>> quotas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotas();
  }

  Future<void> _loadQuotas() async {
    setState(() => isLoading = true);

    try {
      final data = await EmploiDuTempsService.getQuotasStatut();
      setState(() {
        quotas = data;
        isLoading = false;
      });

      print('✅ ${quotas.length} quotas chargés');
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Erreur quotas: $e');
      _showError('Erreur: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Color _getProgressColor(double pourcentage) {
    if (pourcentage >= 100) return Colors.green;
    if (pourcentage >= 75) return Colors.blue;
    if (pourcentage >= 50) return Colors.orange;
    if (pourcentage >= 25) return Colors.yellow.shade700;
    return Colors.red;
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'termine': return 'Terminé';
      case 'en_cours': return 'En cours';
      default: return 'Non démarré';
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'termine': return Colors.green;
      case 'en_cours': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Suivi des Quotas Horaires',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotas,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildSummary(),
          Expanded(child: _buildQuotasList()),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    if (quotas.isEmpty) return const SizedBox();

    final totalCompetences = quotas.length;
    final competencesTerminees = quotas.where((q) => q['statut'] == 'termine').length;
    final competencesEnCours = quotas.where((q) => q['statut'] == 'en_cours').length;

    final totalQuotaHeures = quotas.fold<double>(0, (sum, q) => sum + (q['quota_total'] ?? 0));
    final totalPlanifiees = quotas.fold<double>(0, (sum, q) => sum + (q['heures_planifiees'] ?? 0));
    final progressionGlobale = totalQuotaHeures > 0 ? (totalPlanifiees / totalQuotaHeures) * 100 : 0.0; // 👈 Ajout .0

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé général',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Statistiques en grille
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total compétences',
                  value: totalCompetences.toString(),
                  color: Colors.blue,
                  icon: Icons.school,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Terminées',
                  value: competencesTerminees.toString(),
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'En cours',
                  value: competencesEnCours.toString(),
                  color: Colors.orange,
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progression globale
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progression globale',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  Text(
                    '${totalPlanifiees.toStringAsFixed(1)}h / ${totalQuotaHeures.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (progressionGlobale / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getProgressColor(progressionGlobale.toDouble()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${progressionGlobale.toStringAsFixed(1)}% complété',
                style: TextStyle(
                  fontSize: 12,
                  color: _getProgressColor(progressionGlobale.toDouble()),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuotasList() {
    if (quotas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Color(0xFF64748B)),
            SizedBox(height: 16),
            Text(
              'Aucun quota trouvé',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotas.length,
      itemBuilder: (context, index) {
        return _buildQuotaCard(quotas[index]);
      },
    );
  }

  Widget _buildQuotaCard(Map<String, dynamic> quota) {
    final nom = quota['nom']?.toString() ?? 'Compétence inconnue';
    final code = quota['code']?.toString() ?? '';
    final quotaTotal = (quota['quota_total'] ?? 0).toDouble();
    final heuresPlanifiees = (quota['heures_planifiees'] ?? 0).toDouble();
    final heuresRestantes = (quota['heures_restantes'] ?? 0).toDouble();
    final pourcentage = (quota['pourcentage_complete'] ?? 0).toDouble();
    final statut = quota['statut']?.toString() ?? 'en_cours';

    final formateur = quota['formateur'] ?? {};
    final formateurNom = '${formateur['prenom'] ?? ''} ${formateur['nom'] ?? ''}'.trim();
    final metier = quota['metier']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (code.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              nom,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (formateurNom.isNotEmpty || metier.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (formateurNom.isNotEmpty) formateurNom,
                            if (metier.isNotEmpty) metier,
                          ].join(' • '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatutColor(statut).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatutColor(statut).withOpacity(0.3)),
                  ),
                  child: Text(
                    _getStatutLabel(statut),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatutColor(statut),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barre de progression
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${pourcentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(pourcentage),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (pourcentage / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getProgressColor(pourcentage),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Détails des heures
            Row(
              children: [
                Expanded(
                  child: _buildHoursInfo(
                    'Planifiées',
                    '${heuresPlanifiees.toStringAsFixed(1)}h',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildHoursInfo(
                    'Restantes',
                    '${heuresRestantes.toStringAsFixed(1)}h',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildHoursInfo(
                    'Total',
                    '${quotaTotal.toStringAsFixed(1)}h',
                    Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}