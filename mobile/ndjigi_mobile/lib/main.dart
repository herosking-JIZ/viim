import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(
    // Indispensable pour Riverpod
    const ProviderScope(
      child: NdjigiApp(),
    ),
  );
}

class NdjigiApp extends StatelessWidget {
  const NdjigiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "N'DJIGI",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(), // Pour tester l'auth directement
    );
  }
}