import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/profile_assistance_providers.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/models/utilisateur.dart';

const _cguUrl = 'https://ndjigi.com/cgu';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  int _selectedNavIndex = 4;
  bool _notificationsEnabled = true;
  bool _partageTrajetEnabled = false;
  String _langueSelected = 'fr';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('pref_notifications') ?? true;
      _partageTrajetEnabled = prefs.getBool('pref_partage_trajet') ?? false;
      _langueSelected = prefs.getString('pref_langue') ?? 'fr';
    });
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedNavIndex = index);
    _navigateToTab(index);
  }

  void _navigateToTab(int index) {
    switch (index) {
      case 0:
        context.go('/home/passager');
        break;
      case 1:
        context.push('/trajets');
        break;
      case 2:
        context.push('/messages');
        break;
      case 3:
        context.push('/notifications');
        break;
      case 4:
        break; // Already on profil
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: authState.user == null
          ? const Center(child: CircularProgressIndicator())
          : _buildProfilContent(authState.user!, context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Trajets'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildProfilContent(Utilisateur user, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildHeader(user),
          const SizedBox(height: 24),

          // Infos personnelles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPersonalInfoSection(user),
          ),
          const SizedBox(height: 24),

          // Adresses
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildAddressesSection(),
          ),
          const SizedBox(height: 24),

          // Portefeuille
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildWalletSection(),
          ),
          const SizedBox(height: 24),

          // Centre de sécurité
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSecuritySection(),
          ),
          const SizedBox(height: 24),

          // Devenir chauffeur/propriétaire
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildRoleSection(user),
          ),
          const SizedBox(height: 24),

          // Paramètres
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSettingsSection(user, context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(Utilisateur user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: user.photoProfil != null && user.photoProfil!.isNotEmpty
                    ? NetworkImage(user.photoProfil!)
                    : null,
                backgroundColor: Colors.white30,
                child: user.photoProfil == null || user.photoProfil!.isEmpty
                    ? const Icon(Icons.person, size: 48, color: Colors.white)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _showPhotoUploadDialog(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${user.prenom ?? ''} ${user.nom ?? ''}'.trim(),
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
          ),
          if (user.numeroTelephone != null) ...[
            const SizedBox(height: 8),
            Text(
              user.numeroTelephone!,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ],
          if (user.statutCompte == 'actif') ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Compte actif',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(Utilisateur user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Infos personnelles',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Prénom'),
          subtitle: Text(user.prenom ?? '-'),
          trailing: const Icon(Icons.edit, size: 18),
          onTap: () => _showEditDialog('Prénom', user.prenom, (value) => _updateProfile(user.copyWith(prenom: value))),
        ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Nom'),
          subtitle: Text(user.nom ?? '-'),
          trailing: const Icon(Icons.edit, size: 18),
          onTap: () => _showEditDialog('Nom', user.nom, (value) => _updateProfile(user.copyWith(nom: value))),
        ),
        ListTile(
          leading: const Icon(Icons.phone_outlined),
          title: const Text('Téléphone'),
          subtitle: Text(user.numeroTelephone ?? '-'),
          trailing: const Icon(Icons.edit, size: 18),
          onTap: () => _showEditDialog('Téléphone', user.numeroTelephone, (value) => _updateProfile(user.copyWith(numeroTelephone: value))),
        ),
        ListTile(
          leading: const Icon(Icons.email_outlined),
          title: const Text('E-mail'),
          subtitle: Text(user.email),
          trailing: const Icon(Icons.edit, size: 18),
          onTap: () => _showEditDialog('E-mail', user.email, (value) => _updateProfile(user.copyWith(email: value))),
        ),
      ],
    );
  }

  Widget _buildAddressesSection() {
    final addressesAsync = ref.watch(addressesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Adresses favorites',
              style: AppTextStyles.headlineSmall,
            ),
            TextButton(
              onPressed: () => _showAddAddressDialog(),
              child: const Text('+ Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        addressesAsync.when(
          data: (addresses) {
            if (addresses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Aucune adresse enregistrée',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(address.label),
                  subtitle: Text(address.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Modifier'),
                        onTap: () => _showEditAddressDialog(address),
                      ),
                      PopupMenuItem(
                        child: const Text('Supprimer'),
                        onTap: () => _deleteAddress(address.idAddress),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Erreur : ${error.toString()}'),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletSection() {
    final walletAsync = ref.watch(portefeuilleProvider);

    return walletAsync.when(
      data: (wallet) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solde disponible'),
                        Text(
                          '${wallet.solde.toStringAsFixed(2)} ${wallet.devise}',
                          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showRechargeBottomSheet(),
                      child: const Text('Recharger'),
                    ),
                    ElevatedButton(
                      onPressed: null,
                      child: Tooltip(
                        message: 'Indisponible pour les passagers',
                        child: const Text('Retirer'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/wallet-history'),
                      child: const Text('Historique'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) {
        // Handle 404: portefeuille not found
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solde disponible'),
                        Text(
                          '0.00 XOF',
                          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showRechargeBottomSheet(),
                      child: const Text('Recharger'),
                    ),
                    ElevatedButton(
                      onPressed: null,
                      child: Tooltip(
                        message: 'Indisponible pour les passagers',
                        child: const Text('Retirer'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/wallet-history'),
                      child: const Text('Historique'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Centre de sécurité',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Text('Contacts de confiance'),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final contactsAsync = ref.watch(contactsConfianceProvider);
                    return contactsAsync.when(
                      data: (contacts) {
                        final displayedContacts = contacts.take(3).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (displayedContacts.isEmpty)
                              Text(
                                'Aucun contact enregistré (max 3)',
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  displayedContacts.length,
                                  (index) {
                                    final contact = displayedContacts[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        '${contact.prenom} ${contact.nom} (${contact.relation})',
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _showAddTrustedContactDialog(),
                              child: const Text('Ajouter un contact'),
                            ),
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Erreur : ${error.toString()}'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.warning_outlined),
            title: const Text('Tutoriel SOS'),
            subtitle: const Text('Apprenez à utiliser la fonction SOS'),
            onTap: () => _showSOSTutorialBottomSheet(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.share_location_outlined),
            title: const Text('Partager mon trajet'),
            subtitle: const Text('Partage automatique en cas de trajet'),
            trailing: Switch(
              value: _partageTrajetEnabled,
              onChanged: (value) async {
                setState(() => _partageTrajetEnabled = value);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('pref_partage_trajet', value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSection(Utilisateur user) {
    final isDriver = user.roles.contains('chauffeur');
    final isOwner = user.roles.contains('proprietaire');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Text('Rôles supplémentaires'),
              ],
            ),
            const SizedBox(height: 16),
            if (!isDriver)
              ListTile(
                title: const Text('Devenir chauffeur'),
                onTap: () => _showBecomeDriverBottomSheet(),
              ),
            if (!isOwner)
              ListTile(
                title: Text(isDriver ? 'Ajouter le rôle propriétaire' : 'Devenir propriétaire'),
                onTap: () => _showBecomeOwnerBottomSheet(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(Utilisateur user, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notifications'),
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('pref_notifications', value);
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Langue'),
          subtitle: Text(_getLanguageName(_langueSelected)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLanguageDialog(),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Paramètres de confidentialité'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/privacy-settings'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Conditions d\'utilisation'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _openURL(_cguUrl),
        ),
        ListTile(
          leading: const Icon(Icons.info_outlined),
          title: const Text('Version'),
          subtitle: const Text('v1.0.0'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          onTap: () => _showLogoutConfirmation(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Color(0xFFE57373)),
          title: const Text('Supprimer mon compte', style: TextStyle(color: Color(0xFFE57373))),
          onTap: () => _showDeleteAccountConfirmation(context),
        ),
      ],
    );
  }

  // Dialog & Bottom Sheet Methods

  void _showEditDialog(String title, String? initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _updateProfile(Utilisateur updatedUser) {
    final apiService = ref.read(apiServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    apiService.patch<Map<String, dynamic>>(
      '/utilisateurs/profil',
      data: {
        if (updatedUser.prenom != null) 'prenom': updatedUser.prenom,
        if (updatedUser.nom != null) 'nom': updatedUser.nom,
        if (updatedUser.numeroTelephone != null) 'numero_telephone': updatedUser.numeroTelephone,
        if (updatedUser.email.isNotEmpty) 'email': updatedUser.email,
      },
    ).then((_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')),
      );
      ref.invalidate(authProvider);
    }).catchError((error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : ${error.toString()}')),
      );
    });
  }

  void _showAddAddressDialog() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une adresse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(hintText: 'Label (ex: Domicile)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(hintText: 'Adresse'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _createAddress(labelController.text, addressController.text);
              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _createAddress(String label, String address) {
    final apiService = ref.read(apiServiceProvider);
    apiService.post<Map<String, dynamic>>(
      '/addresses',
      data: {
        'label': label,
        'address': address,
        'latitude': 0.0,
        'longitude': 0.0,
        'isfavorite': false,
      },
    ).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse ajoutée')),
      );
      ref.invalidate(addressesProvider);
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${error.toString()}')),
      );
    });
  }

  void _showEditAddressDialog(dynamic address) {
    final labelController = TextEditingController(text: address.label);
    final addressController = TextEditingController(text: address.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier adresse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(hintText: 'Label'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(hintText: 'Adresse'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateAddress(address.idAddress, labelController.text, addressController.text);
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _updateAddress(String id, String label, String address) {
    final apiService = ref.read(apiServiceProvider);
    apiService.patch<Map<String, dynamic>>(
      '/addresses/$id',
      data: {
        'label': label,
        'address': address,
      },
    ).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse mise à jour')),
      );
      ref.invalidate(addressesProvider);
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${error.toString()}')),
      );
    });
  }

  void _deleteAddress(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer adresse'),
        content: const Text('Êtes-vous sûr ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final apiService = ref.read(apiServiceProvider);
              final messenger = ScaffoldMessenger.of(context);
              apiService.delete<Map<String, dynamic>>('/addresses/$id')
                  .then((_) {
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Adresse supprimée')),
                      );
                      ref.invalidate(addressesProvider);
                    }
                  })
                  .catchError((error) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Erreur : ${error.toString()}')),
                      );
                    }
                  });
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showPhotoUploadDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo upload: TODO')),
    );
  }

  void _showRechargeBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recharger mon portefeuille'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTrustedContactDialog() {
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String selectedRelation = 'parent';
          String selectedCountryCode = '+226';

          return AlertDialog(
            title: const Text('Ajouter contact de confiance'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: prenomController,
                    decoration: const InputDecoration(hintText: 'Prénom'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nomController,
                    decoration: const InputDecoration(hintText: 'Nom'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCountryCode,
                    items: const [
                      DropdownMenuItem(value: '+226', child: Text('+226 (Burkina Faso)')),
                      DropdownMenuItem(value: '+221', child: Text('+221 (Sénégal)')),
                      DropdownMenuItem(value: '+225', child: Text('+225 (Côte d\'Ivoire)')),
                      DropdownMenuItem(value: '+223', child: Text('+223 (Mali)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCountryCode = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(hintText: 'Téléphone'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedRelation,
                    items: const [
                      DropdownMenuItem(value: 'parent', child: Text('Parent')),
                      DropdownMenuItem(value: 'enfant', child: Text('Enfant')),
                      DropdownMenuItem(value: 'conjoint', child: Text('Conjoint')),
                      DropdownMenuItem(value: 'frere', child: Text('Frère')),
                      DropdownMenuItem(value: 'soeur', child: Text('Sœur')),
                      DropdownMenuItem(value: 'autre', child: Text('Autre')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedRelation = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  _createTrustedContact(
                    nom: nomController.text,
                    prenom: prenomController.text,
                    phone: phoneController.text,
                    relation: selectedRelation,
                    countryCode: selectedCountryCode,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createTrustedContact({
    required String nom,
    required String prenom,
    required String phone,
    required String relation,
    required String countryCode,
  }) {
    final apiService = ref.read(apiServiceProvider);
    apiService.post<Map<String, dynamic>>(
      '/contacts-confiance',
      data: {
        'nom': nom,
        'prenom': prenom,
        'country_code': countryCode,
        'phone': phone,
        'relation': relation,
      },
    ).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact ajouté')),
      );
      ref.invalidate(contactsConfianceProvider);
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${error.toString()}')),
      );
    });
  }

  void _showSOSTutorialBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tutoriel SOS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'La fonction SOS vous permet d\'alerter rapidement vos contacts de confiance en cas d\'urgence lors d\'un trajet.',
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Assurez-vous d\'avoir ajouté des contacts de confiance',
              ),
              const SizedBox(height: 8),
              const Text(
                '2. Lors d\'un trajet, appuyez longuement sur le bouton rouge SOS',
              ),
              const SizedBox(height: 8),
              const Text(
                '3. Vos contacts seront alertés avec votre localisation',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBecomeDriverBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Devenir chauffeur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Documents requis:'),
            const SizedBox(height: 8),
            const Text('• Permis de conduire'),
            const Text('• Carte grise du véhicule'),
            const Text('• Certificat d\'assurance'),
            const Text('• Document d\'identité'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/driver-documents');
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBecomeOwnerBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Devenir propriétaire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Documents requis:'),
            const SizedBox(height: 8),
            const Text('• Carte grise du véhicule'),
            const Text('• Certificat d\'assurance'),
            const Text('• Permis de conduire'),
            const Text('• Document d\'identité'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/owner-documents');
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sélectionner langue'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _langueSelected = 'fr');
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('pref_langue', 'fr');
            },
            child: const Text('Français'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _langueSelected = 'en');
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('pref_langue', 'en');
            },
            child: const Text('English'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _langueSelected = 'wo');
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('pref_langue', 'wo');
            },
            child: const Text('Wolof'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
              context.go('/welcome');
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text('Cette action est irréversible. Tous vos données seront supprimées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteAccountFinalConfirmation(context);
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountFinalConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation finale'),
        content: const Text('Tapez "SUPPRIMER" pour confirmer la suppression de votre compte'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final authState = ref.read(authProvider);
              if (authState.user != null) {
                final apiService = ref.read(apiServiceProvider);
                final navigator = Navigator.of(context);
                final router = GoRouter.of(context);
                final messenger = ScaffoldMessenger.of(context);
                apiService.delete<Map<String, dynamic>>(
                  '/utilisateurs/${authState.user!.idUtilisateur}',
                ).then((_) {
                  if (mounted) {
                    ref.read(authProvider.notifier).logout();
                    navigator.pop();
                    router.go('/welcome');
                  }
                }).catchError((error) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Erreur : ${error.toString()}')),
                    );
                  }
                });
              }
            },
            child: const Text('Supprimer mon compte'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'wo':
        return 'Wolof';
      default:
        return 'Français';
    }
  }

  Future<void> _openURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir : $url')),
      );
    }
  }
}
