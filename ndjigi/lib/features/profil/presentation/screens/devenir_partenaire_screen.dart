import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/document_upload_tile.dart';
import '../providers/demande_extension_provider.dart';

// ── Écran de demande d'extension de profil ──────────────────────────

class DevenirPartennaireScreen extends ConsumerStatefulWidget {
  const DevenirPartennaireScreen({super.key});

  @override
  ConsumerState<DevenirPartennaireScreen> createState() =>
      _DevenirPartennaireScreenState();
}

class _DevenirPartennaireScreenState
    extends ConsumerState<DevenirPartennaireScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les demandes existantes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(demandeExtensionProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demandeExtensionProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Devenir partenaire'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section A: Sélection du rôle ──────────────────
                  _buildRoleSelection(context, state),

                  // ── Section B: Bannière demande existante ─────────
                  if (state.selectedRole != null && state.hasActiveDemande)
                    _buildActiveDemandeAlert(state),

                  // ── Section C: Documents requis (si rôle sélectionné)
                  if (state.selectedRole != null && !state.hasActiveDemande)
                    _buildDocumentsSection(state),

                  // ── Message d'erreur global ──────────────────────
                  if (state.errorMessage != null)
                    _buildErrorAlert(state.errorMessage!),

                  // ── Bouton soumettre ────────────────────────────
                  if (state.selectedRole != null && !state.hasActiveDemande)
                    _buildSubmitButton(state),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Sélection du rôle ──────────────────────────────────────────────

  Widget _buildRoleSelection(BuildContext context, DemandeExtensionState state) {
    final canSelectChauffeur = !state.existingDemandes.any((d) =>
        d.extensionType == 'chauffeur' && d.statut != 'refuse');
    final canSelectProp = !state.existingDemandes.any((d) =>
        d.extensionType == 'proprietaire' && d.statut != 'refuse');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quel rôle souhaitez-vous ajouter ?',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (canSelectChauffeur)
              _buildRoleCard(
                context,
                'Chauffeur',
                'Transportez des passagers',
                'chauffeur',
                state.selectedRole == 'chauffeur',
              ),
            if (canSelectProp)
              _buildRoleCard(
                context,
                'Propriétaire',
                'Louez vos véhicules',
                'proprietaire',
                state.selectedRole == 'proprietaire',
              ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    String title,
    String subtitle,
    String roleValue,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(demandeExtensionProvider.notifier).selectRole(roleValue);
        },
        child: SectionCard(
          child: Container(
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    roleValue == 'chauffeur'
                        ? Icons.directions_car
                        : Icons.home_work,
                    color: isSelected ? AppColors.background : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bannière demande existante ─────────────────────────────────────

  Widget _buildActiveDemandeAlert(DemandeExtensionState state) {
    final demande = state.existingDemandes.firstWhere(
      (d) =>
          d.extensionType == state.selectedRole &&
          (d.statut == 'en_attente' || d.statut == 'accepte'),
    );

    final (color, icon, message) = switch (demande.statut) {
      'en_attente' => (
        AppColors.warning,
        Icons.schedule,
        'Votre demande est en cours de traitement.',
      ),
      'accepte' => (
        AppColors.success,
        Icons.check_circle,
        'Votre demande a été acceptée ! Vous avez accès au nouveau rôle.',
      ),
      'refuse' => (
        AppColors.error,
        Icons.cancel,
        'Votre demande a été refusée. ${demande.motifRejet ?? 'Vous pouvez soumettre une nouvelle demande.'}',
      ),
      _ => (AppColors.info, Icons.info, 'État de votre demande'),
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Section documents ──────────────────────────────────────────────

  Widget _buildDocumentsSection(DemandeExtensionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents requis',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Chargez chaque document pour valider votre demande.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: state.docs.entries.map((entry) {
            final docType = entry.key;
            final docState = entry.value;
            final label = kDocLabels[docType] ?? docType;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DocumentUploadTile(
                label: label,
                uploadState: docState,
                onPickFile: () {
                  ref
                      .read(demandeExtensionProvider.notifier)
                      .pickFile(docType);
                },
                onUpload: () {
                  ref
                      .read(demandeExtensionProvider.notifier)
                      .uploadDocument(docType);
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Alert erreur ───────────────────────────────────────────────────

  Widget _buildErrorAlert(String message) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.error),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Bouton soumettre ───────────────────────────────────────────────

  Widget _buildSubmitButton(DemandeExtensionState state) {
    return Column(
      children: [
        PrimaryButton(
          label: 'Soumettre ma demande',
          isLoading: state.isSubmitting,
          isDisabled: !state.canSubmit,
          onPressed: () async {
            await ref
                .read(demandeExtensionProvider.notifier)
                .submitDemande();

            if (mounted && ref.read(demandeExtensionProvider).submitSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Demande envoyée avec succès ! Elle est en cours de traitement.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
              context.pop();
            }
          },
        ),
        const SizedBox(height: 12),
        if (!state.canSubmit && state.selectedRole != null)
          Text(
            'Tous les documents doivent être chargés pour soumettre.',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
