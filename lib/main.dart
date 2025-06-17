// main.dart
import 'package:flutter/material.dart';
import 'package:memoire/pages/emploi_du_temps_page.dart';
import 'package:memoire/pages/splash_screen.dart';
import 'package:memoire/screens/analyse_emploi_du_temps_screen.dart';
import 'screens/create_creneau_screen.dart';
import 'screens/generation_auto_screen.dart';


void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),

      // 🚀 NOUVELLES ROUTES POUR L'EMPLOI DU TEMPS
      routes: {
        '/emploi-du-temps': (context) => const EmploiDuTempsPage(),
        '/create-creneau': (context) => const CreateCreneauScreen(),
        '/generation-auto': (context) => const GenerationAutoScreen(),
        '/analyse-emploi': (context) => const AnalyseEmploiDuTempsScreen(),
      },
    );
  }
}