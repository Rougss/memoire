import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DepartementService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Récupération du token depuis SharedPreferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print('🔑 Token récupéré: ${token != null ? "✅ Présent" : "❌ Absent"}');
    if (token != null) {
      print('🔑 Token (premiers 20 caractères): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    }
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

  // Récupérer tous les départements
  static Future<List<Map<String, dynamic>>> getAllDepartements() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/departements'),
        headers: headers,
      );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

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

        // Si la réponse contient un objet avec une clé 'departements'
        if (data is Map && data.containsKey('departements')) {
          return List<Map<String, dynamic>>.from(data['departements']);
        }

        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur dans getAllDepartements: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Créer un nouveau département (nouvelle méthode pour la page dédiée)
  static Future<Map<String, dynamic>> createDepartement(Map<String, dynamic> departementData) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode(departementData);

      print('🔍 Création département - Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/departements'),
        headers: headers,
        body: body,
      );

      print('🔍 Create département response status: ${response.statusCode}');
      print('🔍 Create département response body: ${response.body}');

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

        throw Exception(errorData['message'] ?? 'Erreur lors de la création du département');
      }
    } catch (e) {
      print('❌ Erreur dans createDepartement: $e');
      throw Exception('Erreur lors de la création: $e');
    }
  }

  // Ajouter un nouveau département (méthode existante pour le dialog)
  static Future<Map<String, dynamic>> addDepartement(String nom, String description) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'nom': nom,
        'description': description,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/admin/departements'),
        headers: headers,
        body: body,
      );

      print('🔍 Add département response status: ${response.statusCode}');
      print('🔍 Add département response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'ajout du département');
      }
    } catch (e) {
      print('❌ Erreur dans addDepartement: $e');
      throw Exception('Erreur lors de l\'ajout: $e');
    }
  }

  // Modifier un département existant
  static Future<Map<String, dynamic>> updateDepartement(int id, String nom, String description) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'nom': nom,
        'description': description,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/admin/departements/$id'),
        headers: headers,
        body: body,
      );

      print('🔍 Update département response status: ${response.statusCode}');
      print('🔍 Update département response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la modification du département');
      }
    } catch (e) {
      print('❌ Erreur dans updateDepartement: $e');
      throw Exception('Erreur lors de la modification: $e');
    }
  }

  // Modifier un département avec tous les champs (version étendue)
  static Future<Map<String, dynamic>> updateDepartementComplet(int id, Map<String, dynamic> departementData) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode(departementData);

      print('🔍 Modification département complet - Body: $body');

      final response = await http.put(
        Uri.parse('$baseUrl/admin/departements/$id'),
        headers: headers,
        body: body,
      );

      print('🔍 Update département complet response status: ${response.statusCode}');
      print('🔍 Update département complet response body: ${response.body}');

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

        throw Exception(errorData['message'] ?? 'Erreur lors de la modification du département');
      }
    } catch (e) {
      print('❌ Erreur dans updateDepartementComplet: $e');
      throw Exception('Erreur lors de la modification: $e');
    }
  }

  // Supprimer un département
  static Future<void> deleteDepartement(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/departements/$id'),
        headers: headers,
      );

      print('🔍 Delete département response status: ${response.statusCode}');
      print('🔍 Delete département response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression du département');
      }
    } catch (e) {
      print('❌ Erreur dans deleteDepartement: $e');
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // Récupérer un département spécifique par ID
  static Future<Map<String, dynamic>> getDepartementById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/departements/$id'),
        headers: headers,
      );

      print('🔍 Get département by ID response status: ${response.statusCode}');
      print('🔍 Get département by ID response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Si la réponse contient directement les données du département
        if (data is Map<String, dynamic>) {
          return data;
        }

        return {};
      } else {
        throw Exception('Département non trouvé');
      }
    } catch (e) {
      print('❌ Erreur dans getDepartementById: $e');
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  // Rechercher des départements
  static Future<List<Map<String, dynamic>>> searchDepartements(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/departements/search?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );

      print('🔍 Search départements response status: ${response.statusCode}');
      print('🔍 Search départements response body: ${response.body}');

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

        // Si la réponse contient un objet avec une clé 'results'
        if (data is Map && data.containsKey('results')) {
          return List<Map<String, dynamic>>.from(data['results']);
        }

        return [];
      } else {
        throw Exception('Erreur lors de la recherche');
      }
    } catch (e) {
      print('❌ Erreur dans searchDepartements: $e');
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Dans votre DepartementService
  static Future<List<Map<String, dynamic>>> getFormateurs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/formateurs'), // Endpoint pour récupérer les formateurs
        headers: await _getHeaders(),
      );

      print('🔍 Response status getFormateurs: ${response.statusCode}');
      print('🔍 Response body getFormateurs: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifiez la structure de la réponse
        List<Map<String, dynamic>> formateurs;
        if (data is List) {
          formateurs = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          formateurs = List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('Format de réponse inattendu');
        }

        // Ajouter full_name pour l'affichage
        for (var formateur in formateurs) {
          formateur['full_name'] = '${formateur['prenom'] ?? ''} ${formateur['nom'] ?? ''}'.trim();
        }

        print('✅ Formateurs récupérés avec leurs IDs de formateurs:');
        for (var formateur in formateurs) {
          print('  - Formateur ID: ${formateur['id']}, User ID: ${formateur['user_id']}, Nom: ${formateur['full_name']}');
        }

        return formateurs;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur dans getFormateurs: $e');
      rethrow;
    }
  }

  // Récupérer les départements par bâtiment
  static Future<List<Map<String, dynamic>>> getDepartementsByBatiment(int batimentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/departements/batiment/$batimentId'),
        headers: headers,
      );

      print('🔍 Get départements by bâtiment response status: ${response.statusCode}');
      print('🔍 Get départements by bâtiment response body: ${response.body}');

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
        throw Exception('Erreur lors de la récupération des départements');
      }
    } catch (e) {
      print('❌ Erreur dans getDepartementsByBatiment: $e');
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  // Récupérer les départements par utilisateur responsable
  static Future<List<Map<String, dynamic>>> getDepartementsByUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/departements/user/$userId'),
        headers: headers,
      );

      print('🔍 Get départements by user response status: ${response.statusCode}');
      print('🔍 Get départements by user response body: ${response.body}');

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
        throw Exception('Erreur lors de la récupération des départements');
      }
    } catch (e) {
      print('❌ Erreur dans getDepartementsByUser: $e');
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  // Récupérer les départements par formateur
  static Future<List<Map<String, dynamic>>> getDepartementsByFormateur(int formateurId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/departements/formateur/$formateurId'),
        headers: headers,
      );

      print('🔍 Get départements by formateur response status: ${response.statusCode}');
      print('🔍 Get départements by formateur response body: ${response.body}');

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
        throw Exception('Erreur lors de la récupération des départements');
      }
    } catch (e) {
      print('❌ Erreur dans getDepartementsByFormateur: $e');
      throw Exception('Erreur lors de la récupération: $e');
    }
  }

  // Récupérer les statistiques des départements
  static Future<Map<String, dynamic>> getDepartementsStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/departements/stats'),
        headers: headers,
      );

      print('🔍 Get départements stats response status: ${response.statusCode}');
      print('🔍 Get départements stats response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des statistiques');
      }
    } catch (e) {
      print('❌ Erreur dans getDepartementsStats: $e');
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  // Activer/Désactiver un département
  static Future<Map<String, dynamic>> toggleDepartementStatus(int id, bool isActive) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'is_active': isActive,
      });

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/departements/$id/status'),
        headers: headers,
        body: body,
      );

      print('🔍 Toggle département status response status: ${response.statusCode}');
      print('🔍 Toggle département status response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors du changement de statut');
      }
    } catch (e) {
      print('❌ Erreur dans toggleDepartementStatus: $e');
      throw Exception('Erreur lors du changement de statut: $e');
    }
  }

  // Exporter les départements (PDF/Excel)
  static Future<String> exportDepartements({String format = 'pdf'}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/departements/export?format=$format'),
        headers: headers,
      );

      print('🔍 Export départements response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['download_url'] ?? data['file_path'] ?? '';
      } else {
        throw Exception('Erreur lors de l\'export');
      }
    } catch (e) {
      print('❌ Erreur dans exportDepartements: $e');
      throw Exception('Erreur lors de l\'export: $e');
    }
  }

  // Dupliquer un département
  static Future<Map<String, dynamic>> duplicateDepartement(int id, String newName) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'nom_departement': newName,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/admin/departements/$id/duplicate'),
        headers: headers,
        body: body,
      );

      print('🔍 Duplicate département response status: ${response.statusCode}');
      print('🔍 Duplicate département response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la duplication');
      }
    } catch (e) {
      print('❌ Erreur dans duplicateDepartement: $e');
      throw Exception('Erreur lors de la duplication: $e');
    }
  }



  // Archiver un département
  static Future<void> archiveDepartement(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/departements/$id/archive'),
        headers: headers,
      );

      print('🔍 Archive département response status: ${response.statusCode}');
      print('🔍 Archive département response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'archivage');
      }
    } catch (e) {
      print('❌ Erreur dans archiveDepartement: $e');
      throw Exception('Erreur lors de l\'archivage: $e');
    }
  }

  // Restaurer un département archivé
  static Future<void> restoreDepartement(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/departements/$id/restore'),
        headers: headers,
      );

      print('🔍 Restore département response status: ${response.statusCode}');
      print('🔍 Restore département response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la restauration');
      }
    } catch (e) {
      print('❌ Erreur dans restoreDepartement: $e');
      throw Exception('Erreur lors de la restauration: $e');
    }
  }

  // Récupérer l'historique des modifications d'un département
  static Future<List<Map<String, dynamic>>> getDepartementHistory(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/departements/$id/history'),
        headers: headers,
      );

      print('🔍 Get département history response status: ${response.statusCode}');
      print('🔍 Get département history response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }

        if (data is Map && data.containsKey('history')) {
          return List<Map<String, dynamic>>.from(data['history']);
        }

        return [];
      } else {
        throw Exception('Erreur lors de la récupération de l\'historique');
      }
    } catch (e) {
      print('❌ Erreur dans getDepartementHistory: $e');
      throw Exception('Erreur lors de la récupération de l\'historique: $e');
    }
  }
}