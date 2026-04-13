import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext ConsumerState, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets(20.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: "Mot de passe")),
            if (authState.isLoading) CircularProgressIndicator(),
            ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).login(emailController.text, passwordController.text),
              child: Text("Se connecter"),
            ),
            if (authState.errorMessage != null) Text(authState.errorMessage!, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}