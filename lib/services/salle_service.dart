import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SalleService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Récupérer toutes les salles
  static Future<List<Map<String, dynamic>>> getAllSalles() async {
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
        Uri.parse('$baseUrl/admin/salles'),
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
          return await _getSallesCommun();
        }
      } else {
        return await _getSallesCommun();
      }
    } catch (e) {
      print('❌ Erreur getAllSalles: $e');
      return await _getSallesCommun();
    }
  }

  // Endpoint fallback pour récupérer les salles
  static Future<List<Map<String, dynamic>>> _getSallesCommun() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/common/salles'),
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
      print('❌ Erreur _getSallesCommun: $e');
      return [];
    }
  }

  // Créer une nouvelle salle - VERSION CORRIGÉE
  static Future createSalle({
    required String intitule,
    required int nombreDePlace,
    required int batimentId,
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
        'nombre_de_place': nombreDePlace,
        'batiment_id': batimentId,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/admin/salles'),
        headers: headers,
        body: body,
      );

      print('🔍 Create response status: ${response.statusCode}');
      print('🔍 Create response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Vérifier si c'est un objet avec success/data
        if (data is Map && data.containsKey('success')) {
          if (data['success'] == true) {
            return data['data'];
          } else {
            throw Exception(data['message'] ?? 'Erreur lors de la création');
          }
        }
        // Sinon, retourner directement l'objet (cas de ton API)
        else if (data is Map) {
          return data;
        } else {
          throw Exception('Format de réponse inattendu');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      print('❌ Erreur createSalle: $e');
      throw Exception('Erreur lors de la création: $e');
    }
  }

  // Modifier une salle - VERSION CORRIGÉE
  static Future updateSalle({
    required int id,
    required String intitule,
    required int nombreDePlace,
    required int batimentId,
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
        'nombre_de_place': nombreDePlace,
        'batiment_id': batimentId,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/admin/salles/$id'),
        headers: headers,
        body: body,
      );

      print('🔍 Update response status: ${response.statusCode}');
      print('🔍 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Vérifier si c'est un objet avec success/data
        if (data is Map && data.containsKey('success')) {
          if (data['success'] == true) {
            return data['data'];
          } else {
            throw Exception(data['message'] ?? 'Erreur lors de la modification');
          }
        }
        // Sinon, retourner directement l'objet
        else if (data is Map) {
          return data;
        } else {
          throw Exception('Format de réponse inattendu');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la modification');
      }
    } catch (e) {
      print('❌ Erreur updateSalle: $e');
      throw Exception('Erreur lors de la modification: $e');
    }
  }

  // Supprimer une salle - VERSION CORRIGÉE
  static Future<bool> deleteSalle(int id) async {
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
        Uri.parse('$baseUrl/admin/salles/$id'),
        headers: headers,
      );

      print('🔍 Delete response status: ${response.statusCode}');
      print('🔍 Delete response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Si pas de contenu (204) c'est OK
        if (response.statusCode == 204) {
          return true;
        }

        final data = jsonDecode(response.body);

        // Vérifier si c'est un objet avec success
        if (data is Map && data.containsKey('success')) {
          return data['success'] == true;
        }
        // Sinon considérer comme succès si status 200
        else {
          return true;
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      print('❌ Erreur deleteSalle: $e');
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // Récupérer une salle par ID - VERSION CORRIGÉE
  static Future getSalleById(int id) async {
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
        Uri.parse('$baseUrl/admin/salles/$id'),
        headers: headers,
      );

      print('🔍 GetById response status: ${response.statusCode}');
      print('🔍 GetById response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Vérifier si c'est un objet avec success/data
        if (data is Map && data.containsKey('success')) {
          if (data['success'] == true) {
            return data['data'];
          }
        }
        // Sinon, retourner directement l'objet
        else if (data is Map) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur getSalleById: $e');
      return null;
    }
  }
}