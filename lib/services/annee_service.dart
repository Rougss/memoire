import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnneeService {
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

  // Récupérer toutes les années
  static Future<List<Map<String, dynamic>>> getAllAnnees() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/annees'),
        headers: _getHeaders(token),
      );

      print('📡 GET /admin/annees - Status: ${response.statusCode}');

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
      print('❌ Erreur getAllAnnees: $e');
      throw Exception('Impossible de charger les années: $e');
    }
  }

  // Créer une nouvelle année
  static Future<Map<String, dynamic>> createAnnee({
    required String intitule,
    required String annee,
  }) async {
    try {
      final token = await _getToken();

      // Construction explicite du body avec conversion string forcée
      final Map<String, String> body = {
        'intitule': intitule,
        'annee': annee,
      };

      print('🔧 Debug body avant JSON: $body');
      final String jsonBody = jsonEncode(body);
      print('🔧 Debug JSON final: $jsonBody');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/annees'),
        headers: _getHeaders(token),
        body: jsonBody,
      );

      print('📡 POST /admin/annees - Status: ${response.statusCode}');
      print('📤 Body envoyé: $jsonBody');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Année créée avec succès: $data');
        return data is Map<String, dynamic> ? data : {};
      } else {
        print('❌ Erreur API: ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      print('❌ Erreur createAnnee: $e');
      throw Exception('Impossible de créer l\'année: $e');
    }
  }

  // Mettre à jour une année
  static Future<Map<String, dynamic>> updateAnnee({
    required int id,
    required String intitule,
    required String annee,
  }) async {
    try {
      final token = await _getToken();

      // Construction explicite du body avec conversion string forcée
      final Map<String, String> body = {
        'intitule': intitule,
        'annee': annee,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/admin/annees/$id'),
        headers: _getHeaders(token),
        body: jsonEncode(body),
      );

      print('📡 PUT /admin/annees/$id - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : {};
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la modification');
      }
    } catch (e) {
      print('❌ Erreur updateAnnee: $e');
      throw Exception('Impossible de modifier l\'année: $e');
    }
  }

  // Supprimer une année
  static Future<void> deleteAnnee(int id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/annees/$id'),
        headers: _getHeaders(token),
      );

      print('📡 DELETE /admin/annees/$id - Status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      print('❌ Erreur deleteAnnee: $e');
      throw Exception('Impossible de supprimer l\'année: $e');
    }
  }
}