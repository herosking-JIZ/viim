import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

/// Bouton primaire pleine largeur : hauteur 52, corners 8, green bg
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double? height;

  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && !isDisabled && onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
