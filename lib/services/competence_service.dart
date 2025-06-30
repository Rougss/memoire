import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CompetenceService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ??
        prefs.getString('token') ??
        prefs.getString('access_token') ??
        prefs.getString('user_token');
  }

  static Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Récupérer toutes les compétences
  static Future<List<Map<String, dynamic>>> getAllCompetences() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/competences'),
        headers: _getHeaders(token),
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return await _getCompetencesCommun();
        }
      } else {
        return await _getCompetencesCommun();
      }
    } catch (e) {
      print('❌ Erreur getAllCompetences: $e');
      return await _getCompetencesCommun();
    }
  }

  // Endpoint fallback pour récupérer les compétences
  static Future<List<Map<String, dynamic>>> _getCompetencesCommun() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/common/competences'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('❌ Erreur _getCompetencesCommun: $e');
      return [];
    }
  }

  // Créer une nouvelle compétence
  static Future<Map<String, dynamic>> createCompetence({
    required String nom,
    required String code,
    required String numeroCompetence,
    double? quotaHoraire,
    required int metierId,
    required int formateurId,
    required int salleId,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final Map<String, dynamic> body = {
        'nom': nom,
        'code': code,
        'numero_competence': numeroCompetence,
        'metier_id': metierId,
        'formateur_id': formateurId,
        'salle_id': salleId,
      };

      if (quotaHoraire != null) {
        body['quota_horaire'] = quotaHoraire;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/competences'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      print('🔍 Create response status: ${response.statusCode}');
      print('🔍 Create response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          if (data.containsKey('success') && data['success'] == true) {
            return data['data'] ?? data;
          } else if (data.containsKey('id')) {
            return data;
          } else if (data.containsKey('message')) {
            throw Exception(data['message']);
          }
        }

        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur createCompetence: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la création: $e');
      }
    }
  }

  // Modifier une compétence
  static Future<Map<String, dynamic>> updateCompetence({
    required int id,
    required String nom,
    required String code,
    required String numeroCompetence,
    double? quotaHoraire,
    required int metierId,
    required int formateurId,
    required int salleId,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final Map<String, dynamic> body = {
        'nom': nom,
        'code': code,
        'numero_competence': numeroCompetence,
        'metier_id': metierId,
        'formateur_id': formateurId,
        'salle_id': salleId,
      };

      if (quotaHoraire != null) {
        body['quota_horaire'] = quotaHoraire;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/admin/competences/$id'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      print('🔍 Update response status: ${response.statusCode}');
      print('🔍 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          if (data.containsKey('success') && data['success'] == true) {
            return data['data'] ?? data;
          } else if (data.containsKey('id')) {
            return data;
          } else if (data.containsKey('message')) {
            throw Exception(data['message']);
          }
        }

        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la modification (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur updateCompetence: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la modification: $e');
      }
    }
  }

  // Supprimer une compétence
  static Future<bool> deleteCompetence(int id) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/competences/$id'),
        headers: _getHeaders(token),
      );

      print('🔍 Delete response status: ${response.statusCode}');
      print('🔍 Delete response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.statusCode == 204) {
          return true;
        }

        final data = jsonDecode(response.body);
        if (data is Map) {
          return data['success'] == true || data.containsKey('message');
        }
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur deleteCompetence: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la suppression: $e');
      }
    }
  }

  // Récupérer une compétence par ID
  static Future<Map<String, dynamic>?> getCompetenceById(int id) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/admin/competences/$id'),
        headers: _getHeaders(token),
      );

      print('🔍 GetById response status: ${response.statusCode}');
      print('🔍 GetById response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          if (data.containsKey('success') && data['success'] == true) {
            return data['data'];
          } else if (data.containsKey('id')) {
            return data;
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur getCompetenceById: $e');
      return null;
    }
  }

  // Récupérer les métiers pour le dropdown
  static Future<List<Map<String, dynamic>>> getMetiers() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/metiers'),
        headers: _getHeaders(token),
      );

      print('📡 GET /admin/metiers - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        return [];
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Erreur getMetiers: $e');
      return [];
    }
  }

  // Récupérer les formateurs pour le dropdown
  // 🔥 SOLUTION RAPIDE: Mapper par formateur_id au lieu de user_id
  static Future<List<Map<String, dynamic>>> getFormateurs() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/admin/formateurs'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> formateurs = [];

        if (data is Map && data['success'] == true && data['data'] is List) {
          formateurs = List<Map<String, dynamic>>.from(data['data']);
        }

        // 🔥 MAPPER PAR FORMATEUR_ID (pas user_id)
        final List<Map<String, dynamic>> formateursPourAffichage = [];

        for (var formateur in formateurs) {
          final user = formateur['user'] as Map<String, dynamic>?;
          if (user != null) {
            final Map<String, dynamic> formateurFormate = {
              // 🔥 UTILISER L'ID DE FORMATEUR (pas user_id)
              'id': formateur['id'], // ← C'est ça que les compétences utilisent !
              'user_id': formateur['user_id'],
              'nom': user['nom'] ?? '',
              'prenom': user['prenom'] ?? '',
              'full_name': '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim(),
              'specialite': formateur['specialite'],
            };

            formateursPourAffichage.add(formateurFormate);
            print('✅ Formateur: formateur_id=${formateur['id']}, user_id=${formateur['user_id']}, nom=${formateurFormate['full_name']}');
          }
        }

        return formateursPourAffichage;

      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur dans getFormateurs: $e');
      rethrow;
    }
  }

  // Récupérer les salles pour le dropdown
  static Future<List<Map<String, dynamic>>> getSalles() async {
    try {
      final token = await _getToken();

      // Essayer d'abord avec /admin/salles
      var response = await http.get(
        Uri.parse('$baseUrl/admin/salles'),
        headers: _getHeaders(token),
      );

      print('📡 GET /admin/salles - Status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      // Si ça ne marche pas, essayer avec /salles (comme pour formateurs)
      if (response.statusCode != 200) {
        print('🔄 Essai avec /salles...');
        response = await http.get(
          Uri.parse('$baseUrl/salles'),
          headers: _getHeaders(token),
        );
        print('📡 GET /salles - Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          final salles = List<Map<String, dynamic>>.from(data);

          print('✅ Salles récupérées:');
          for (var salle in salles.take(3)) {
            print('  - Salle ID: ${salle['id']}, Nom: ${salle['intitule'] ?? salle['nom']}, Bâtiment: ${salle['batiment']?['intitule'] ?? 'N/A'}');
          }

          return salles;
        } else if (data is Map && data.containsKey('data') && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is Map && data.containsKey('success') && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('❌ Format de réponse salles inattendu: ${data.runtimeType}');
          return [];
        }
      } else {
        print('❌ Erreur API salles: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur getSalles: $e');
      return [];
    }
  }

  // Rechercher des compétences
  static Future<List<Map<String, dynamic>>> searchCompetences(String query) async {
    try {
      final allCompetences = await getAllCompetences();

      if (query.trim().isEmpty) {
        return allCompetences;
      }

      final queryLower = query.toLowerCase().trim();
      return allCompetences.where((competence) {
        final nom = (competence['nom']?.toString() ?? '').toLowerCase();
        final code = (competence['code']?.toString() ?? '').toLowerCase();
        return nom.contains(queryLower) || code.contains(queryLower);
      }).toList();
    } catch (e) {
      print('❌ Erreur searchCompetences: $e');
      return [];
    }
  }

  // Obtenir les statistiques des compétences
  static Future<Map<String, int>> getCompetenceStats() async {
    try {
      final allCompetences = await getAllCompetences();

      int totalCompetences = allCompetences.length;
      int competencesAvecQuota = 0;
      double totalQuotaHoraire = 0;

      for (var competence in allCompetences) {
        final quotaValue = competence['quota_horaire'];
        double? quota;

        // Gérer les différents types de quota_horaire
        if (quotaValue != null) {
          if (quotaValue is String) {
            quota = double.tryParse(quotaValue);
          } else if (quotaValue is num) {
            quota = quotaValue.toDouble();
          }

          if (quota != null && quota > 0) {
            competencesAvecQuota++;
            totalQuotaHoraire += quota;
          }
        }
      }

      return {
        'total_competences': totalCompetences,
        'competences_avec_quota': competencesAvecQuota,
        'total_quota_horaire': totalQuotaHoraire.round(),
        'competences_sans_quota': totalCompetences - competencesAvecQuota,
      };
    } catch (e) {
      print('❌ Erreur getCompetenceStats: $e');
      return {
        'total_competences': 0,
        'competences_avec_quota': 0,
        'total_quota_horaire': 0,
        'competences_sans_quota': 0,
      };
    }
  }
}