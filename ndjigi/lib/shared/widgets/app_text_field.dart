import 'package:flutter/material.dart';
import '../../core/theme/text_styles.dart';

/// Champ texte stylisé : label flottant, corners 8, validation inline
class AppTextField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int? maxLines;
  final int minLines;

  const AppTextField({
    required this.label,
    this.initialValue,
    this.controller,
    this.prefixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    super.key,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  String? _errorText;

  void _validate() {
    final controller = widget.controller;
    final value = controller?.text ?? widget.initialValue ?? '';
    setState(() {
      _errorText = widget.validator?.call(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          onChanged: (_) {
            if (_errorText != null) _validate();
          },
          onEditingComplete: _validate,
          style: AppTextStyles.bodyMedium,
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorText!,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
          ),
        ],
      ],
    );
  }
}
