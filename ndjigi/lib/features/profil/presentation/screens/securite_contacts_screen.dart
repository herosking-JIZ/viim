import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/profile_assistance_providers.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_card.dart';

class SecuriteContactsScreen extends ConsumerStatefulWidget {
  const SecuriteContactsScreen({super.key});

  @override
  ConsumerState<SecuriteContactsScreen> createState() => _SecuriteContactsScreenState();
}

class _SecuriteContactsScreenState extends ConsumerState<SecuriteContactsScreen> {
  bool _showForm = false;
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _phoneController;
  late TextEditingController _relationController;
  String _countryCode = '+226';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _phoneController = TextEditingController();
    _relationController = TextEditingController();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nomController.clear();
    _prenomController.clear();
    _phoneController.clear();
    _relationController.clear();
  }

  Future<void> _addContact() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);

      await apiService.post<Map<String, dynamic>>(
        '/contacts-confiance',
        data: {
          'nom': _nomController.text,
          'prenom': _prenomController.text,
          'country_code': _countryCode,
          'phone': _phoneController.text,
          'relation': _relationController.text,
        },
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Contact ajouté'),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
      setState(() => _showForm = false);
      ref.invalidate(contactsConfianceProvider);
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
    final contactsAsync = ref.watch(contactsConfianceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Sécurité & contacts'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: contactsAsync.when(
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
                onPressed: () => ref.invalidate(contactsConfianceProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (contacts) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ajoutez des contacts de confiance pour les urgences',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (contacts.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      const Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Aucun contact'),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Ajouter un contact',
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
                  itemCount: contacts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${contact.prenom} ${contact.nom}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Relation: ${contact.relation}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${contact.countryCode}${contact.phone}',
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
                  label: 'Ajouter un nouveau contact',
                  onPressed: () => setState(() => _showForm = true),
                ),
              ],
              if (_showForm) ...[
                const SizedBox(height: 32),
                SectionCard(
                  child: Column(
                    children: [
                      const Text('Nouveau contact de confiance'),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Prénom',
                        controller: _prenomController,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Nom',
                        controller: _nomController,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Relation (ex: Mère, Ami)',
                        controller: _relationController,
                        prefixIcon: Icons.people_outline,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _countryCode,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _countryCode = value);
                                }
                              },
                              items: [
                                '+226',
                                '+225',
                                '+224',
                                '+221',
                                '+233',
                              ]
                                  .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                                  .toList(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: AppTextField(
                              label: 'Téléphone',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
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
                              onPressed: _addContact,
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
