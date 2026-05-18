import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../services/auth_service.dart';

/// OTP verification screen
/// Features:
///   - 6 digit input fields with auto-focus
///   - Auto-submit when all digits entered
///   - Backspace navigation
///   - 60-second countdown timer for resend
///   - Error handling
///   - Attempts remaining display
class OtpVerificationScreen extends StatefulWidget {
  final AuthService authService;
  final String phone;
  final String phoneMasked;

  const OtpVerificationScreen({
    Key? key,
    required this.authService,
    required this.phone,
    required this.phoneMasked,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  bool _isLoading = false;
  String? _errorMessage;
  int? _attemptsRemaining;

  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and focus nodes for 6 OTP fields
    _controllers = List.generate(6, (i) => TextEditingController());
    _focusNodes = List.generate(6, (i) => FocusNode());

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });

    // Start resend timer (60 seconds)
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  /// Start 60-second countdown for resend button
  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) {
            _resendTimer?.cancel();
          }
        });
      }
    });
  }

  /// Handle OTP field input
  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Only allow single digit
      _controllers[index].text = value[0];
      return;
    }

    // Move to next field if digit entered
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 6 digits entered
    if (index == 5 && value.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), _verifyOtp);
    }
  }

  /// Handle backspace (navigate to previous field)
  void _onBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  /// Get full OTP code from all fields
  String _getOtpCode() {
    return _controllers.map((c) => c.text).join();
  }

  /// Verify OTP code
  Future<void> _verifyOtp() async {
    final otpCode = _getOtpCode();

    if (otpCode.length != 6) {
      setState(() {
        _errorMessage = 'Veuillez entrer un code à 6 chiffres.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _attemptsRemaining = null;
    });

    try {
      final result = await widget.authService.verifyOtp(widget.phone, otpCode);

      if (mounted) {
        // Check if TOTP setup or verification is required
        if (result['requires_totp_setup'] == true) {
          // Route to TOTP setup screen
          context.go('/setup-totp', extra: {
            'login_token': result['login_token'],
            'qr_code_url': result['qr_code_url'],
            'totp_secret': result['totp_secret'],
          });
        } else if (result['requires_totp'] == true) {
          // Route to TOTP verification screen
          context.go('/verify-totp', extra: {
            'login_token': result['login_token'],
          });
        } else {
          // Success: navigate to dashboard
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().replaceAll('Exception: ', '');

        setState(() {
          _isLoading = false;

          // Check for specific error codes
          if (errorStr.contains('Trop de tentatives')) {
            _errorMessage = 'Trop de tentatives. Réessayez dans 15 minutes.';
          } else if (errorStr.contains('incorrect')) {
            // Try to extract attempts remaining
            _errorMessage = 'Code OTP incorrect.';
            // Parse attempts if available
          } else {
            _errorMessage = errorStr;
          }
        });

        // Clear OTP fields on error
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  /// Resend OTP code
  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) {
      return; // Still on cooldown
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.resendOtp(widget.phone);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });

        // Clear fields and restart timer
        for (var controller in _controllers) {
          controller.clear();
        }
        _startResendTimer();
        _focusNodes[0].requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nouveau code envoyé.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Code de vérification',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // Phone number
              Text(
                'Entrez le code envoyé à ${widget.phoneMasked}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 32),

              // OTP input fields (6 digits)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      enabled: !_isLoading,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onChanged(index, value),
                      onKey: (event) {
                        if (event.isKeyPressed(LogicalKeyboardKey.backspace)) {
                          _onBackspace(index);
                        }
                      },
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),

              const SizedBox(height: 32),

              // Verify button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Vérifier',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Resend button with cooldown
              TextButton(
                onPressed:
                    _resendCountdown > 0 || _isLoading ? null : _resendOtp,
                child: Text(
                  _resendCountdown > 0
                      ? 'Renvoyer dans ${_resendCountdown}s'
                      : 'Renvoyer le code',
                  style: TextStyle(
                    color: _resendCountdown > 0
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
