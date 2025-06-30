import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/connectivity_service.dart';

class NoConnectionScreen extends StatefulWidget {
  final VoidCallback? onRetry;
  final String? customMessage;
  final bool showRetryButton;

  const NoConnectionScreen({
    Key? key,
    this.onRetry,
    this.customMessage,
    this.showRetryButton = true,
  }) : super(key: key);

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
    });

    try {
      final isConnected = await ConnectivityService.checkConnectivity();

      if (isConnected) {
        widget.onRetry?.call();
      } else {
        // Attendre un peu pour montrer qu'on a essayé
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text('Toujours aucune connexion'),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animation des éléments principaux
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Icône principale avec animation
                      TweenAnimationBuilder(
                        duration: const Duration(seconds: 2),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(60),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.wifi_off_rounded,
                                size: 60,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Titre principal
                      const Text(
                        'Pas de connexion Internet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Message personnalisé ou par défaut
                      Text(
                        widget.customMessage ??
                            'Vérifiez votre connexion Internet et réessayez.\nL\'application a besoin d\'Internet pour fonctionner.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Informations de connexion
                      FutureBuilder<String>(
                        future: ConnectivityService.getConnectionType(),
                        builder: (context, snapshot) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getConnectionIcon(snapshot.data ?? ''),
                                  size: 20,
                                  color: const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'État: ${snapshot.data ?? 'Vérification...'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Boutons d'action
              if (widget.showRetryButton) ...[
                // Bouton de retry principal
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isRetrying
                      ? Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SpinKitThreeInOut(
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Vérification...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFF1D4ED8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _handleRetry,
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Réessayer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Conseils de dépannage
                TextButton(
                  onPressed: () => _showTroubleshootingDialog(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Conseils de dépannage',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getConnectionIcon(String connectionType) {
    switch (connectionType.toLowerCase()) {
      case 'wifi':
        return Icons.wifi_off_rounded;
      case 'mobile':
        return Icons.signal_cellular_off_rounded;
      case 'ethernet':
        return Icons.cable_rounded;
      default:
        return Icons.cloud_off_rounded;
    }
  }

  void _showTroubleshootingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF3B82F6)),
            SizedBox(width: 12),
            Text('Conseils de dépannage'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTroubleshootingItem(
              Icons.wifi_rounded,
              'Vérifiez votre connexion WiFi',
            ),
            _buildTroubleshootingItem(
              Icons.signal_cellular_4_bar_rounded,
              'Activez les données mobiles',
            ),
            _buildTroubleshootingItem(
              Icons.airplanemode_inactive_rounded,
              'Désactivez le mode avion',
            ),
            _buildTroubleshootingItem(
              Icons.router_rounded,
              'Redémarrez votre routeur',
            ),
            _buildTroubleshootingItem(
              Icons.refresh_rounded,
              'Réessayez dans quelques minutes',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}