import 'package:flutter/material.dart';
import 'core/constants/yaounde_landmarks.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedMateApp());
}

class MedMateApp extends StatelessWidget {
  const MedMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedMate Yaoundé',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B), // Vert médical apaisant
          secondary: const Color(0xFF0288D1),
        ),
        useMaterial3: true,
      ),
      home: const PharmacySearchHomePage(),
    );
  }
}

class PharmacySearchHomePage extends StatelessWidget {
  const PharmacySearchHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedMate — Pharmacies Yaoundé'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Repères Urbains de Yaoundé',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sélectionnez votre carrefour ou quartier pour trouver les officines ouvertes ou de garde sans consommer inutilement de forfait internet.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Carrefours Incontournables (Accès Rapide)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...YaoundeLandmarks.list.map(
            (landmark) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.local_pharmacy, color: Theme.of(context).primaryColor),
                ),
                title: Text(landmark.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${landmark.quartier} (${landmark.arrondissement})\n${landmark.description}'),
                isThreeLine: true,
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recherche des officines autour de : ${landmark.nom}'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
