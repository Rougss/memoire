import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TypeFormationService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Récupérer tous les types de formation
  static Future<List<Map<String, dynamic>>> getAllTypeFormations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('user_token');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/types-formation'),
        headers: headers,
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          // Ici data est directement une liste JSON
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] is List) {
          // Si tu as un objet enveloppant avec "data"
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          // Sinon fallback
          return await _getTypeFormationsCommun();
        }
      } else {
        return await _getTypeFormationsCommun();
      }
    } catch (e) {
      print('❌ Erreur getAllTypeFormations: $e');
      return await _getTypeFormationsCommun();
    }
  }

  // Endpoint fallback pour récupérer les types de formation
  static Future<List<Map<String, dynamic>>> _getTypeFormationsCommun() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/common/types-formation'),
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
      print('❌ Erreur _getTypeFormationsCommun: $e');
      return [];
    }
  }

  // Créer un nouveau type de formation
  static Future<Map<String, dynamic>> createTypeFormation({
    required String intitule,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('user_token');

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'intitule': intitule,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/admin/types-formation'),
        headers: headers,
        body: body,
      );

      print('🔍 Create response status: ${response.statusCode}');
      print('🔍 Create response body: ${response.body}');

      // ✅ CORRECTION : Gérer la réponse selon sa structure réelle
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Votre API retourne directement l'objet créé
        // {"intitule":"Formation Pro","updated_at":"...","created_at":"...","id":5}
        if (data is Map<String, dynamic>) {
          // Si la réponse a une structure avec success/data
          if (data.containsKey('success') && data['success'] == true) {
            return data['data'] ?? data;
          }
          // Si la réponse est directement l'objet créé (votre cas)
          else if (data.containsKey('id')) {
            return data;
          }
          // Si il y a une erreur dans la réponse
          else if (data.containsKey('message')) {
            throw Exception(data['message']);
          }
        }

        // Fallback - retourner la data telle quelle
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur createTypeFormation: $e');
      // Ne pas double-wrapper l'exception
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la création: $e');
      }
    }
  }

  // Modifier un type de formation
  static Future<Map<String, dynamic>> updateTypeFormation({
    required int id,
    required String intitule,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('user_token');

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'intitule': intitule,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/admin/types-formation/$id'),
        headers: headers,
        body: body,
      );

      print('🔍 Update response status: ${response.statusCode}');
      print('🔍 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Même logique que pour create
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
      print('❌ Erreur updateTypeFormation: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la modification: $e');
      }
    }
  }

  // Supprimer un type de formation
  static Future<bool> deleteTypeFormation(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('user_token');

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/types-formation/$id'),
        headers: headers,
      );

      print('🔍 Delete response status: ${response.statusCode}');
      print('🔍 Delete response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Code 204 = No Content (suppression réussie sans contenu)
        if (response.statusCode == 204) {
          return true;
        }

        final data = jsonDecode(response.body);
        // Gérer différentes structures de réponse
        if (data is Map) {
          return data['success'] == true || data.containsKey('message');
        }
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur deleteTypeFormation: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la suppression: $e');
      }
    }
  }

  // Récupérer un type de formation par ID
  static Future<Map<String, dynamic>?> getTypeFormationById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('user_token');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/types-formation/$id'),
        headers: headers,
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
      print('❌ Erreur getTypeFormationById: $e');
      return null;
    }
  }

  // Rechercher des types de formation par intitulé
  static Future<List<Map<String, dynamic>>> searchTypeFormations(String query) async {
    try {
      final allTypeFormations = await getAllTypeFormations();

      if (query.trim().isEmpty) {
        return allTypeFormations;
      }

      final queryLower = query.toLowerCase().trim();
      return allTypeFormations.where((type) {
        final intitule = (type['intitule']?.toString() ?? '').toLowerCase();
        return intitule.contains(queryLower);
      }).toList();
    } catch (e) {
      print('❌ Erreur searchTypeFormations: $e');
      return [];
    }
  }

  // Vérifier si un intitulé existe déjà
  static Future<bool> checkIntituleExists(String intitule, {int? excludeId}) async {
    try {
      final allTypeFormations = await getAllTypeFormations();

      return allTypeFormations.any((type) {
        final typeId = type['id'];
        final typeIntitule = (type['intitule']?.toString() ?? '').toLowerCase().trim();
        final searchIntitule = intitule.toLowerCase().trim();

        // Exclure l'ID spécifié (utile pour la modification)
        if (excludeId != null && typeId == excludeId) {
          return false;
        }

        return typeIntitule == searchIntitule;
      });
    } catch (e) {
      print('❌ Erreur checkIntituleExists: $e');
      return false; // En cas d'erreur, on assume que l'intitulé n'existe pas
    }
  }

  // Obtenir les statistiques des types de formation
  static Future<Map<String, int>> getTypeFormationStats() async {
    try {
      final allTypeFormations = await getAllTypeFormations();

      int totalTypes = allTypeFormations.length;
      int typesAvecMetiers = 0;
      int totalMetiers = 0;

      for (var type in allTypeFormations) {
        if (type['metiers'] != null && type['metiers'].isNotEmpty) {
          typesAvecMetiers++;
          totalMetiers += (type['metiers'] as List).length;
        }
      }

      return {
        'total_types': totalTypes,
        'types_avec_metiers': typesAvecMetiers,
        'total_metiers': totalMetiers,
        'types_sans_metiers': totalTypes - typesAvecMetiers,
      };
    } catch (e) {
      print('❌ Erreur getTypeFormationStats: $e');
      return {
        'total_types': 0,
        'types_avec_metiers': 0,
        'total_metiers': 0,
        'types_sans_metiers': 0,
      };
    }
  }
}