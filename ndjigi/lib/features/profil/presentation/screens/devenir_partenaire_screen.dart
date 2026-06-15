import 'package:flutter/material.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_card.dart';

class DevenirPartennaireScreen extends StatelessWidget {
  const DevenirPartennaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Devenir partenaire'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SectionCard(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.directions_car_outlined,
                      size: 48,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Rejoignez notre réseau',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Devenez chauffeur ou propriétaire de véhicule et générez des revenus avec N\'DJIGI',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SectionCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                    title: const Text('Revenus flexibles'),
                    subtitle: const Text('Travaillez à votre rythme'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                    title: const Text('Support 24/7'),
                    subtitle: const Text('Une équipe prête à vous aider'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                    title: const Text('Sécurité garantie'),
                    subtitle: const Text('Protection complète des transactions'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SectionCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bientôt disponible',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'L\'inscription en tant que partenaire sera bientôt disponible. Veuillez vérifier cette section prochainement.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'En savoir plus',
              onPressed: () {},
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
