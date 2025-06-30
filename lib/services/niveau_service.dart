import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NiveauService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Remplacez par votre URL de base

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

  // Récupérer tous les niveaux
  static Future<List<Map<String, dynamic>>> getAllNiveaux() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/niveaux'),
        headers: _getHeaders(token),
      );

      print('📡 GET /admin/niveaux - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur getAllNiveaux: $e');
      throw Exception('Impossible de charger les niveaux: $e');
    }
  }

  // Créer un nouveau niveau
  static Future<Map<String, dynamic>> createNiveau({
    required String intitule,
    int? typeFormationId,
  }) async {
    try {
      final token = await _getToken();

      // Construction explicite du body avec conversion string forcée
      final Map<String, String> body = {
        'intitule': intitule,
      };

      if (typeFormationId != null) {
        body['type_formation_id'] = typeFormationId.toString();
      }

      print('🔧 Debug body avant JSON: $body');
      final String jsonBody = jsonEncode(body);
      print('🔧 Debug JSON final: $jsonBody');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/niveaux'),
        headers: _getHeaders(token),
        body: jsonBody,
      );

      print('📡 POST /admin/niveaux - Status: ${response.statusCode}');
      print('📤 Body envoyé: $jsonBody');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Niveau créé avec succès: $data');
        return data is Map<String, dynamic> ? data : {};
      } else {
        print('❌ Erreur API: ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      print('❌ Erreur createNiveau: $e');
      throw Exception('Impossible de créer le niveau: $e');
    }
  }

  // Mettre à jour un niveau
  static Future<Map<String, dynamic>> updateNiveau({
    required int id,
    required String intitule,
    int? typeFormationId,
  }) async {
    try {
      final token = await _getToken();

      // Construction explicite du body avec conversion string forcée
      final Map<String, String> body = {
        'intitule': intitule,
      };

      if (typeFormationId != null) {
        body['type_formation_id'] = typeFormationId.toString();
      }

      final response = await http.put(
        Uri.parse('$baseUrl/admin/niveaux/$id'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      print('📡 PUT /admin/niveaux/$id - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : {};
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la modification');
      }
    } catch (e) {
      print('❌ Erreur updateNiveau: $e');
      throw Exception('Impossible de modifier le niveau: $e');
    }
  }

  // Supprimer un niveau
  static Future<void> deleteNiveau(int id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/niveaux/$id'),
        headers: _getHeaders(token),
      );

      print('📡 DELETE /admin/niveaux/$id - Status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      print('❌ Erreur deleteNiveau: $e');
      throw Exception('Impossible de supprimer le niveau: $e');
    }
  }

  // Récupérer les types de formation pour le dropdown
  static Future<List<Map<String, dynamic>>> getTypesFormation() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/types-formation'),
        headers: _getHeaders(token),
      );

      print('📡 GET /admin/types-formation - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        return [];
      } else {
        // Si l'endpoint n'existe pas, on retourne une liste vide
        return [];
      }
    } catch (e) {
      print('❌ Erreur getTypesFormation: $e');
      return [];
    }
  }
}