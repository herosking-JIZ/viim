import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/nav_tile.dart';
import '../widgets/carrousel_pub.dart';

class ChauffeurVehiculeScreen extends ConsumerWidget {
  const ChauffeurVehiculeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Mon véhicule'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Modification bientôt disponible')),
              );
            },
            child: Text(
              'Modifier',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Carrousel images véhicule
            CarrouselPub(height: 220),
            const SizedBox(height: 16),

            // Statistiques grid
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Courses\neffectuées', '0'),
                _buildStatCard('Revenus\ngénérés', '0 FCFA'),
                _buildStatCard('Note\nvéhicule', '—'),
                _buildStatCard('Km\nparcourus', '0'),
              ],
            ),
            const SizedBox(height: 16),

            // Informations
            Text(
              'Informations',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                children: [
                  _infoRow('Marque', '—'),
                  const Divider(height: 16),
                  _infoRow('Modèle', '—'),
                  const Divider(height: 16),
                  _infoRow('Immatriculation', '—'),
                  const Divider(height: 16),
                  _infoRow('Couleur', '—'),
                  const Divider(height: 16),
                  _infoRow('Année', '—'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Documents
            Text(
              'Documents',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SectionCard(
              child: Column(
                children: [
                  NavTile(
                    icon: Icons.document_scanner_outlined,
                    title: 'Assurance',
                    subtitle: 'À fournir',
                    iconColor: AppColors.warning,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Upload document bientôt disponible'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  NavTile(
                    icon: Icons.description_outlined,
                    title: 'Carte grise',
                    subtitle: 'À fournir',
                    iconColor: AppColors.warning,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Upload document bientôt disponible'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return SectionCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
