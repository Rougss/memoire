import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BatimentService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Récupérer tous les bâtiments
  static Future<List<Map<String, dynamic>>> getAllBatiments() async {
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
        Uri.parse('$baseUrl/admin/batiments'),
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
          return await _getBatimentsCommun();
        }
      } else {
        return await _getBatimentsCommun();
      }
    } catch (e) {
      print('❌ Erreur getAllBatiments: $e');
      return await _getBatimentsCommun();
    }
  }

  // Endpoint fallback pour récupérer les bâtiments
  static Future<List<Map<String, dynamic>>> _getBatimentsCommun() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/common/batiments'),
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
      print('❌ Erreur _getBatimentsCommun: $e');
      return [];
    }
  }

  // Créer un nouveau bâtiment
  static Future<Map<String, dynamic>> createBatiment({
    required String intitule,
    required String adresse,
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
        'adresse': adresse,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/admin/batiments'),
        headers: headers,
        body: body,
      );

      print('🔍 Create response status: ${response.statusCode}');
      print('🔍 Create response body: ${response.body}');

      // ✅ CORRECTION : Gérer la réponse selon sa structure réelle
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Votre API retourne directement l'objet créé
        // {"intitule":"Batiment D","updated_at":"...","created_at":"...","id":5}
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
      print('❌ Erreur createBatiment: $e');
      // Ne pas double-wrapper l'exception
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la création: $e');
      }
    }
  }

  // Modifier un bâtiment
  static Future<Map<String, dynamic>> updateBatiment({
    required int id,
    required String intitule,
    required String adresse,
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
        'adresse': adresse,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/admin/batiments/$id'),
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
      print('❌ Erreur updateBatiment: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la modification: $e');
      }
    }
  }

  // Supprimer un bâtiment
  static Future<bool> deleteBatiment(int id) async {
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
        Uri.parse('$baseUrl/admin/batiments/$id'),
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
      print('❌ Erreur deleteBatiment: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de la suppression: $e');
      }
    }
  }

  // Récupérer un bâtiment par ID
  static Future<Map<String, dynamic>?> getBatimentById(int id) async {
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
        Uri.parse('$baseUrl/admin/batiments/$id'),
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
      print('❌ Erreur getBatimentById: $e');
      return null;
    }
  }
}