import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';

class MfaSecurityCard extends StatefulWidget {
  final UserModel user;

  const MfaSecurityCard({
    super.key,
    required this.user,
  });

  @override
  State<MfaSecurityCard> createState() => _MfaSecurityCardState();
}

class _MfaSecurityCardState extends State<MfaSecurityCard> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool get _isPrivileged =>
      widget.user.role == 'Super Admin' || widget.user.role == 'Admin';

  @override
  Widget build(BuildContext context) {
    if (!_isPrivileged) return const SizedBox.shrink();

    final isEnabled = widget.user.mfaEnabled;

    return CRMCard(
      elevated: true,
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? CRMColors.success.withValues(alpha: 0.12)
                            : CRMColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEnabled
                            ? Icons.verified_user_rounded
                            : Icons.gpp_maybe_rounded,
                        color: isEnabled ? CRMColors.success : CRMColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Two-Factor Authentication (2FA)',
                          style: CRMTypography.sectionTitle.copyWith(
                            color: CRMColors.textOf(context),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'RFC 6238 TOTP Standard',
                          style: CRMTypography.caption.copyWith(
                            color: CRMColors.textSecondaryOf(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? CRMColors.success.withValues(alpha: 0.12)
                        : CRMColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                    border: Border.all(
                      color: isEnabled
                          ? CRMColors.success.withValues(alpha: 0.3)
                          : CRMColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isEnabled ? 'ENABLED' : 'DISABLED',
                    style: CRMTypography.captionBold.copyWith(
                      color: isEnabled ? CRMColors.success : CRMColors.warning,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            Text(
              isEnabled
                  ? 'Your account is secured with Two-Factor Authentication. A 6-digit TOTP token is required whenever you sign in.'
                  : 'Add an extra layer of security to your admin account. When enabled, signing in requires a 6-digit verification code from your authenticator app (Google Authenticator, Microsoft Authenticator, Apple Keychain, etc.).',
              style: CRMTypography.body.copyWith(
                color: CRMColors.textSecondaryOf(context),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: CRMSpacing.l),
            Row(
              children: [
                if (!isEnabled)
                  CRMButton(
                    label: 'Enable 2FA',
                    prefixIcon: Icons.qr_code_rounded,
                    isLoading: _isLoading,
                    onPressed: _startMfaSetup,
                  )
                else
                  CRMButton(
                    label: 'Disable 2FA',
                    prefixIcon: Icons.lock_open_rounded,
                    variant: CRMButtonVariant.danger,
                    isLoading: _isLoading,
                    onPressed: _confirmDisableMfa,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMfaSetup() async {
    setState(() => _isLoading = true);
    try {
      final res = await _authService.setupMfa();
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : <String, dynamic>{};

      final secret = data['secret']?.toString() ?? '';
      final otpauthUrl = data['otpauthUrl']?.toString() ?? '';

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (secret.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate MFA secret key.'),
            backgroundColor: CRMColors.danger,
          ),
        );
        return;
      }

      await _showSetupModal(secret, otpauthUrl);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate 2FA setup: $e'),
            backgroundColor: CRMColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showSetupModal(String secret, String otpauthUrl) async {
    final codeController = TextEditingController();
    bool isVerifying = false;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (innerCtx, setModalState) {
          return AlertDialog(
            backgroundColor: CRMColors.cardBgOf(innerCtx),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.security_rounded, color: CRMColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Setup Two-Factor Authentication',
                    style: CRMTypography.sectionTitle.copyWith(
                      color: CRMColors.textOf(innerCtx),
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 1: Add key to Authenticator App',
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.textOf(innerCtx),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Open Google Authenticator, Microsoft Authenticator, or Apple Keychain, choose "Enter a setup key", and paste this secret:',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(innerCtx),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: CRMColors.backgroundOf(innerCtx),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CRMColors.borderOf(innerCtx)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              secret,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            tooltip: 'Copy secret key',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: secret));
                              ScaffoldMessenger.of(innerCtx).showSnackBar(
                                const SnackBar(
                                  content: Text('Secret key copied to clipboard!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Step 2: Enter 6-digit confirmation code',
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.textOf(innerCtx),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the 6-digit code currently shown in your authenticator app to verify the setup:',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(innerCtx),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Pinput(
                        length: 6,
                        controller: codeController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        hapticFeedbackType: HapticFeedbackType.lightImpact,
                        forceErrorState: errorText != null,
                        errorText: errorText,
                        defaultPinTheme: PinTheme(
                          width: 48,
                          height: 54,
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: CRMColors.textOf(innerCtx),
                            fontFamily: 'monospace',
                          ),
                          decoration: BoxDecoration(
                            color: CRMColors.backgroundOf(innerCtx),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CRMColors.borderOf(innerCtx), width: 1.5),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 48,
                          height: 54,
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: CRMColors.primaryOf(innerCtx),
                            fontFamily: 'monospace',
                          ),
                          decoration: BoxDecoration(
                            color: CRMColors.cardBgOf(innerCtx),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CRMColors.primaryOf(innerCtx), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: CRMColors.primaryOf(innerCtx).withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        errorPinTheme: PinTheme(
                          width: 48,
                          height: 54,
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: CRMColors.danger,
                            fontFamily: 'monospace',
                          ),
                          decoration: BoxDecoration(
                            color: CRMColors.backgroundOf(innerCtx),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CRMColors.danger, width: 1.5),
                          ),
                        ),
                        separatorBuilder: (index) => const SizedBox(width: 8),
                        onChanged: (val) {
                          if (errorText != null) {
                            setModalState(() => errorText = null);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.of(dialogCtx).pop(),
                child: Text('Cancel', style: TextStyle(color: CRMColors.textSecondaryOf(innerCtx))),
              ),
              CRMButton(
                label: 'Confirm & Enable',
                isLoading: isVerifying,
                onPressed: () async {
                  final code = codeController.text.trim();
                  if (code.length != 6) {
                    setModalState(() => errorText = 'Please enter a 6-digit code');
                    return;
                  }

                  setModalState(() {
                    isVerifying = true;
                    errorText = null;
                  });

                  try {
                    await _authService.confirmMfa(code);
                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                    }
                    if (!mounted) return;
                    context.read<AuthBloc>().add(AuthCheckStatus());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Two-Factor Authentication is now enabled!'),
                        backgroundColor: CRMColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    setModalState(() {
                      isVerifying = false;
                      errorText = e.toString().replaceAll('Exception: ', '');
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDisableMfa() async {
    final passwordController = TextEditingController();
    bool isDisabling = false;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (innerCtx, setModalState) {
          return AlertDialog(
            backgroundColor: CRMColors.cardBgOf(innerCtx),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CRMColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: CRMColors.danger, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Disable Two-Factor Authentication',
                    style: CRMTypography.sectionTitle.copyWith(
                      color: CRMColors.textOf(innerCtx),
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to disable 2FA? This will make your account significantly less secure.',
                    style: CRMTypography.body.copyWith(
                      color: CRMColors.textSecondaryOf(innerCtx),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter your password to confirm:',
                    style: CRMTypography.bodyMedium.copyWith(
                      color: CRMColors.textOf(innerCtx),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Current account password',
                      errorText: errorText,
                      filled: true,
                      fillColor: CRMColors.backgroundOf(innerCtx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: CRMColors.borderOf(innerCtx)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: CRMColors.primaryOf(innerCtx), width: 2),
                      ),
                    ),
                    onChanged: (val) {
                      if (errorText != null) {
                        setModalState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDisabling ? null : () => Navigator.of(dialogCtx).pop(),
                child: Text('Cancel', style: TextStyle(color: CRMColors.textSecondaryOf(innerCtx))),
              ),
              CRMButton(
                label: 'Disable 2FA',
                variant: CRMButtonVariant.danger,
                isLoading: isDisabling,
                onPressed: () async {
                  final password = passwordController.text;
                  if (password.isEmpty) {
                    setModalState(() => errorText = 'Password is required');
                    return;
                  }

                  setModalState(() {
                    isDisabling = true;
                    errorText = null;
                  });

                  try {
                    await _authService.disableMfa(password);
                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                    }
                    if (!mounted) return;
                    context.read<AuthBloc>().add(AuthCheckStatus());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Two-Factor Authentication has been disabled.'),
                        backgroundColor: CRMColors.warning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    setModalState(() {
                      isDisabling = false;
                      errorText = e.toString().replaceAll('Exception: ', '');
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
