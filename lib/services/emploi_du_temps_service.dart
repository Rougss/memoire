// lib/services/emploi_du_temps_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmploiDuTempsService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Récupérer le token d'authentification
  // Dans emploi_du_temps_service.dart, remplace la méthode _getToken()
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    // Essaie toutes les clés possibles comme BatimentService
    String? token = prefs.getString('auth_token') ??
        prefs.getString('token') ??
        prefs.getString('access_token') ??
        prefs.getString('user_token');

    print('🔑 Token trouvé: ${token ?? "AUCUN"}');
    print('🔑 Toutes les clés: ${prefs.getKeys()}');

    return token;
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

  // 📅 RÉCUPÉRER TOUS LES EMPLOIS DU TEMPS
  static Future<List<Map<String, dynamic>>> getAllEmplois() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps'),
        headers: headers,
      );

      print('📅 Réponse getAllEmplois: ${response.statusCode}');
      print('📅 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la récupération');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getAllEmplois: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // ➕ CRÉER UN NOUVEAU CRÉNEAU
  static Future<Map<String, dynamic>> creerCreneau({
    required int anneeId,
    required String heureDebut,
    required String heureFin,
    required String dateDebut,
    required String dateFin,
    List<int>? competences,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'annee_id': anneeId,
        'heure_debut': heureDebut,
        'heure_fin': heureFin,
        'date_debut': dateDebut,
        'date_fin': dateFin,
        if (competences != null && competences.isNotEmpty)
          'competences': competences,
      };

      print('➕ Création créneau: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps'),
        headers: headers,
        body: json.encode(body),
      );

      print('➕ Réponse création: ${response.statusCode}');
      print('➕ Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      print('❌ Erreur creerCreneau: $e');
      throw Exception('Erreur de création: $e');
    }
  }

  // 🤖 GÉNÉRATION AUTOMATIQUE
  static Future<Map<String, dynamic>> genererAutomatique({
    required int departementId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'departement_id': departementId,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };

      print('🤖 Génération auto: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/generer-auto'),
        headers: headers,
        body: json.encode(body),
      );

      print('🤖 Réponse génération: ${response.statusCode}');
      print('🤖 Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la génération');
      }
    } catch (e) {
      print('❌ Erreur génération auto: $e');
      throw Exception('Erreur de génération: $e');
    }
  }

  // 📊 ANALYSER L'EMPLOI DU TEMPS
  static Future<Map<String, dynamic>> analyserEmploi({
    required int departementId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'departement_id': departementId,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/analyser'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'analyse');
      }
    } catch (e) {
      print('❌ Erreur analyse: $e');
      throw Exception('Erreur d\'analyse: $e');
    }
  }

  // 📈 GÉNÉRER UN RAPPORT
  static Future<Map<String, dynamic>> genererRapport({
    required int departementId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'departement_id': departementId,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/rapport'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors du rapport');
      }
    } catch (e) {
      print('❌ Erreur rapport: $e');
      throw Exception('Erreur de rapport: $e');
    }
  }

  // 🔄 PROPOSER UNE RÉORGANISATION
  static Future<Map<String, dynamic>> proposerReorganisation({
    required int departementId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'departement_id': departementId,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/reorganiser'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la réorganisation');
      }
    } catch (e) {
      print('❌ Erreur réorganisation: $e');
      throw Exception('Erreur de réorganisation: $e');
    }
  }

  // 📋 RÉCUPÉRER LES DONNÉES NÉCESSAIRES POUR L'EMPLOI DU TEMPS

  // Récupérer les années d'un département
  static Future<List<Map<String, dynamic>>> getAnneesByDepartement(int departementId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/annees?departement_id=$departementId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération des années');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Récupérer les compétences disponibles
  // À ajouter dans votre EmploiDuTempsService

// 📚 RÉCUPÉRER TOUTES LES COMPÉTENCES
  static Future<List<Map<String, dynamic>>> getCompetences() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/competences'),
        headers: headers,
      );

      print('📚 Réponse getCompetences: ${response.statusCode}');
      print('📚 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Votre API peut retourner directement une liste ou un objet avec 'data'
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        throw Exception('Erreur lors de la récupération des compétences');
      }
    } catch (e) {
      print('❌ Erreur getCompetences: $e');
      throw Exception('Erreur: $e');
    }
  }

  // 🗓️ RÉCUPÉRER L'EMPLOI DU TEMPS D'UN FORMATEUR
  static Future<List<Map<String, dynamic>>> getEmploiFormateur({
    required int formateurId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/formateur/$formateurId?date_debut=$dateDebut&date_fin=$dateFin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération de l\'emploi du formateur');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // 🎓 RÉCUPÉRER L'EMPLOI DU TEMPS D'UNE ANNÉE
  static Future<List<Map<String, dynamic>>> getEmploiAnnee({
    required int anneeId,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/annee/$anneeId?date_debut=$dateDebut&date_fin=$dateFin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération de l\'emploi de l\'année');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
// Récupérer toutes les années
  static Future<List<Map<String, dynamic>>> getAllAnnees() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/annees'),
        headers: headers,
      );

      print('📚 Réponse getAllAnnees: ${response.statusCode}');
      print('📚 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Ton API retourne directement une liste
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        throw Exception('Erreur lors de la récupération des années');
      }
    } catch (e) {
      print('❌ Erreur getAllAnnees: $e');
      throw Exception('Erreur: $e');
    }
  }

// Récupérer les infos utilisateur
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: headers,
      );

      print('👤 Réponse getUserInfo: ${response.statusCode}');
      print('👤 Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getUserInfo: $e');
      throw Exception('Erreur: $e');
    }
  }
}