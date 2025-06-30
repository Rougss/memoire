import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Récupérer le token avec la même clé que LoginScreen
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
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
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      if (!await isAuthenticated()) {
        return {
          'success': false,
          'message': 'Utilisateur non authentifié. Veuillez vous connecter.'
        };
      }

      final headers = await _getHeaders();

      print('🔐 Changement de mot de passe...');
      print('📍 URL: $baseUrl/profile/change-password');

      final response = await http.post(
        Uri.parse('$baseUrl/profile/change-password'),
        headers: headers,
        body: jsonEncode({
          'current_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        }),
      );

      print('📡 changePassword - Status: ${response.statusCode}');
      print('📝 changePassword - Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mot de passe modifié avec succès'
        };
      } else if (response.statusCode == 422) {
        // Gestion des erreurs de validation
        String errorMessage = 'Erreur de validation';

        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          if (errors['current_password'] != null) {
            errorMessage = errors['current_password'][0];
          } else if (errors['new_password'] != null) {
            errorMessage = errors['new_password'][0];
          } else if (errors['new_password_confirmation'] != null) {
            errorMessage = errors['new_password_confirmation'][0];
          } else {
            errorMessage = data['message'] ?? errorMessage;
          }
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }

        return {
          'success': false,
          'message': errorMessage
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expirée, veuillez vous reconnecter'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du changement de mot de passe'
        };
      }
    } catch (e) {
      print('❌ Erreur changePassword: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion. Vérifiez votre connexion internet.'
      };
    }
  }

// Mettre à jour le profil utilisateur
  static Future<Map<String, dynamic>> updateProfile({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
  }) async {
    try {
      if (!await isAuthenticated()) {
        return {
          'success': false,
          'message': 'Utilisateur non authentifié. Veuillez vous connecter.'
        };
      }

      // Récupérer l'ID utilisateur depuis les données stockées
      final userData = await getCurrentUserData();
      if (userData == null) {
        return {
          'success': false,
          'message': 'Données utilisateur non trouvées'
        };
      }

      final userId = userData['id'];
      final headers = await _getHeaders();

      print('👤 Mise à jour profil utilisateur ID: $userId');
      print('📍 URL: $baseUrl/profile/$userId');

      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: headers,
        body: jsonEncode({
          'nom': nom,
          'prenom': prenom,
          'email': email,
          if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
        }),
      );

      print('📡 updateProfile - Status: ${response.statusCode}');
      print('📝 updateProfile - Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Mettre à jour les données locales
        if (data['data'] != null) {
          await saveUserData(data['data']);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Profil mis à jour avec succès',
          'data': data['data']
        };
      } else if (response.statusCode == 422) {
        String errorMessage = 'Erreur de validation';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.first[0];
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }
        return {
          'success': false,
          'message': errorMessage
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expirée, veuillez vous reconnecter'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour'
        };
      }
    } catch (e) {
      print('❌ Erreur updateProfile: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion. Vérifiez votre connexion internet.'
      };
    }
  }

// Récupérer les données de l'utilisateur connecté
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        return jsonDecode(userData);
      }

      print('⚠️ Aucune donnée utilisateur trouvée en local');
      return null;
    } catch (e) {
      print('❌ Erreur getCurrentUserData: $e');
      return null;
    }
  }

// Sauvegarder les données utilisateur localement
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
      print('✅ Données utilisateur sauvegardées localement');
    } catch (e) {
      print('❌ Erreur saveUserData: $e');
    }
  }

// Récupérer le profil utilisateur depuis l'API
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      if (!await isAuthenticated()) {
        print('❌ Pas de token pour récupérer le profil');
        return null;
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      print('📡 fetchUserProfile - Status: ${response.statusCode}');
      print('📝 fetchUserProfile - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else if (response.statusCode == 401) {
        print('⚠️ Session expirée lors de la récupération du profil');
        return null;
      } else {
        print('❌ Erreur lors de la récupération du profil: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur fetchUserProfile: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getEleveByUserId(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('user_token');

      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification non trouvé'
        };
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/admin/eleves/users/$userId'),
        headers: headers,
      );

      print('🔍 Requête élève pour user_id: $userId');
      print('📡 Status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Données élève récupérées avec succès'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Erreur lors de la récupération des données'
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Élève non trouvé'
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des données élève: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      if (!await isAuthenticated()) {
        return {
          'success': false,
          'message': 'Utilisateur non authentifié. Veuillez vous connecter.'
        };
      }

      final headers = await _getHeaders();

      print('🗑️ Suppression de l\'utilisateur ID: $userId');
      print('📍 URL: $baseUrl/admin/users/$userId');

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      print('📡 deleteUser - Status: ${response.statusCode}');
      print('📝 deleteUser - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Utilisateur supprimé avec succès'
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expirée, veuillez vous reconnecter'
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé'
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la suppression'
        };
      }
    } catch (e) {
      print('❌ Erreur deleteUser: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion. Vérifiez votre connexion internet.'
      };
    }
  }

  static Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      if (!await isAuthenticated()) {
        return {
          'success': false,
          'message': 'Utilisateur non authentifié. Veuillez vous connecter.'
        };
      }

      final headers = await _getHeaders();

      print('✏️ Mise à jour de l\'utilisateur ID: $userId');
      print('📦 Données: $userData');
      print('📍 URL: $baseUrl/admin/users/$userId');

      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
        body: jsonEncode(userData),
      );

      print('📡 updateUser - Status: ${response.statusCode}');
      print('📝 updateUser - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Utilisateur mis à jour avec succès',
          'data': data['data']
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expirée, veuillez vous reconnecter'
        };
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        String errorMessage = 'Erreur de validation';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.first[0];
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }
        return {
          'success': false,
          'message': errorMessage
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour'
        };
      }
    } catch (e) {
      print('❌ Erreur updateUser: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion. Vérifiez votre connexion internet.'
      };
    }
  }

  static Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      if (!await isAuthenticated()) {
        return {
          'success': false,
          'message': 'Utilisateur non authentifié. Veuillez vous connecter.'
        };
      }

      final headers = await _getHeaders();

      print('🔍 Récupération de l\'utilisateur ID: $userId');
      print('📍 URL: $baseUrl/admin/users/$userId');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      print('📡 getUserById - Status: ${response.statusCode}');
      print('📝 getUserById - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expirée, veuillez vous reconnecter'
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé'
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la récupération'
        };
      }
    } catch (e) {
      print('❌ Erreur getUserById: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion. Vérifiez votre connexion internet.'
      };
    }
  }


}