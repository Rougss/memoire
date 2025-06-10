import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Récupérer le token avec la même clé que LoginScreen
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
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

  // Récupérer tous les rôles disponibles
  static Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/roles'),
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

  // À ajouter dans UserService
  static Future<List<Map<String, dynamic>>> getBatiments() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/batiments'),
        headers: headers,
      );

      print('🔍 Get batiments response status: ${response.statusCode}');
      print('🔍 Get batiments response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }

        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        if (data is Map && data.containsKey('batiments')) {
          return List<Map<String, dynamic>>.from(data['batiments']);
        }

        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur dans getBatiments: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }


  // CORRECTION PRINCIPALE : Récupérer les métiers avec la bonne route
  static Future<List<Map<String, dynamic>>> getMetiers() async {
    try {
      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();

      // 🔧 ESSAYER PLUSIEURS ROUTES POSSIBLES
      List<String> possibleRoutes = [
        '$baseUrl/admin/metiers',
        '$baseUrl/common/metiers',
        '$baseUrl/metiers'
      ];

      http.Response? response;
      String? workingRoute;

      for (String route in possibleRoutes) {
        try {
          print('🔍 Tentative avec la route: $route');
          response = await http.get(Uri.parse(route), headers: headers);

          if (response.statusCode == 200) {
            workingRoute = route;
            print('✅ Route fonctionnelle trouvée: $route');
            break;
          } else {
            print('❌ Route $route échouée avec status: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ Erreur avec route $route: $e');
          continue;
        }
      }

      if (response == null || response.statusCode != 200) {
        throw Exception('Aucune route valide trouvée pour récupérer les métiers');
      }

      print('🔄 getMetiers - Status: ${response.statusCode}');
      print('🔄 getMetiers - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        // Vérifier si la réponse n'est pas vide
        if (responseBody.isEmpty) {
          print('⚠️ Réponse vide du serveur');
          return [];
        }

        final data = jsonDecode(responseBody);
        print('🔍 Data décodée: $data');
        print('🔍 Type de data: ${data.runtimeType}');

        List<Map<String, dynamic>> metiers = [];

        // Gestion flexible de la structure de réponse
        if (data is Map) {
          if (data.containsKey('data')) {
            final rawMetiers = data['data'];
            if (rawMetiers is List) {
              metiers = _processMetiersList(rawMetiers);
            } else if (rawMetiers is Map && rawMetiers.containsKey('data')) {
              // Structure imbriquée: {"data": {"data": [...]}}
              final nestedData = rawMetiers['data'];
              if (nestedData is List) {
                metiers = _processMetiersList(nestedData);
              }
            }
          } else if (data.containsKey('metiers')) {
            final rawMetiers = data['metiers'];
            if (rawMetiers is List) {
              metiers = _processMetiersList(rawMetiers);
            }
          }
        } else if (data is List) {
          metiers = _processMetiersList(data);
        }

        print('✅ ${metiers.length} métiers récupérés et traités');

        // Valider que chaque métier a les champs nécessaires
        metiers = metiers.where((metier) {
          bool isValid = metier['id'] != null && metier['nom'] != null;
          if (!isValid) {
            print('⚠️ Métier invalide ignoré: $metier');
          }
          return isValid;
        }).toList();

        print('✅ ${metiers.length} métiers valides après filtrage');
        return metiers;

      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la récupération des métiers (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur getMetiers: $e');
      if (e.toString().contains('FormatException')) {
        throw Exception('Erreur de format de réponse du serveur');
      }
      throw Exception('Erreur de connexion: $e');
    }
  }


  // 🆕 Méthode utilitaire pour traiter la liste des métiers
  static List<Map<String, dynamic>> _processMetiersList(List rawList) {
    return rawList.map((item) {
      if (item is Map<String, dynamic>) {
        final correctedItem = Map<String, dynamic>.from(item);

        // Assurer que l'ID est un entier
        if (correctedItem['id'] is String) {
          correctedItem['id'] = int.tryParse(correctedItem['id']) ?? 0;
        }

        // Assurer que le nom existe
        if (correctedItem['nom'] == null) {
          correctedItem['nom'] = correctedItem['name'] ?? correctedItem['libelle'] ?? 'Sans nom';
        }

        return correctedItem;
      }
      return <String, dynamic>{'id': 0, 'nom': 'Métier invalide'};
    }).toList();
  }



  // Récupérer les spécialités (pour les formateurs)
  static Future<List<Map<String, dynamic>>> getSpecialites() async {
    try {
      print('🔍 Tentative de récupération des spécialités...');

      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/admin/specialites');
      print('➡ Requête envoyée à : $url');

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

  // Créer un utilisateur
  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();
      final endpoint = '$baseUrl/admin/users/ajouter';

      print('🚀 Tentative de création avec endpoint: $endpoint');
      print('📦 Données envoyées: $userData');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(userData),
      );

      print('🔄 createUser - Status: ${response.statusCode}');
      print('🔄 createUser - Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la création (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Erreur createUser: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // 🚀 NOUVELLE MÉTHODE : Récupérer TOUS les utilisateurs avec pagination automatique
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      if (!await isAuthenticated()) {
        throw Exception('Utilisateur non authentifié. Veuillez vous connecter.');
      }

      final headers = await _getHeaders();
      List<Map<String, dynamic>> allUsers = [];
      int currentPage = 1;
      int totalPages = 1;

      print('🔄 Début récupération de tous les utilisateurs...');

      do {
        final url = '$baseUrl/admin/users?page=$currentPage';
        print('🔍 Récupération page $currentPage sur $totalPages : $url');

        final response = await http.get(
          Uri.parse(url),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Extraire les informations de pagination
          final paginationData = data['data'];
          totalPages = paginationData['last_page'] ?? 1;

          // Extraire les utilisateurs de cette page
          final usersOnPage = List<Map<String, dynamic>>.from(paginationData['data'] ?? []);

          // Traiter chaque utilisateur pour extraire le nom du rôle
          for (var user in usersOnPage) {
            if (user['role'] != null && user['role'] is Map) {
              user['role_name'] = user['role']['intitule'] ?? 'Non défini';
            } else {
              user['role_name'] = 'Non défini';
            }
            allUsers.add(user);
          }

          print('✅ Page $currentPage : ${usersOnPage.length} utilisateurs récupérés');
          currentPage++;

        } else if (response.statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else {
          throw Exception('Erreur lors de la récupération des utilisateurs (page $currentPage)');
        }

      } while (currentPage <= totalPages);

      print('✅ TOTAL : ${allUsers.length} utilisateurs récupérés sur $totalPages pages');
      return allUsers;

    } catch (e) {
      print('❌ Erreur getAllUsers: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // ANCIENNE MÉTHODE (conservée pour compatibilité)
  static Future<List<Map<String, dynamic>>> getUsers() async {
    return getAllUsers(); // Redirection vers la nouvelle méthode
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
        Uri.parse('$baseUrl/admin/user'),
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