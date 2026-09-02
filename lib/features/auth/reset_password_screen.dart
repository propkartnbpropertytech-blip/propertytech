import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/design_system/tokens/app_colors.dart';
import '../../core/design_system/tokens/app_shadows.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/design_system/tokens/app_typography.dart';
import '../../core/utils/seo_helper.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? errorCode;
  final String? errorDescription;
  final String? tokenHash;
  final String? type;
  final String? code;
  final String? token;

  const ResetPasswordScreen({
    super.key,
    this.errorCode,
    this.errorDescription,
    this.tokenHash,
    this.type,
    this.code,
    this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSaving = false;
  bool _sessionLoaded = false;
  bool _isVerifyingLink = false;
  /// When true, show a Continue button before consuming token_hash (blocks email scanners).
  bool _needsManualConfirm = false;
  String? _errorMessage;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();

    SeoHelper.updateTags(
      title: 'Reset Password | PropKart CRM',
      description: 'Choose a new password for your PropKart account.',
      noIndex: true,
    );

    _bootstrapRecovery();
  }

  Future<void> _bootstrapRecovery() async {
    final errorCode = widget.errorCode;
    final errorDescription = widget.errorDescription;
    if (errorCode != null && errorCode.isNotEmpty) {
      setState(() {
        _errorMessage = _friendlyAuthError(errorCode, errorDescription);
      });
      return;
    }

    setState(() {
      _sessionLoaded = true;
      _needsManualConfirm = false;
      _isVerifyingLink = false;
    });
  }

  String _friendlyAuthError(String code, String? description) {
    final desc = (description ?? '').replaceAll('+', ' ').trim();
    if (code == 'otp_expired' || desc.toLowerCase().contains('expired')) {
      return 'This password reset link is invalid or has expired. Request a new reset from the login screen, or ask your administrator to set a new password.';
    }
    if (code == 'access_denied') {
      return 'Access to this reset link was denied. Request a new link and open it in your browser (not an in-app email preview).';
    }
    return desc.isNotEmpty
        ? desc
        : 'Unable to open this password reset link. Please request a new one.';
  }

  void _confirmTokenHash() {
    setState(() {
      _needsManualConfirm = false;
      _sessionLoaded = true;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final token = widget.token ?? widget.code ?? widget.tokenHash;
      final newPassword = _passwordController.text;

      await ApiClient().post('/auth/reset-password', {
        if (token != null && token.isNotEmpty) 'token': token,
        'password': newPassword,
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: CRMColors.surfaceElevatedOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: CRMColors.primaryOf(context), size: 28),
              const SizedBox(width: 10),
              Text(
                'Password Updated',
                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
              ),
            ],
          ),
          content: Text(
            'Your password has been successfully updated. You can now log in using your new credentials.',
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
          actions: [
            TextButton(
              onPressed: () {
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: Text(
                'Log In',
                style: TextStyle(
                  color: CRMColors.primaryOf(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1C1A18),
                          const Color(0xFF24211F),
                          const Color(0xFF1C1A18),
                        ]
                      : [
                          const Color(0xFFFFFFFF),
                          const Color(0xFFF7F7F6),
                          const Color(0xFFF4F4F3),
                        ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: CRMColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                  border: Border.all(color: CRMColors.borderOf(context), width: 1),
                  boxShadow: CRMShadows.large,
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              width: 36,
                              height: 36,
                              errorBuilder: (context, error, stackTrace) => Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: CRMColors.primaryOf(context).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.apartment_rounded,
                                  color: CRMColors.primaryOf(context),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'PropKart',
                              style: CRMTypography.sectionTitle.copyWith(
                                fontSize: 22,
                                color: CRMColors.primaryOf(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Reset Your Password',
                          style: CRMTypography.headline.copyWith(color: CRMColors.textOf(context)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a new secure password for your account.',
                          style: CRMTypography.subheadline.copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                        const SizedBox(height: 28),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CRMColors.danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: CRMColors.danger.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: CRMTypography.body.copyWith(
                                      color: CRMColors.danger,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CRMColors.primaryOf(context),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => context.go('/login'),
                            child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ] else if (_needsManualConfirm) ...[
                          Text(
                            'Tap continue to verify this reset link, then choose a new password.',
                            style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CRMColors.primaryOf(context),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isVerifyingLink ? null : _confirmTokenHash,
                            child: _isVerifyingLink
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ] else if (_isVerifyingLink || !_sessionLoaded) ...[
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    color: CRMColors.primaryOf(context),
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Verifying recovery session...',
                                  style: CRMTypography.body.copyWith(
                                    color: CRMColors.textSecondaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          PremiumTextField(
                            controller: _passwordController,
                            labelText: 'New Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: CRMColors.primaryOf(context).withOpacity(0.7),
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter a password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          PremiumTextField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleReset(),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: CRMColors.primaryOf(context).withOpacity(0.7),
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CRMColors.primaryOf(context),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isSaving ? null : _handleReset,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Save Password',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
