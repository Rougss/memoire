import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MetierService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Récupérer le token d'authentification
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('🔑 Token récupéré: ${token != null ? "✅ Présent" : "❌ Absent"}');
    return token;
  }

  // Headers avec token d'authentification
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 📋 RÉCUPÉRER TOUS LES MÉTIERS
  static Future<List<Map<String, dynamic>>> getAllMetiers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/metiers'),
        headers: headers,
      );

      print('🔍 Response status getAllMetiers: ${response.statusCode}');
      print('🔍 Response body getAllMetiers: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Si la réponse contient directement la liste
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }

        // Si la réponse contient un objet avec une clé 'data'
        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        // Si la réponse contient un objet avec une clé 'metiers'
        if (data is Map && data.containsKey('metiers')) {
          return List<Map<String, dynamic>>.from(data['metiers']);
        }

        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur dans getAllMetiers: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // ➕ CRÉER UN NOUVEAU MÉTIER
  static Future<Map<String, dynamic>> createMetier({
    required String intitule,
    required String duree,
    required int niveauId,
    required int departementId,
    String? description,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'intitule': intitule,
        'duree': duree,
        'niveau_id': niveauId,
        'departement_id': departementId,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      print('🔍 Création métier - Body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/metiers'),
        headers: headers,
        body: json.encode(body),
      );

      print('🔍 Create métier response status: ${response.statusCode}');
      print('🔍 Create métier response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);

        // Gestion des erreurs de validation Laravel
        if (errorData.containsKey('errors')) {
          final errors = errorData['errors'] as Map<String, dynamic>;
          String errorMessage = 'Erreurs de validation:\n';
          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessage += '• ${messages.join(', ')}\n';
            }
          });
          throw Exception(errorMessage.trim());
        }

        throw Exception(errorData['message'] ?? 'Erreur lors de la création du métier');
      }
    } catch (e) {
      print('❌ Erreur dans createMetier: $e');
      throw Exception('Erreur lors de la création: $e');
    }
  }

  // 📝 MODIFIER UN MÉTIER EXISTANT
  static Future<Map<String, dynamic>> updateMetier({
    required int id,
    required String intitule,
    required String duree,
    required int niveauId,
    required int departementId,
    String? description,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'intitule': intitule,
        'duree': duree,
        'niveau_id': niveauId,
        'departement_id': departementId,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      print('🔍 Modification métier - Body: ${json.encode(body)}');

      final response = await http.put(
        Uri.parse('$baseUrl/admin/metiers/$id'),
        headers: headers,
        body: json.encode(body),
      );

      print('🔍 Update métier response status: ${response.statusCode}');
      print('🔍 Update métier response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);

        // Gestion des erreurs de validation Laravel
        if (errorData.containsKey('errors')) {
          final errors = errorData['errors'] as Map<String, dynamic>;
          String errorMessage = 'Erreurs de validation:\n';
          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessage += '• ${messages.join(', ')}\n';
            }
          });
          throw Exception(errorMessage.trim());
        }

        throw Exception(errorData['message'] ?? 'Erreur lors de la modification du métier');
      }
    } catch (e) {
      print('❌ Erreur dans updateMetier: $e');
      throw Exception('Erreur lors de la modification: $e');
    }
  }

  // 🗑️ SUPPRIMER UN MÉTIER
  static Future<void> deleteMetier(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/metiers/$id'),
        headers: headers,
      );

      print('🔍 Delete métier response status: ${response.statusCode}');
      print('🔍 Delete métier response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression du métier');
      }
    } catch (e) {
      print('❌ Erreur dans deleteMetier: $e');
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // 🔍 RÉCUPÉRER UN MÉTIER SPÉCIFIQUE PAR ID
  static Future<Map<String, dynamic>> getMetierById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/metiers/$id'),
        headers: headers,
      );

      print('🔍 Get métier by ID response status: ${response.statusCode}');
      print('🔍 Get métier by ID response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Si la réponse contient directement les données du métier
        if (data is Map<String, dynamic>) {
          return data;
        }

        return {};
      } else {
        throw Exception('Métier non trouvé');
      }
    } catch (e) {
      print('❌ Erreur dans getMetierById: $e');
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  // 📊 RÉCUPÉRER LES NIVEAUX (pour les dropdowns) - Alternative avec admin
  static Future<List<Map<String, dynamic>>> getNiveaux() async {
    try {
      final headers = await _getHeaders();

      // Essayer d'abord common, puis admin si ça échoue
      List<String> endpoints = [
        '$baseUrl/common/niveaux',
        '$baseUrl/admin/niveaux'
      ];

      for (String endpoint in endpoints) {
        try {
          print('🔍 Test endpoint niveaux: $endpoint');

          final response = await http.get(
            Uri.parse(endpoint),
            headers: headers,
          );

          print('🔍 Response status getNiveaux: ${response.statusCode}');
          print('🔍 Response body getNiveaux: ${response.body}');

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            if (data is List) {
              print('✅ Niveaux trouvés avec endpoint: $endpoint');
              return List<Map<String, dynamic>>.from(data);
            }

            if (data is Map && data.containsKey('data')) {
              print('✅ Niveaux trouvés avec endpoint: $endpoint');
              return List<Map<String, dynamic>>.from(data['data']);
            }
          }
        } catch (e) {
          print('❌ Échec endpoint $endpoint: $e');
          continue;
        }
      }

      return [];
    } catch (e) {
      print('❌ Erreur dans getNiveaux: $e');
      throw Exception('Erreur: $e');
    }
  }

  // 🏢 RÉCUPÉRER LES DÉPARTEMENTS (pour les dropdowns) - Alternative avec admin
  static Future<List<Map<String, dynamic>>> getDepartements() async {
    try {
      final headers = await _getHeaders();

      // Essayer d'abord common, puis admin si ça échoue
      List<String> endpoints = [
        '$baseUrl/common/departements',
        '$baseUrl/admin/departements'
      ];

      for (String endpoint in endpoints) {
        try {
          print('🔍 Test endpoint départements: $endpoint');

          final response = await http.get(
            Uri.parse(endpoint),
            headers: headers,
          );

          print('🔍 Response status getDepartements: ${response.statusCode}');
          print('🔍 Response body getDepartements: ${response.body}');

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            if (data is List) {
              print('✅ Départements trouvés avec endpoint: $endpoint');
              return List<Map<String, dynamic>>.from(data);
            }

            if (data is Map && data.containsKey('data')) {
              print('✅ Départements trouvés avec endpoint: $endpoint');
              return List<Map<String, dynamic>>.from(data['data']);
            }
          }
        } catch (e) {
          print('❌ Échec endpoint $endpoint: $e');
          continue;
        }
      }

      return [];
    } catch (e) {
      print('❌ Erreur dans getDepartements: $e');
      throw Exception('Erreur: $e');
    }
  }

  // 🔍 RECHERCHER DES MÉTIERS
  static Future<List<Map<String, dynamic>>> searchMetiers(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/metiers/search?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );

      print('🔍 Search métiers response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }

        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        if (data is Map && data.containsKey('results')) {
          return List<Map<String, dynamic>>.from(data['results']);
        }

        return [];
      } else {
        throw Exception('Erreur lors de la recherche');
      }
    } catch (e) {
      print('❌ Erreur dans searchMetiers: $e');
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // 📊 RÉCUPÉRER LES MÉTIERS PAR DÉPARTEMENT
  static Future<List<Map<String, dynamic>>> getMetiersByDepartement(int departementId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/metiers/departement/$departementId'),
        headers: headers,
      );

      print('🔍 Get métiers by département response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }

        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        return [];
      } else {
        throw Exception('Erreur lors de la récupération des métiers');
      }
    } catch (e) {
      print('❌ Erreur dans getMetiersByDepartement: $e');
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  // 📊 RÉCUPÉRER LES MÉTIERS PAR NIVEAU
  static Future<List<Map<String, dynamic>>> getMetiersByNiveau(int niveauId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/metiers/niveau/$niveauId'),
        headers: headers,
      );

      print('🔍 Get métiers by niveau response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }

        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        return [];
      } else {
        throw Exception('Erreur lors de la récupération des métiers');
      }
    } catch (e) {
      print('❌ Erreur dans getMetiersByNiveau: $e');
      throw Exception('Erreur lors de la récupération: $e');
    }
  }
}