import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/profile_assistance_providers.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_card.dart';

class MesAdressesScreen extends ConsumerStatefulWidget {
  const MesAdressesScreen({super.key});

  @override
  ConsumerState<MesAdressesScreen> createState() => _MesAdressesScreenState();
}

class _MesAdressesScreenState extends ConsumerState<MesAdressesScreen> {
  bool _showForm = false;
  late TextEditingController _addressController;
  late TextEditingController _labelController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _labelController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _labelController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _addressController.clear();
    _labelController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
  }

  Future<void> _addAddress() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);

      await apiService.post<Map<String, dynamic>>(
        '/addresses',
        data: {
          'label': _labelController.text,
          'address': _addressController.text,
          'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
          'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
        },
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Adresse ajoutée'),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
      setState(() => _showForm = false);
      ref.invalidate(addressesProvider);
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Mes adresses'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: addressesAsync.when(
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
                onPressed: () => ref.invalidate(addressesProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (addresses) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (addresses.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      const Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Aucune adresse'),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Ajouter une adresse',
                        onPressed: () => setState(() => _showForm = true),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                )
              else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            address.address,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${address.latitude}, Lng: ${address.longitude}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Éditer'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text('Supprimer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Ajouter une nouvelle adresse',
                  onPressed: () => setState(() => _showForm = true),
                ),
              ],
              if (_showForm) ...[
                const SizedBox(height: 32),
                SectionCard(
                  child: Column(
                    children: [
                      const Text('Nouvelle adresse'),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Label (ex: Maison, Bureau)',
                        controller: _labelController,
                        prefixIcon: Icons.label_outline,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Adresse',
                        controller: _addressController,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Latitude',
                        controller: _latitudeController,
                        prefixIcon: Icons.location_on_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Longitude',
                        controller: _longitudeController,
                        prefixIcon: Icons.location_on_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _showForm = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Ajouter',
                              isLoading: _isLoading,
                              onPressed: _addAddress,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
