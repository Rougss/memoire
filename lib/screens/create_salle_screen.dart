import 'package:flutter/material.dart';
import '../services/batiment_service.dart';
import '../services/salle_service.dart';


class CreateSalleScreen extends StatefulWidget {
  const CreateSalleScreen({Key? key}) : super(key: key);

  @override
  _CreateSalleScreenState createState() => _CreateSalleScreenState();
}

class _CreateSalleScreenState extends State<CreateSalleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _intituleController = TextEditingController();
  final _nombrePlaceController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingBatiments = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _batiments = [];
  int? _selectedBatimentId;

  @override
  void initState() {
    super.initState();
    _loadBatiments();
  }

  Future<void> _loadBatiments() async {
    setState(() => _isLoadingBatiments = true);

    try {
      final batiments = await BatimentService.getAllBatiments();
      setState(() {
        _batiments = batiments;
        _isLoadingBatiments = false;
        // Sélectionner le premier bâtiment par défaut s'il y en a
        if (_batiments.isNotEmpty) {
          _selectedBatimentId = _batiments.first['id'];
        }
      });
      print('✅ ${_batiments.length} bâtiments chargés');
    } catch (e) {
      print('❌ Erreur lors du chargement des bâtiments: $e');
      setState(() => _isLoadingBatiments = false);
      _showError('Erreur lors du chargement des bâtiments: $e');
    }
  }

  Future<void> _createSalle() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBatimentId == null) {
      _showError('Veuillez sélectionner un bâtiment');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final salleData = {
        'intitule': _intituleController.text.trim(),
        'nombre_de_place': int.parse(_nombrePlaceController.text.trim()),
        'batiment_id': _selectedBatimentId,
      };

      print('📤 Données salle à envoyer: $salleData');

      final result = await SalleService.createSalle(
        intitule: _intituleController.text.trim(),
        nombreDePlace: int.parse(_nombrePlaceController.text.trim()),
        batimentId: _selectedBatimentId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Salle "${_intituleController.text}" créée avec succès !'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Erreur lors de la création de la salle: $e');
      if (mounted) {
        _showError('Erreur lors de la création: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Créer une Salle',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingBatiments
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildFormSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message d'erreur
              if (_errorMessage != null) _buildErrorMessage(),

              // Informations de la salle
              _buildSectionHeader(
                'Informations de la salle',
                Icons.meeting_room_rounded,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 20),

              _buildModernTextField(
                controller: _intituleController,
                label: 'Intitulé de la salle',
                icon: Icons.title_rounded,
                required: true,
              ),
              const SizedBox(height: 20),

              _buildModernTextField(
                controller: _nombrePlaceController,
                label: 'Nombre de places',
                icon: Icons.person_rounded,
                keyboardType: TextInputType.number,
                required: true,
              ),
              const SizedBox(height: 20),

              _buildBatimentDropdown(),
              const SizedBox(height: 32),

              // Bouton de création
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: const Color(0xFFFAFAFA),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          alignLabelWithHint: maxLines > 1,
        ),
        validator: required
            ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Ce champ est requis';
          }
          if (keyboardType == TextInputType.number) {
            final number = int.tryParse(value.trim());
            if (number == null || number < 1) {
              return 'Veuillez saisir un nombre valide (≥ 1)';
            }
          } else if (value.trim().length < 2) {
            return 'L\'intitulé doit contenir au moins 2 caractères';
          }
          return null;
        }
            : null,
      ),
    );
  }

  Widget _buildBatimentDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: const Color(0xFFFAFAFA),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedBatimentId,
        decoration: InputDecoration(
          labelText: 'Bâtiment',
          labelStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business_rounded, color: Color(0xFF3B82F6), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        dropdownColor: Colors.white,
        items: _batiments.map<DropdownMenuItem<int>>((batiment) {
          return DropdownMenuItem<int>(
            value: batiment['id'],
            child: Text(
              batiment['intitule']?.toString() ?? 'Bâtiment ${batiment['id']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          );
        }).toList(),
        onChanged: (int? newValue) {
          setState(() {
            _selectedBatimentId = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Veuillez sélectionner un bâtiment';
          }
          return null;
        },
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createSalle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Création en cours...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Créer la Salle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _intituleController.dispose();
    _nombrePlaceController.dispose();
    super.dispose();
  }
}