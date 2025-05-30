import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SpecialiteService {
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

  // Récupérer toutes les spécialités (route commune, accessible à tous)
  static Future<List<Specialite>> getAllSpecialites() async {
    try {
      final headers = await _getHeaders();

      // Debug: afficher le token utilisé
      final token = await _getToken();
      print('Token utilisé pour les spécialités: ${token?.substring(0, 20)}...' ?? 'Aucun token');

      // Utiliser la route commune au lieu de la route admin
      final response = await http.get(
        Uri.parse('$baseUrl/common/specialites'), // Route commune
        headers: headers,
      );

      print('Response status spécialités: ${response.statusCode}');
      print('Response body spécialités: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        List<dynamic> specialitesJson;
        if (jsonData.containsKey('data')) {
          specialitesJson = jsonData['data'];
        } else if (jsonData is List) {
          specialitesJson = jsonData as List;
        } else {
          throw Exception('Format de réponse inattendu pour les spécialités');
        }

        return specialitesJson.map((json) => Specialite.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Token d\'authentification expiré ou invalide');
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Vérifiez vos permissions');
      } else {
        throw Exception('Erreur lors de la récupération des spécialités: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans getAllSpecialites: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Pour les opérations CRUD admin (création, modification, suppression)
  static Future<List<Specialite>> getAllSpecialitesAdmin() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/specialites'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        List<dynamic> specialitesJson = jsonData['data'] ?? jsonData;
        return specialitesJson.map((json) => Specialite.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des spécialités admin: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion admin: $e');
    }
  }

  // Créer une nouvelle spécialité (admin seulement)
  static Future<Specialite> createSpecialite(Specialite specialite) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/specialites'),
        headers: headers,
        body: json.encode(specialite.toJson()),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return Specialite.fromJson(jsonData['data'] ?? jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création de la spécialité');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création de la spécialité: $e');
    }
  }

  // Mettre à jour une spécialité (admin seulement)
  static Future<Specialite> updateSpecialite(int id, Specialite specialite) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/specialites/$id'),
        headers: headers,
        body: json.encode(specialite.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Specialite.fromJson(jsonData['data'] ?? jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la mise à jour de la spécialité');
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la spécialité: $e');
    }
  }

  // Supprimer une spécialité (admin seulement)
  static Future<void> deleteSpecialite(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/specialites/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la suppression de la spécialité');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la spécialité: $e');
    }
  }
}

// Modèle Specialite (à adapter selon votre structure)
class Specialite {
  final int? id;
  final String nom;
  final String? description;

  Specialite({
    this.id,
    required this.nom,
    this.description,
  });

  factory Specialite.fromJson(Map<String, dynamic> json) {
    return Specialite(
      id: json['id'],
      nom: json['nom'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      if (description != null) 'description': description,
    };
  }
}