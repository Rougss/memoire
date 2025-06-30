import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _lastLoginKey = 'last_login';

  // 🔥 NOUVELLE MÉTHODE: Vérifier une session existante
  static Future<Map<String, dynamic>?> checkExistingSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(_tokenKey);
      final userDataString = prefs.getString(_userKey);
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      print('🔍 Vérification session existante...');
      print('   Token présent: ${token != null}');
      print('   User data présent: ${userDataString != null}');
      print('   Is logged in: $isLoggedIn');

      // Si on a un token et des données utilisateur et que la session est marquée active
      if (token != null && userDataString != null && isLoggedIn) {

        // 🔥 VÉRIFIER SI LE TOKEN EST ENCORE VALIDE
        final isValid = await _validateTokenWithApi(token);

        if (isValid) {
          final userData = jsonDecode(userDataString);

          print('✅ Session valide trouvée pour: ${userData['nom']} ${userData['prenom']}');

          return {
            'isLoggedIn': true,
            'user': userData,
            'token': token,
            'role': userData['role']['intitule'],
          };
        } else {
          print('❌ Token expiré, suppression de la session');
          await clearSession();
          return null;
        }
      }

      print('❌ Aucune session trouvée');
      return null;

    } catch (e) {
      print('❌ Erreur vérification session: $e');
      return null;
    }
  }

  // 🔥 NOUVELLE MÉTHODE: Valider le token avec l'API
  static Future<bool> _validateTokenWithApi(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/me'), // Endpoint pour vérifier le token
        headers: ApiConfig.authHeaders(token),
      ).timeout(Duration(seconds: 10));

      print('🔍 Validation token - Status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur validation token: $e');
      return false;
    }
  }

  // 🔥 MISE À JOUR: Connexion avec sauvegarde de session
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: ApiConfig.timeoutDuration));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final String token = jsonResponse['data']['token'];
          final Map<String, dynamic> user = jsonResponse['data']['user'];

          // 🔥 SAUVEGARDER LA SESSION COMPLÈTE
          await _saveToken(token);
          await _saveUserData(user);
          await _markAsLoggedIn(); // Nouvelle méthode

          print('✅ Session sauvegardée pour: ${user['nom']} ${user['prenom']}');

          return {
            'success': true,
            'token': token,
            'user': user,
            'access_token': token, // Pour compatibilité avec LoginScreen
          };
        } else {
          throw Exception('Format de réponse invalide');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Email ou mot de passe incorrect');
      } else {
        throw Exception('Erreur de connexion: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Délai de connexion dépassé');
      }
      rethrow;
    }
  }

  // 🔥 MISE À JOUR: Déconnexion avec suppression complète de session
  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse(ApiConfig.logoutUrl),
          headers: ApiConfig.authHeaders(token),
        ).timeout(Duration(seconds: ApiConfig.timeoutDuration));
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    } finally {
      // 🔥 SUPPRIMER TOUTE LA SESSION
      await clearSession();
      print('🗑️ Session complètement supprimée');
    }
  }

  // 🔥 NOUVELLE MÉTHODE: Supprimer complètement la session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_lastLoginKey);

    // Supprimer aussi les anciennes clés pour compatibilité
    await prefs.remove('access_token');
    await prefs.remove('user_data');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
  }

  // 🔥 NOUVELLE MÉTHODE: Marquer comme connecté
  static Future<void> _markAsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
  }

  // Vérifier si l'utilisateur est connecté (méthode existante améliorée)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    return token != null && token.isNotEmpty && isLoggedIn;
  }

  // Obtenir le token (méthode existante)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Obtenir les données utilisateur (méthode existante)
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }

  // 🔥 NOUVELLE MÉTHODE: Obtenir le rôle de l'utilisateur
  static Future<String?> getUserRole() async {
    final userData = await getUserData();
    if (userData != null && userData['role'] != null) {
      return userData['role']['intitule'];
    }
    return null;
  }

  // Sauvegarder le token (méthode existante)
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Sauvegarder les données utilisateur (méthode existante)
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(userData));
  }

  // Supprimer le token (méthode existante)
  static Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Supprimer les données utilisateur (méthode existante)
  static Future<void> _removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Rafraîchir le token (méthode existante)
  static Future<String?> refreshToken() async {
    try {
      final currentToken = await getToken();
      if (currentToken == null) return null;

      final response = await http.post(
        Uri.parse(ApiConfig.refreshTokenUrl),
        headers: ApiConfig.authHeaders(currentToken),
      ).timeout(Duration(seconds: ApiConfig.timeoutDuration));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final String newToken = jsonResponse['data']['token'];
          await _saveToken(newToken);
          return newToken;
        }
      }

      return null;
    } catch (e) {
      print('Erreur lors du rafraîchissement du token: $e');
      return null;
    }
  }
}