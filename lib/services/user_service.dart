import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Remplacez par votre URL

  // CORRECTION: Récupérer le token avec la même clé que LoginScreen
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token'); // 'access_token' au lieu de 'auth_token'
    print('🔑 Token récupéré: ${token != null ? "✅ Présent" : "❌ Absent"}');
    if (token != null) {
      print('🔑 Token (premiers 20 caractères): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    }
    return token;
  }

  // Headers avec authentification
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print('📋 Headers générés: $headers');
    return headers;
  }

  // Méthode pour vérifier si l'utilisateur est authentifié
  static Future<bool> isAuthenticated() async {
    final token = await _getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // Méthode pour vérifier les données utilisateur sauvegardées
  static Future<void> debugUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userData = prefs.getString('user_data');
    final userRole = prefs.getString('user_role');
    final userId = prefs.getInt('user_id');

    print('=== DEBUG USER DATA ===');
    print('Token: ${token != null ? "✅ Présent (${token.substring(0, 20)}...)" : "❌ Absent"}');
    print('User Data: ${userData != null ? "✅ Présent" : "❌ Absent"}');
    print('User Role: ${userRole ?? "❌ Absent"}');
    print('User ID: ${userId ?? "❌ Absent"}');
    print('=====================');
  }

  // Récupérer tous les rôles disponibles
  static Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      // Vérifier l'authentification avant la requête
      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/roles'),
        headers: headers,
      );

      print('🔄 getRoles - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la récupération des rôles');
      }
    } catch (e) {
      print('❌ Erreur getRoles: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer les spécialités (pour les formateurs)
  static Future<List<Map<String, dynamic>>> getSpecialites() async {
    try {
      print('🔍 Tentative de récupération des spécialités...');

      // Debug des données utilisateur
      await debugUserData();

      // Vérifier l'authentification avant la requête
      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/admin/specialites');
      print('➡ Requête envoyée à : $url');
      print('➡ Headers : $headers');

      final response = await http.get(url, headers: headers);

      print('⬅ Status code: ${response.statusCode}');
      print('⬅ Réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final specialites = List<Map<String, dynamic>>.from(data['data'] ?? []);
        print('✅ ${specialites.length} spécialités récupérées');
        return specialites;
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé. Permissions insuffisantes.');
      } else {
        throw Exception('Erreur lors de la récupération des spécialités (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur getSpecialites: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer les métiers (pour les élèves)
  static Future<List<Map<String, dynamic>>> getMetiers() async {
    try {
      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/metiers'),
        headers: headers,
      );

      print('🔄 getMetiers - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la récupération des métiers');
      }
    } catch (e) {
      print('❌ Erreur getMetiers: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer les salles (pour les élèves)
  static Future<List<Map<String, dynamic>>> getSalles() async {
    try {
      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/salles'),
        headers: headers,
      );

      print('🔄 getSalles - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la récupération des salles');
      }
    } catch (e) {
      print('❌ Erreur getSalles: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Créer un utilisateur selon son rôle
  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: headers,
        body: jsonEncode(userData),
      );

      print('🔄 createUser - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      print('❌ Erreur createUser: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer tous les utilisateurs
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: headers,
      );

      print('🔄 getUsers - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['data'] ?? []);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la récupération des utilisateurs');
      }
    } catch (e) {
      print('❌ Erreur getUsers: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Méthode de déconnexion
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_data');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    print('🚪 Utilisateur déconnecté - Toutes les données supprimées');
  }

  // Méthode pour tester la connexion avec votre API
  static Future<bool> testAuth() async {
    try {
      if (!await isAuthenticated()) {
        print('❌ Pas de token pour tester');
        return false;
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/user'), // Testez avec /api/user si nécessaire
        headers: headers,
      );

      print('🧪 Test auth - Status: ${response.statusCode}');
      print('🧪 Test auth - Réponse: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur test auth: $e');
      return false;
    }
  }
}