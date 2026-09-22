import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pinput/pinput.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';

class MfaVerifyDialog extends StatefulWidget {
  final String mfaChallengeId;
  final String email;
  final String role;
  final bool rememberMe;
  final bool mfaSetupRequired;
  final String? secret;
  final String? otpauthUrl;

  const MfaVerifyDialog({
    super.key,
    required this.mfaChallengeId,
    required this.email,
    required this.role,
    required this.rememberMe,
    this.mfaSetupRequired = false,
    this.secret,
    this.otpauthUrl,
  });

  static Future<void> show(BuildContext context, MfaChallengeRequired state) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MfaVerifyDialog(
        mfaChallengeId: state.mfaChallengeId,
        email: state.email,
        role: state.role,
        rememberMe: state.rememberMe,
        mfaSetupRequired: state.mfaSetupRequired,
        secret: state.secret,
        otpauthUrl: state.otpauthUrl,
      ),
    );
  }

  @override
  State<MfaVerifyDialog> createState() => _MfaVerifyDialogState();
}

class _MfaVerifyDialogState extends State<MfaVerifyDialog> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _copied = false;
  bool _showManualKey = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _copySecret() {
    if (widget.secret != null && widget.secret!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.secret!));
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    setState(() => _isSubmitting = true);
    Navigator.of(context).pop();

    context.read<AuthBloc>().add(
      MfaSubmitted(
        mfaChallengeId: widget.mfaChallengeId,
        code: code,
        rememberMe: widget.rememberMe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSetup = widget.mfaSetupRequired && widget.secret != null && widget.secret!.isNotEmpty;

    final String qrData = (widget.otpauthUrl != null && widget.otpauthUrl!.isNotEmpty)
        ? widget.otpauthUrl!
        : 'otpauth://totp/PropKart:${Uri.encodeComponent(widget.email)}?secret=${widget.secret}&issuer=PropKart&algorithm=SHA1&digits=6&period=30';

    return Dialog(
      backgroundColor: CRMColors.cardBgOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
        side: BorderSide(color: CRMColors.borderOf(context), width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSetup ? 500 : 440,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CRMSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSetup ? Icons.qr_code_scanner_rounded : Icons.security_rounded,
                        color: CRMColors.primaryOf(context),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSetup ? 'Setup Two-Factor Authentication' : '2-Step Verification',
                            style: CRMTypography.sectionTitle.copyWith(
                              color: CRMColors.textOf(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.role.isNotEmpty
                                ? '${widget.role} Protected Account (TOTP)'
                                : 'Privileged Access',
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.primaryOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CRMSpacing.l),

                // Body description or Setup instructions
                if (isSetup) ...[
                  Text(
                    'Scan the QR code below using Google Authenticator, Microsoft Authenticator, or Apple Keychain to enroll your device.',
                    style: CRMTypography.body.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.l),

                  // QR Code Center Box
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CRMColors.borderOf(context), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 170,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Scan with Google Authenticator or Microsoft Authenticator',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Toggle for manual key
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _showManualKey = !_showManualKey),
                      icon: Icon(
                        _showManualKey ? Icons.keyboard_arrow_up_rounded : Icons.vpn_key_rounded,
                        size: 16,
                        color: CRMColors.primaryOf(context),
                      ),
                      label: Text(
                        _showManualKey ? 'Hide Manual Setup Key' : "Can't scan? Enter key manually",
                        style: TextStyle(
                          color: CRMColors.primaryOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Collapsible manual secret key box
                  if (_showManualKey) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(CRMSpacing.m),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CRMColors.borderOf(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manual Setup Key:',
                            style: CRMTypography.captionBold.copyWith(
                              color: CRMColors.textOf(context),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: CRMColors.primaryOf(context).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: SelectableText(
                                    widget.secret!,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _copySecret,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _copied ? CRMColors.success : CRMColors.primaryOf(context),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _copied ? 'Copied' : 'Copy',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: CRMSpacing.m),
                  Text(
                    'Enter the 6-digit confirmation code from your app below:',
                    style: CRMTypography.captionBold.copyWith(
                      color: CRMColors.textOf(context),
                      fontSize: 12,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Enter the 6-digit authentication code from Google Authenticator, Apple Keychain, or your TOTP app for ${widget.email}.',
                    style: CRMTypography.body.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],

                const SizedBox(height: CRMSpacing.m),

                // 6-digit PIN input with Pinput
                Center(
                  child: Pinput(
                    length: 6,
                    controller: _codeController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    hapticFeedbackType: HapticFeedbackType.lightImpact,
                    defaultPinTheme: PinTheme(
                      width: 50,
                      height: 56,
                      textStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CRMColors.textOf(context),
                        fontFamily: 'monospace',
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CRMColors.borderOf(context), width: 1.5),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 50,
                      height: 56,
                      textStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CRMColors.primaryOf(context),
                        fontFamily: 'monospace',
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CRMColors.primaryOf(context), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: CRMColors.primaryOf(context).withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    submittedPinTheme: PinTheme(
                      width: 50,
                      height: 56,
                      textStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CRMColors.textOf(context),
                        fontFamily: 'monospace',
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: CRMColors.primaryOf(context).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                    separatorBuilder: (index) => const SizedBox(width: 8),
                    onCompleted: (_) => _submit(),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: CRMSpacing.xl),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: CRMColors.textSecondaryOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    Expanded(
                      flex: 2,
                      child: CRMButton(
                        label: isSetup ? 'Verify & Activate 2FA' : 'Verify & Sign In',
                        prefixIcon: Icons.check_circle_outline_rounded,
                        isLoading: _isSubmitting,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
