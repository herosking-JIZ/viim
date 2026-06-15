import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/profile_assistance_providers.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_card.dart';

class PortefeuilleScreen extends ConsumerWidget {
  const PortefeuilleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portefeuilleAsync = ref.watch(portefeuilleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Portefeuille'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: portefeuilleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: ${error.toString()}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(portefeuilleProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (portefeuille) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SectionCard(
                child: Column(
                  children: [
                    Text(
                      'Solde disponible',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${portefeuille.solde.toStringAsFixed(2)} ${portefeuille.devise}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (portefeuille.detteCommission != null && portefeuille.detteCommission! > 0) ...[
                      Text(
                        'Dette commission: ${portefeuille.detteCommission!.toStringAsFixed(2)} ${portefeuille.devise}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        portefeuille.statut.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Opérations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Ajouter du crédit',
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Historique des transactions'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Retirer des fonds'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
