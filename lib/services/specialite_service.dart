// services/specialite_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SpecialiteService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Récupérer toutes les spécialités
  static Future<List<Map<String, dynamic>>> getAllSpecialites() async {
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
        Uri.parse('$baseUrl/admin/specialites'),
        headers: headers,
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          // Essayer avec l'endpoint commun si l'admin ne fonctionne pas
          return await _getSpecialitesCommun();
        }
      } else {
        // Essayer avec l'endpoint commun
        return await _getSpecialitesCommun();
      }
    } catch (e) {
      print('❌ Erreur getAllSpecialites: $e');
      // Essayer avec l'endpoint commun en cas d'erreur
      return await _getSpecialitesCommun();
    }
  }

  // Endpoint de fallback
  static Future<List<Map<String, dynamic>>> _getSpecialitesCommun() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/common/specialites'),
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
      print('❌ Erreur _getSpecialitesCommun: $e');
      return [];
    }
  }

  // Créer une nouvelle spécialité
  static Future<Map<String, dynamic>> createSpecialite(Map<String, String?> specialiteData, {
    required String intitule,
    String? description,
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
        'description': description,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/admin/specialites'),
        headers: headers,
        body: body,
      );

      print('🔍 Create response status: ${response.statusCode}');
      print('🔍 Create response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la création');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      print('❌ Erreur createSpecialite: $e');
      throw Exception('Erreur lors de la création: $e');
    }
  }

  // Modifier une spécialité
  static Future<Map<String, dynamic>> updateSpecialite({
    required int id,
    required String intitule,
    String? description,
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
        'description': description,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/admin/specialites/$id'),
        headers: headers,
        body: body,
      );

      print('🔍 Update response status: ${response.statusCode}');
      print('🔍 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la modification');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la modification');
      }
    } catch (e) {
      print('❌ Erreur updateSpecialite: $e');
      throw Exception('Erreur lors de la modification: $e');
    }
  }

  // Supprimer une spécialité
  static Future<bool> deleteSpecialite(int id) async {
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
        Uri.parse('$baseUrl/admin/specialites/$id'),
        headers: headers,
      );

      print('🔍 Delete response status: ${response.statusCode}');
      print('🔍 Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      print('❌ Erreur deleteSpecialite: $e');
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // Récupérer une spécialité par ID
  static Future<Map<String, dynamic>?> getSpecialiteById(int id) async {
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
        Uri.parse('$baseUrl/admin/specialites/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur getSpecialiteById: $e');
      return null;
    }
  }
}