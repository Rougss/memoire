import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/role.dart';

class RoleService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Obtenir le token d'authentification
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Headers avec authentification
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Récupérer tous les rôles (route publique pour la création de compte)
  static Future<List<Role>> getAllRoles() async {
    try {
      // Pour récupérer les rôles lors de la création de compte,
      // utiliser la route publique qui ne nécessite pas d'authentification
      final response = await http.get(
        Uri.parse('$baseUrl/roles'), // Route publique
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status rôles (public): ${response.statusCode}');
      print('Response body rôles (public): ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        List<dynamic> rolesJson;
        if (jsonData.containsKey('data')) {
          rolesJson = jsonData['data'];
        } else if (jsonData is List) {
          rolesJson = jsonData as List;
        } else {
          throw Exception('Format de réponse inattendu pour les rôles');
        }

        return rolesJson.map((json) => Role.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des rôles: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans getAllRoles: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer tous les rôles (pour les opérations admin authentifiées)
  static Future<List<Role>> getAllRolesAdmin() async {
    try {
      final headers = await _getHeaders();

      // Debug: afficher le token utilisé
      final token = await _getToken();
      print('Token utilisé pour les rôles admin: ${token?.substring(0, 20)}...' ?? 'Aucun token');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/roles'),
        headers: headers,
      );

      print('Response status rôles admin: ${response.statusCode}');
      print('Response body rôles admin: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        List<dynamic> rolesJson;
        if (jsonData.containsKey('data')) {
          rolesJson = jsonData['data'];
        } else if (jsonData is List) {
          rolesJson = jsonData as List;
        } else {
          throw Exception('Format de réponse inattendu pour les rôles');
        }

        return rolesJson.map((json) => Role.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Token d\'authentification expiré ou invalide');
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Vérifiez vos permissions administrateur');
      } else {
        throw Exception('Erreur lors de la récupération des rôles: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans getAllRolesAdmin: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Créer un nouveau rôle (admin seulement)
  static Future<Role> createRole(Role role) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/roles'),
        headers: headers,
        body: json.encode(role.toJson()),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return Role.fromJson(jsonData['data'] ?? jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création du rôle');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création du rôle: $e');
    }
  }

  // Mettre à jour un rôle (admin seulement)
  static Future<Role> updateRole(int id, Role role) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/roles/$id'),
        headers: headers,
        body: json.encode(role.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Role.fromJson(jsonData['data'] ?? jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la mise à jour du rôle');
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du rôle: $e');
    }
  }

  // Supprimer un rôle (admin seulement)
  static Future<void> deleteRole(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/roles/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression du rôle');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression du rôle: $e');
    }
  }
}