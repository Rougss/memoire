import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SemestreService {
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

  // Récupérer tous les semestres
  static Future<List<Map<String, dynamic>>> getAllSemestres() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/semestres'),
        headers: _getHeaders(token),
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('success') && data['success'] == true) {
          if (data['data'] is List) {
            return List<Map<String, dynamic>>.from(data['data']);
          }
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return await _getSemestresCommun();
        }
      } else {
        return await _getSemestresCommun();
      }
    } catch (e) {
      print('❌ Erreur getAllSemestres: $e');
      return await _getSemestresCommun();
    }
    return [];
  }

  // Endpoint fallback pour récupérer les semestres
  static Future<List<Map<String, dynamic>>> _getSemestresCommun() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/common/semestres'),
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
      print('❌ Erreur _getSemestresCommun: $e');
      return [];
    }
  }

  // Créer un nouveau semestre
  static Future<Map<String, dynamic>> createSemestre({
    required String intitule,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final Map<String, dynamic> body = {
        'intitule': intitule,
      };

      if (dateDebut != null) {
        body['date_debut'] = dateDebut.toIso8601String().split('T')[0]; // Format YYYY-MM-DD
      }

      if (dateFin != null) {
        body['date_fin'] = dateFin.toIso8601String().split('T')[0]; // Format YYYY-MM-DD
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/semestres'),
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
      print('❌ Erreur createSemestre: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la création: $e');
      }
    }
  }

  // Modifier un semestre
  static Future<Map<String, dynamic>> updateSemestre({
    required int id,
    required String intitule,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final Map<String, dynamic> body = {
        'intitule': intitule,
      };

      if (dateDebut != null) {
        body['date_debut'] = dateDebut.toIso8601String().split('T')[0];
      }

      if (dateFin != null) {
        body['date_fin'] = dateFin.toIso8601String().split('T')[0];
      }

      final response = await http.put(
        Uri.parse('$baseUrl/admin/semestres/$id'),
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
      print('❌ Erreur updateSemestre: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la modification: $e');
      }
    }
  }

  // Supprimer un semestre
  static Future<bool> deleteSemestre(int id) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/semestres/$id'),
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
      print('❌ Erreur deleteSemestre: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la suppression: $e');
      }
    }
  }

  // Récupérer un semestre par ID
  static Future<Map<String, dynamic>?> getSemestreById(int id) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/admin/semestres/$id'),
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
      print('❌ Erreur getSemestreById: $e');
      return null;
    }
  }

  // Rechercher des semestres
  static Future<List<Map<String, dynamic>>> searchSemestres(String query) async {
    try {
      final allSemestres = await getAllSemestres();

      if (query.trim().isEmpty) {
        return allSemestres;
      }

      final queryLower = query.toLowerCase().trim();
      return allSemestres.where((semestre) {
        final intitule = (semestre['intitule']?.toString() ?? '').toLowerCase();
        return intitule.contains(queryLower);
      }).toList();
    } catch (e) {
      print('❌ Erreur searchSemestres: $e');
      return [];
    }
  }

  // Vérifier si un intitulé existe déjà
  static Future<bool> checkIntituleExists(String intitule, {int? excludeId}) async {
    try {
      final allSemestres = await getAllSemestres();

      return allSemestres.any((semestre) {
        final semestreId = semestre['id'];
        final semestreIntitule = (semestre['intitule']?.toString() ?? '').toLowerCase().trim();
        final searchIntitule = intitule.toLowerCase().trim();

        // Exclure l'ID spécifié (utile pour la modification)
        if (excludeId != null && semestreId == excludeId) {
          return false;
        }

        return semestreIntitule == searchIntitule;
      });
    } catch (e) {
      print('❌ Erreur checkIntituleExists: $e');
      return false;
    }
  }

  // Obtenir les statistiques des semestres
  static Future<Map<String, int>> getSemestreStats() async {
    try {
      final allSemestres = await getAllSemestres();

      int totalSemestres = allSemestres.length;
      int semestresAvecDates = 0;
      int semestresActifs = 0;

      final now = DateTime.now();

      for (var semestre in allSemestres) {
        // Compter les semestres avec dates
        if (semestre['date_debut'] != null && semestre['date_fin'] != null) {
          semestresAvecDates++;

          // Vérifier si le semestre est actif (en cours)
          try {
            final dateDebut = DateTime.parse(semestre['date_debut']);
            final dateFin = DateTime.parse(semestre['date_fin']);

            if (now.isAfter(dateDebut) && now.isBefore(dateFin)) {
              semestresActifs++;
            }
          } catch (e) {
            // Ignorer les erreurs de parsing de dates
          }
        }
      }

      return {
        'total_semestres': totalSemestres,
        'semestres_avec_dates': semestresAvecDates,
        'semestres_actifs': semestresActifs,
        'semestres_sans_dates': totalSemestres - semestresAvecDates,
      };
    } catch (e) {
      print('❌ Erreur getSemestreStats: $e');
      return {
        'total_semestres': 0,
        'semestres_avec_dates': 0,
        'semestres_actifs': 0,
        'semestres_sans_dates': 0,
      };
    }
  }

  // Obtenir les semestres actifs (en cours)
  static Future<List<Map<String, dynamic>>> getSemestresActifs() async {
    try {
      final allSemestres = await getAllSemestres();
      final now = DateTime.now();

      return allSemestres.where((semestre) {
        if (semestre['date_debut'] == null || semestre['date_fin'] == null) {
          return false;
        }

        try {
          final dateDebut = DateTime.parse(semestre['date_debut']);
          final dateFin = DateTime.parse(semestre['date_fin']);

          return now.isAfter(dateDebut) && now.isBefore(dateFin);
        } catch (e) {
          return false;
        }
      }).toList();
    } catch (e) {
      print('❌ Erreur getSemestresActifs: $e');
      return [];
    }
  }
}