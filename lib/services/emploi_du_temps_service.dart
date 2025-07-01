import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmploiDuTempsService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // 🔥 CACHE INTELLIGENT
  static final Map<String, CacheEntry> _cache = {};
  static const int CACHE_DURATION_SECONDS = 300; // 5 minutes
  static const int MAX_CACHE_SIZE = 50; // Limite mémoire

  // 🔥 GESTION TOKEN SIMPLIFIÉE
  static const List<String> TOKEN_KEYS = [
    'auth_token', 'token', 'access_token', 'user_token'
  ];

  /// 🔥 RÉCUPÉRATION TOKEN OPTIMISÉE
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    for (String key in TOKEN_KEYS) {
      final token = prefs.getString(key);
      if (token != null && token.isNotEmpty) {
        return token;
      }
    }

    return null;
  }

  /// 🔥 HEADERS AVEC CACHE
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 🔥 GESTION CACHE INTELLIGENTE
  static T? _getCachedData<T>(String key) {
    if (!_cache.containsKey(key)) return null;

    final entry = _cache[key]!;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  static void _setCachedData<T>(String key, T data) {
    // 🔥 LIMITATION TAILLE CACHE
    if (_cache.length >= MAX_CACHE_SIZE) {
      _cleanOldestCacheEntries();
    }

    _cache[key] = CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(Duration(seconds: CACHE_DURATION_SECONDS)),
      createdAt: DateTime.now(),
    );
  }

  static void _cleanOldestCacheEntries() {
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    // Supprimer les 10 plus anciens
    for (int i = 0; i < 10 && i < sortedEntries.length; i++) {
      _cache.remove(sortedEntries[i].key);
    }
  }

  /// 🔥 INVALIDATION CACHE CIBLÉE
  static void invalidateCache([String? pattern]) {
    if (pattern == null) {
      _cache.clear();
      return;
    }

    _cache.removeWhere((key, _) => key.contains(pattern));
  }

  /// 🔥 RÉCUPÉRATION EMPLOIS ÉLÈVE OPTIMISÉE
  static Future<List<Map<String, dynamic>>> getEmploisEleve({
    String? dateDebut,
    String? dateFin,
    int page = 1,
    int perPage = 30,
  }) async {
    final cacheKey = 'emplois_eleve_${dateDebut ?? 'default'}_${dateFin ?? 'default'}_${page}_$perPage';

    // 🔥 VÉRIFIER CACHE D'ABORD
    final cachedData = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      print('📦 Cache hit pour emplois élève');
      return cachedData;
    }

    try {
      final headers = await _getHeaders();


      String url = '$baseUrl/eleve/mon-emploi-du-temps?page=$page&per_page=$perPage';
      if (dateDebut != null) url += '&date_debut=$dateDebut';
      if (dateFin != null) url += '&date_fin=$dateFin';

      final response = await http.get(Uri.parse(url), headers: headers);

      print('📅 Emplois élève: ${response.statusCode} (${response.body.length} chars)');

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null && data['success'] == true) {
          final emplois = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);

          // 🔥 MISE EN CACHE
          _setCachedData(cacheKey, emplois);

          return emplois;
        } else {
          throw Exception(data?['message'] ?? 'Erreur lors de la récupération');
        }
      } else {
        throw HttpException('Erreur HTTP: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      print('❌ Erreur getEmploisEleve: $e');

      // 🔥 FALLBACK : Retourner cache expiré si disponible
      final expiredCache = _cache[cacheKey];
      if (expiredCache != null) {
        print('🆘 Utilisation cache expiré comme fallback');
        return expiredCache.data as List<Map<String, dynamic>>;
      }

      throw Exception('Erreur de connexion: $e');
    }
  }

  /// 🔥 RÉCUPÉRATION TOUS EMPLOIS OPTIMISÉE AVEC PAGINATION
  static Future<EmploiResponse> getAllEmploisPaginated({
    int page = 1,
    int perPage = 50,
    String? dateDebut,
    String? dateFin,
    int? anneeId,
  }) async {
    final cacheKey = 'all_emplois_${page}_${perPage}_${dateDebut ?? ''}_${dateFin ?? ''}_${anneeId ?? ''}';

    // 🔥 VÉRIFIER CACHE
    final cachedData = _getCachedData<EmploiResponse>(cacheKey);
    if (cachedData != null) {
      print('📦 Cache hit pour tous emplois page $page');
      return cachedData;
    }

    try {
      final headers = await _getHeaders();


      String url = '$baseUrl/admin/emploi-du-temps?page=$page&per_page=$perPage';
      if (dateDebut != null) url += '&date_debut=$dateDebut';
      if (dateFin != null) url += '&date_fin=$dateFin';
      if (anneeId != null) url += '&annee_id=$anneeId';

      final response = await http.get(Uri.parse(url), headers: headers);

      print('📅 Tous emplois: ${response.statusCode} (${response.body.length} chars)');

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null && data['success'] == true) {
          final emploiResponse = EmploiResponse(
            emplois: List<Map<String, dynamic>>.from(data['data'] as List? ?? []),
            pagination: PaginationInfo.fromJson(data['pagination'] as Map<String, dynamic>? ?? {}),
            timestamp: DateTime.now(),
          );

          // 🔥 MISE EN CACHE
          _setCachedData(cacheKey, emploiResponse);

          return emploiResponse;
        } else {
          throw Exception(data?['message'] ?? 'Erreur lors de la récupération');
        }
      } else {

        print('🔍 ERREUR ${response.statusCode} COMPLÈTE:');
        print('URL: $url');
        print('Headers: $headers');
        print('Response Body: ${response.body}');
        print('=== FIN ERREUR ===');

        throw HttpException('Erreur HTTP: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      print('❌ Erreur getAllEmploisPaginated: $e');


      return _handleEmploiError(e, cacheKey);
    }
  }

  /// 🔥 MÉTHODE LEGACY POUR COMPATIBILITÉ
  static Future<List<Map<String, dynamic>>> getAllEmplois() async {
    try {
      final response = await getAllEmploisPaginated(perPage: 100);
      return response.emplois;
    } catch (e) {
      print('❌ Fallback getAllEmplois: $e');
      return [];
    }
  }

  /// 🔥 PARSING JSON SÉCURISÉ
  static Map<String, dynamic>? _parseJsonSafely(String jsonString) {
    try {
      // 🔥 NETTOYAGE PRÉVENTIF
      String cleanJson = jsonString.trim();

      // Vérifier intégrité JSON de base
      if (!cleanJson.startsWith('{') || (!cleanJson.endsWith('}') && !cleanJson.endsWith(']'))) {
        print('⚠️ JSON mal formé détecté');
        return _attemptJsonRecovery(cleanJson);
      }

      return json.decode(cleanJson);
    } catch (e) {
      print('❌ Erreur parsing JSON: $e');
      return _attemptJsonRecovery(jsonString);
    }
  }

  /// 🔥 RÉCUPÉRATION JSON SIMPLIFIÉE
  static Map<String, dynamic>? _attemptJsonRecovery(String brokenJson) {
    try {
      // Méthode simple : couper à la dernière accolade fermante complète
      int lastValidEnd = brokenJson.lastIndexOf('}}]}');
      if (lastValidEnd == -1) {
        lastValidEnd = brokenJson.lastIndexOf('}]}');
      }
      if (lastValidEnd == -1) {
        lastValidEnd = brokenJson.lastIndexOf('}}');
      }

      if (lastValidEnd > 0) {
        String repairedJson = brokenJson.substring(0, lastValidEnd + 3);
        return json.decode(repairedJson);
      }

      // Si rien ne fonctionne, retourner structure vide
      return {'success': false, 'data': [], 'message': 'JSON corrompu'};
    } catch (e) {
      print('❌ Récupération JSON échouée: $e');
      return null;
    }
  }

  /// 🔥 GESTION D'ERREURS INTELLIGENTE
  static EmploiResponse _handleEmploiError(dynamic error, String cacheKey) {
    // Essayer le cache expiré
    final expiredCache = _cache[cacheKey];
    if (expiredCache != null) {
      print('🆘 Utilisation cache expiré pour getAllEmplois');
      final cached = expiredCache.data as EmploiResponse;
      return EmploiResponse(
        emplois: cached.emplois,
        pagination: cached.pagination,
        timestamp: cached.timestamp,
        isFromCache: true,
        cacheWarning: 'Données mises en cache (connexion limitée)',
      );
    }

    // Retourner réponse vide avec info d'erreur
    return EmploiResponse(
      emplois: [],
      pagination: PaginationInfo.empty(),
      timestamp: DateTime.now(),
      isFromCache: false,
      error: error.toString(),
    );
  }

  /// 🔥 MÉTHODES EXISTANTES OPTIMISÉES
  static Future<List<Map<String, dynamic>>> getMetiersAvecCompetences() async {
    const cacheKey = 'metiers_avec_competences';

    final cachedData = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/metiers-avec-competences'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null) {
          final metiers = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
          _setCachedData(cacheKey, metiers);
          return metiers;
        }
      }
      throw Exception('Erreur lors de la récupération des métiers');
    } catch (e) {
      print('❌ Erreur getMetiersAvecCompetences: $e');
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCompetencesAvecQuotaByMetier(int metierId) async {
    final cacheKey = 'competences_metier_$metierId';

    final cachedData = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/competences-avec-quota-metier/$metierId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null) {
          final competences = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
          _setCachedData(cacheKey, competences);
          return competences;
        }
      }
      throw Exception('Erreur lors de la récupération des compétences du métier');
    } catch (e) {
      print('❌ Erreur getCompetencesAvecQuotaByMetier: $e');
      throw Exception('Erreur: $e');
    }
  }

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

  /// 🔥 PLANIFICATION OPTIMISÉE
  static Future<Map<String, dynamic>> planifierCompetencesLimitees({
    required int anneeId,
    required String dateDebut,
    required List<Map<String, dynamic>> competences,
    required int maxSeancesParCompetence,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'annee_id': anneeId,
        'date_debut': dateDebut,
        'competences': competences,
        'max_seances_par_competence': maxSeancesParCompetence,
        'mode': 'intelligent_limite',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/planifier-intelligent'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final result = _parseJsonSafely(response.body);

        // 🔥 INVALIDATION CACHE APRÈS CRÉATION
        invalidateCache('emplois_');
        invalidateCache('quotas_');

        return result ?? {'success': false, 'message': 'Réponse invalide'};
      } else {
        final errorData = _parseJsonSafely(response.body);
        throw Exception(errorData?['message'] ?? 'Erreur lors de la planification');
      }
    } catch (e) {
      print('❌ Erreur planifierCompetencesLimitees: $e');
      throw Exception('Erreur de planification: $e');
    }
  }

  /// 🔥 DÉPLACEMENT DE COURS OPTIMISÉ
  static Future<Map<String, dynamic>> deplacerCours(
      int emploiId,
      String nouvelleDate,
      String nouvelleHeureDebut,
      String nouvelleHeureFin,
      String raisonDeplacement,
      ) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'nouvelle_date': nouvelleDate,
        'nouvelle_heure_debut': nouvelleHeureDebut,
        'nouvelle_heure_fin': nouvelleHeureFin,
        'raison_deplacement': raisonDeplacement,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/admin/emploi-du-temps/$emploiId/deplacer'),
        headers: headers,
        body: json.encode(body),
      );

      final data = _parseJsonSafely(response.body);

      if (response.statusCode == 200) {
        // 🔥 INVALIDATION CACHE CIBLÉE
        invalidateCache('emplois_');
        invalidateCache('formateur_${emploiId}');
      }

      return data ?? {'success': false, 'message': 'Réponse invalide'};
    } catch (e) {
      print('❌ Erreur deplacerCours: $e');
      throw Exception('Erreur de déplacement: $e');
    }
  }

  /// 🔥 MÉTHODES MANQUANTES RAJOUTÉES

  // ========================================
  // MÉTHODES DE RÉCUPÉRATION COMPLÈTES
  // ========================================

  static Future<List<Map<String, dynamic>>> getCompetencesMetier(int metierId) async {
    final cacheKey = 'competences_metier_all_$metierId';

    final cachedData = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/metiers/$metierId/competences'),
        headers: headers,
      );

      print('📚 Réponse toutes compétences du métier $metierId: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null) {
          final competences = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
          _setCachedData(cacheKey, competences);
          return competences;
        }
      }
      throw Exception('Erreur lors de la récupération des compétences');
    } catch (e) {
      print('❌ Erreur getCompetencesMetier: $e');
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getEmploiFormateur({
    required int formateurId,
    required String dateDebut,
    required String dateFin,
  }) async {
    final cacheKey = 'emploi_formateur_${formateurId}_${dateDebut}_$dateFin';

    final cachedData = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/formateur/$formateurId?date_debut=$dateDebut&date_fin=$dateFin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null) {
          final emplois = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
          _setCachedData(cacheKey, emplois);
          return emplois;
        }
      }
      throw Exception('Erreur lors de la récupération de l\'emploi du formateur');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getEmploiAnnee({
    required int anneeId,
    required String dateDebut,
    required String dateFin,
  }) async {
    final cacheKey = 'emploi_annee_${anneeId}_${dateDebut}_$dateFin';

    final cachedData = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/annee/$anneeId?date_debut=$dateDebut&date_fin=$dateFin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null) {
          final emplois = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
          _setCachedData(cacheKey, emplois);
          return emplois;
        }
      }
      throw Exception('Erreur lors de la récupération de l\'emploi de l\'année');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCompetences() async {
    const cacheKey = 'all_competences';

    final cachedData = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/competences'),
        headers: headers,
      );

      print('📚 Réponse getCompetences: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null) {
          List<Map<String, dynamic>> competences;
          if (data is List) {
            competences = List<Map<String, dynamic>>.from(data as List);
          } else if (data is Map && data['data'] != null && data['data'] is List) {
            competences = List<Map<String, dynamic>>.from(data['data'] as List);
          } else {
            competences = [];
          }

          _setCachedData(cacheKey, competences);
          return competences;
        }
      }
      throw Exception('Erreur lors de la récupération des compétences');
    } catch (e) {
      print('❌ Erreur getCompetences: $e');
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCompetencesAvecQuota({int? metierId}) async {
    String cacheKey = 'competences_avec_quota';
    if (metierId != null) {
      cacheKey += '_metier_$metierId';
    }

    final cachedData = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final headers = await _getHeaders();

      String url = '$baseUrl/admin/emploi-du-temps/competences-avec-quota';
      if (metierId != null) {
        url += '?metier_id=$metierId';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      print('🎯 Réponse compétences avec quota${metierId != null ? " (métier $metierId)" : ""}: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null) {
          final competences = List<Map<String, dynamic>>.from(data['data'] ?? []);
          _setCachedData(cacheKey, competences);
          return competences;
        }
      }
      throw Exception('Erreur lors de la récupération des compétences avec quota');
    } catch (e) {
      print('❌ Erreur getCompetencesAvecQuota: $e');
      throw Exception('Erreur: $e');
    }
  }

  static Future<Map<String, dynamic>> getResumeMetier(int metierId) async {
    final cacheKey = 'resume_metier_$metierId';

    final cachedData = _getCachedData<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final results = await Future.wait([
        getCompetencesAvecQuotaByMetier(metierId),
        // Note: getStatistiquesMetier() serait à implémenter si nécessaire
      ]);

      final competences = results[0] as List<Map<String, dynamic>>;

      final resume = {
        'metier_id': metierId,
        'competences_disponibles': competences.length,
        'total_quota_restant': competences.fold<double>(
            0, (sum, comp) => sum + (comp['heures_restantes'] ?? 0.0)
        ),
        'competences': competences,
      };

      _setCachedData(cacheKey, resume);
      return resume;
    } catch (e) {
      print('❌ Erreur getResumeMetier: $e');
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAnneesByDepartement(int departementId) async {
    final cacheKey = 'annees_departement_$departementId';

    final cachedData = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/annees?departement_id=$departementId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null) {
          final annees = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
          _setCachedData(cacheKey, annees);
          return annees;
        }
      }
      throw Exception('Erreur lors de la récupération des années');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    const cacheKey = 'user_info';

    final cachedData = _getCachedData<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: headers,
      );

      print('👤 Réponse getUserInfo: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null) {
          _setCachedData(cacheKey, data);
          return data;
        }
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      print('❌ Erreur getUserInfo: $e');
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getQuotasStatut() async {
    const cacheKey = 'quotas_statut';

    final cachedData = _getCachedData<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/emploi-du-temps/quotas-statut'),
        headers: headers,
      );

      print('📊 Réponse quotas statut: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        if (data != null) {
          final quotas = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
          _setCachedData(cacheKey, quotas);
          return quotas;
        }
      }
      throw Exception('Erreur lors de la récupération des quotas');
    } catch (e) {
      print('❌ Erreur getQuotasStatut: $e');
      throw Exception('Erreur: $e');
    }
  }

  // ========================================
  // MÉTHODES DE CRÉATION ET MODIFICATION
  // ========================================

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

      if (response.statusCode == 201) {
        final data = _parseJsonSafely(response.body);

        // 🔥 INVALIDATION CACHE APRÈS CRÉATION
        invalidateCache('emplois_');
        invalidateCache('quotas_');

        return data ?? {'success': false, 'message': 'Réponse invalide'};
      } else {
        final errorData = _parseJsonSafely(response.body);
        throw Exception(errorData?['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      print('❌ Erreur creerCreneau: $e');
      throw Exception('Erreur de création: $e');
    }
  }

  static Future<Map<String, dynamic>> planifierCompetences({
    required int anneeId,
    required String dateDebut,
    required List<Map<String, dynamic>> competences,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'annee_id': anneeId,
        'date_debut': dateDebut,
        'competences': competences,
      };

      print('🎯 Planification compétences: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/planifier-competences'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final result = _parseJsonSafely(response.body);

        // 🔥 INVALIDATION CACHE APRÈS CRÉATION
        invalidateCache('emplois_');
        invalidateCache('quotas_');

        return result ?? {'success': false, 'message': 'Réponse invalide'};
      } else {
        final errorData = _parseJsonSafely(response.body);
        throw Exception(errorData?['message'] ?? 'Erreur lors de la planification');
      }
    } catch (e) {
      print('❌ Erreur planifierCompetences: $e');
      throw Exception('Erreur de planification: $e');
    }
  }

  // ========================================
  // MÉTHODES D'ANALYSE ET PREVIEW
  // ========================================

  static Future<Map<String, dynamic>> getQuotasApresLimitation({
    required List<Map<String, dynamic>> competences,
    required int maxSeancesParCompetence,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'competences': competences,
        'max_seances_par_competence': maxSeancesParCompetence,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/preview-limitation'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        return data ?? {'success': false, 'message': 'Réponse invalide'};
      } else {
        final errorData = _parseJsonSafely(response.body);
        throw Exception(errorData?['message'] ?? 'Erreur lors du calcul');
      }
    } catch (e) {
      print('❌ Erreur getQuotasApresLimitation: $e');
      throw Exception('Erreur de calcul: $e');
    }
  }

  static Future<Map<String, dynamic>> verifierDisponibiliteFormateurs({
    required List<int> formateurIds,
    required String dateDebut,
    required String dateFin,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'formateur_ids': formateurIds,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/verifier-disponibilite'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);
        return data ?? {'success': false, 'message': 'Réponse invalide'};
      } else {
        final errorData = _parseJsonSafely(response.body);
        throw Exception(errorData?['message'] ?? 'Erreur lors de la vérification');
      }
    } catch (e) {
      print('❌ Erreur verifierDisponibiliteFormateurs: $e');
      throw Exception('Erreur de vérification: $e');
    }
  }

  // ========================================
  // MÉTHODES D'ANALYSE ET RAPPORTS
  // ========================================

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

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);

        // 🔥 INVALIDATION CACHE APRÈS GÉNÉRATION
        invalidateCache('emplois_');

        return data ?? {'success': false, 'message': 'Réponse invalide'};
      } else {
        final errorData = _parseJsonSafely(response.body);
        throw Exception(errorData?['message'] ?? 'Erreur lors de la génération');
      }
    } catch (e) {
      print('❌ Erreur génération auto: $e');
      throw Exception('Erreur de génération: $e');
    }
  }

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
        final data = _parseJsonSafely(response.body);
        return data ?? {'success': false, 'message': 'Réponse invalide'};
      } else {
        final errorData = _parseJsonSafely(response.body);
        throw Exception(errorData?['message'] ?? 'Erreur lors de l\'analyse');
      }
    } catch (e) {
      print('❌ Erreur analyse: $e');
      throw Exception('Erreur d\'analyse: $e');
    }
  }

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
        final data = _parseJsonSafely(response.body);
        return data ?? {'success': false, 'message': 'Réponse invalide'};
      } else {
        final errorData = _parseJsonSafely(response.body);
        throw Exception(errorData?['message'] ?? 'Erreur lors du rapport');
      }
    } catch (e) {
      print('❌ Erreur rapport: $e');
      throw Exception('Erreur de rapport: $e');
    }
  }

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
        final data = _parseJsonSafely(response.body);
        return data ?? {'success': false, 'message': 'Réponse invalide'};
      } else {
        final errorData = _parseJsonSafely(response.body);
        throw Exception(errorData?['message'] ?? 'Erreur lors de la réorganisation');
      }
    } catch (e) {
      print('❌ Erreur réorganisation: $e');
      throw Exception('Erreur de réorganisation: $e');
    }
  }

  static Future<Map<String, dynamic>> optimiserRepartition({
    required int anneeId,
    required String dateDebut,
    required List<Map<String, dynamic>> competences,
    required int maxSeancesParCompetence,
    String? algorithme,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'annee_id': anneeId,
        'date_debut': dateDebut,
        'competences': competences,
        'max_seances_par_competence': maxSeancesParCompetence,
        'algorithme': algorithme ?? 'equilibre',
        'options': {
          'eviter_conflits': true,
          'respecter_pauses': true,
          'equilibrer_charges': true,
        }
      };

      print('🔀 Optimisation répartition: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/admin/emploi-du-temps/optimiser-repartition'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = _parseJsonSafely(response.body);

        // 🔥 INVALIDATION CACHE APRÈS OPTIMISATION
        invalidateCache('emplois_');

        return data ?? {'success': false, 'message': 'Réponse invalide'};
      } else {
        final errorData = _parseJsonSafely(response.body);
        throw Exception(errorData?['message'] ?? 'Erreur lors de l\'optimisation');
      }
    } catch (e) {
      print('❌ Erreur optimiserRepartition: $e');
      throw Exception('Erreur d\'optimisation: $e');
    }
  }

  /// 🔥 MÉTHODES UTILITAIRES CACHE
  static Map<String, dynamic> getCacheStats() {
    return {
      'cache_size': _cache.length,
      'max_size': MAX_CACHE_SIZE,
      'cache_duration_seconds': CACHE_DURATION_SECONDS,
      'entries': _cache.keys.toList(),
      'memory_usage': '${(_cache.length * 0.1).toStringAsFixed(1)} MB (estimation)',
    };
  }

  static void clearExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiresAt));
    print('🧹 Cache expiré nettoyé: ${_cache.length} entrées restantes');
  }
}

/// 🔥 CLASSES DE DONNÉES OPTIMISÉES
class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  final DateTime createdAt;

  CacheEntry({
    required this.data,
    required this.expiresAt,
    required this.createdAt,
  });
}

class EmploiResponse {
  final List<Map<String, dynamic>> emplois;
  final PaginationInfo pagination;
  final DateTime timestamp;
  final bool isFromCache;
  final String? cacheWarning;
  final String? error;

  EmploiResponse({
    required this.emplois,
    required this.pagination,
    required this.timestamp,
    this.isFromCache = false,
    this.cacheWarning,
    this.error,
  });
}

class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 50,
      total: json['total'] ?? 0,
      from: json['from'],
      to: json['to'],
    );
  }

  factory PaginationInfo.empty() {
    return PaginationInfo(
      currentPage: 1,
      lastPage: 1,
      perPage: 50,
      total: 0,
    );
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;

  HttpException(this.message, this.statusCode);

  @override
  String toString() => 'HttpException: $message (Status: $statusCode)';
}