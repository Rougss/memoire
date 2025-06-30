import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _isConnected = true;
  static VoidCallback? _onConnectionChanged;

  // Initialiser le service de connectivité
  static Future<void> initialize({VoidCallback? onConnectionChanged}) async {
    _onConnectionChanged = onConnectionChanged;

    // Vérifier la connectivité initiale
    await checkConnectivity();

    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
          (List<ConnectivityResult> results) async {
        await checkConnectivity();
        _onConnectionChanged?.call();
      },
    );
  }

  // Vérifier la connectivité réelle (pas seulement si connecté au WiFi/Mobile)
  static Future<bool> checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      // Si aucune connexion disponible
      if (connectivityResults.isEmpty ||
          connectivityResults.every((result) => result == ConnectivityResult.none)) {
        _isConnected = false;
        return false;
      }

      // Vérifier si on peut vraiment accéder à Internet
      final result = await InternetAddress.lookup('google.com');
      _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  // Obtenir le statut de connexion actuel
  static bool get isConnected => _isConnected;

  // Obtenir le type de connexion
  static Future<String> getConnectionType() async {
    final connectivityResults = await _connectivity.checkConnectivity();

    if (connectivityResults.isEmpty) {
      return 'Aucune connexion';
    }

    // Prendre le premier type de connexion disponible
    final connectivityResult = connectivityResults.first;

    switch (connectivityResult) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.none:
        return 'Aucune connexion';
      default:
        return 'Inconnue';
    }
  }

  // Nettoyer les ressources
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _onConnectionChanged = null;
  }

  // Wrapper pour les appels API avec gestion d'erreur
  static Future<T> executeWithConnectivity<T>(
      Future<T> Function() apiCall, {
        T? fallbackValue,
        String? errorMessage,
      }) async {
    if (!await checkConnectivity()) {
      throw NoInternetException(
          errorMessage ?? 'Aucune connexion Internet disponible'
      );
    }

    try {
      return await apiCall();
    } on SocketException {
      throw NoInternetException('Impossible de se connecter au serveur');
    } on TimeoutException {
      throw NoInternetException('Délai d\'attente dépassé');
    } catch (e) {
      if (e is NoInternetException) rethrow;
      throw ApiException('Erreur lors de l\'appel API: $e');
    }
  }
}

// Exceptions personnalisées
class NoInternetException implements Exception {
  final String message;
  NoInternetException(this.message);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}