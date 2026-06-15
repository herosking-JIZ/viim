import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/nav_tile.dart';

class ProfilHubScreen extends ConsumerWidget {
  const ProfilHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Mon profil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(user),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Compte'),
                  const SizedBox(height: 12),
                  SectionCard(
                    child: Column(
                      children: [
                        NavTile(
                          icon: Icons.person_outline,
                          title: 'Mes informations',
                          onTap: () => context.push('/profil/mes-informations'),
                        ),
                        const Divider(height: 1),
                        NavTile(
                          icon: Icons.location_on_outlined,
                          title: 'Mes adresses',
                          onTap: () => context.push('/profil/mes-adresses'),
                        ),
                        const Divider(height: 1),
                        NavTile(
                          icon: Icons.account_balance_wallet,
                          title: 'Portefeuille',
                          iconColor: Colors.green,
                          onTap: () => context.push('/profil/portefeuille'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Sécurité'),
                  const SizedBox(height: 12),
                  SectionCard(
                    child: NavTile(
                      icon: Icons.shield_outlined,
                      title: 'Sécurité & contacts',
                      iconColor: Colors.orange,
                      onTap: () => context.push('/profil/securite-contacts'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Partenaire'),
                  const SizedBox(height: 12),
                  SectionCard(
                    child: NavTile(
                      icon: Icons.directions_car_outlined,
                      title: 'Devenir chauffeur / propriétaire',
                      iconColor: Colors.blue,
                      onTap: () => context.push('/profil/devenir-partenaire'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Préférences'),
                  const SizedBox(height: 12),
                  SectionCard(
                    child: NavTile(
                      icon: Icons.settings_outlined,
                      title: 'Paramètres',
                      onTap: () => context.push('/profil/parametres'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        onTap: (index) {
          if (index != 4) {
            switch (index) {
              case 0:
                context.go('/home/passager');
              case 1:
                context.push('/trajets');
              case 2:
                context.push('/messages');
              case 3:
                context.push('/notifications');
            }
          }
        },
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

  Widget _buildHeader(dynamic user) {
    final initials = _getInitials(user.prenom, user.nom);
    return SectionCard(
      child: Column(
        children: [
          // Photo ou initiales
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: user.photoProfil != null
                ? ClipOval(
                    child: Image.network(
                      user.photoProfil!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Center(child: Text(initials, style: AppTextStyles.titleLarge)),
                    ),
                  )
                : Center(
                    child: Text(initials, style: AppTextStyles.titleLarge),
                  ),
          ),
          const SizedBox(height: 12),
          // Nom
          Text(
            '${user.prenom ?? ''} ${user.nom ?? ''}'.trim(),
            style: AppTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Téléphone
          Text(
            user.numeroTelephone ?? '-',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Compte ${user.statutCompte ?? 'actif'}',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(color: Colors.grey.shade600),
      ),
    );
  }

  String _getInitials(String? prenom, String? nom) {
    String p = (prenom?.isNotEmpty ?? false) ? prenom!.substring(0, 1).toUpperCase() : '';
    String n = (nom?.isNotEmpty ?? false) ? nom!.substring(0, 1).toUpperCase() : '';
    return (p + n).isNotEmpty ? p + n : '?';
  }
}
