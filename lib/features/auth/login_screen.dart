import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bloc/auth_bloc.dart';
import 'services/auth_service.dart';
import 'widgets/mfa_verify_dialog.dart';
import '../../core/api/dio_client.dart';
import '../../core/design_system/tokens/app_colors.dart';
import '../../core/services/notification_center.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/utils/seo_helper.dart';

/// Luxury PropKart Login Screen implementing Shubhangi's architectural design:
/// - Full-bleed villa background image (`landing_villa.webp` / `landing_villa.jpg`)
/// - Multi-stop dark scrim overlay (`rgba(5, 10, 8, ...)`)
/// - Architectural editorial hero copy (Inclusive Sans + Inter)
/// - Translucent frosted glass card with "Welcome back."
/// - Live dynamic backend CAPTCHA with distorted slight blur & refresh button
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _authService = AuthService();

  String? _captchaId;
  Uint8List? _captchaImageBytes;
  bool _isLoadingCaptcha = false;
  String? _captchaError;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _imagePrecached = false;

  @override
  void initState() {
    super.initState();
    SeoHelper.updateTags(
      title: 'Login | PropKart CRM',
      description:
          'Log in to your PropKart account to access the property management dashboard, update listings, coordinate with clients, and review lead analytics.',
      canonicalUrl: 'https://propkart.nbpropertytech.com/login',
      imageUrl: 'https://propkart.nbpropertytech.com/assets/images/landing_villa.jpg',
    );
    _fetchCaptcha();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagePrecached) {
      _imagePrecached = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        precacheImage(const AssetImage('assets/images/landing_villa.webp'), context).catchError((_) {});
        precacheImage(const AssetImage('assets/images/landing_logo.webp'), context).catchError((_) {});
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _fetchCaptcha({bool preserveError = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingCaptcha = true;
      if (!preserveError) {
        _captchaError = null;
      }
    });
    try {
      final res = await _authService.getCaptcha().timeout(const Duration(seconds: 10));
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final id = data['captchaId']?.toString();
      final imgUri = data['captchaImage']?.toString() ?? '';
      Uint8List? bytes;
      if (imgUri.contains(',')) {
        final b64 = imgUri.split(',').last;
        bytes = base64Decode(b64);
      }
      if (mounted) {
        setState(() {
          _captchaId = id;
          _captchaImageBytes = bytes;
          _isLoadingCaptcha = false;
          _captchaController.clear();
        });
      }
    } catch (e) {
      debugPrint('[LoginScreen] Captcha fetch failed: $e');
      if (mounted) {
        setState(() {
          _isLoadingCaptcha = false;
          _captchaError = 'Tap refresh to load';
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141614),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF737773),
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF141614),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              title: Text(
                'Forgot Password',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141614),
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter your email address below. We will email you a confirmation and send the reset request to your administrator.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF737773),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF141614)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFCFCFA),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        hintText: 'Email address',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF737773)),
                        prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF737773)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFDCDDD8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFDCDDD8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF141614), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: CRMColors.danger),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: CRMColors.danger, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,10}$').hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF737773),
                  ),
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF141614),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isSubmitting = true);
                            final email = emailController.text.trim();
                            try {
                              final response = await DioClient.dio.post(
                                '/auth/forgot-password',
                                data: {'email': email},
                              );
                              await NotificationCenter.addNotification(
                                title: 'Forgot Password Request',
                                message: 'Password reset requested for email: $email',
                                type: 'forgot_password',
                              );

                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded,
                                          color: Color(0xFF141614), size: 28),
                                      const SizedBox(width: 10),
                                      Text('Email Sent',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                              color: const Color(0xFF141614))),
                                    ],
                                  ),
                                  content: Text(
                                    response.data['message'] ??
                                        'A password reset link has been sent to your email. Please check your inbox and spam folder.',
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: const Color(0xFF737773)),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Dismiss',
                                          style: TextStyle(
                                              color: Color(0xFF141614),
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              setState(() => isSubmitting = false);
                              String errorMsg = 'Failed to submit request. Please try again.';
                              if (e is DioException) {
                                final resData = e.response?.data;
                                if (resData is Map && resData['message'] != null) {
                                  errorMsg = resData['message'].toString();
                                } else if (e.message != null && e.message!.isNotEmpty) {
                                  errorMsg = e.message!;
                                }
                              }
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: CRMColors.danger,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final captchaAnswer = _captchaController.text.trim();

      if (captchaAnswer.isEmpty) {
        setState(() => _captchaError = 'Please enter the verification code');
        return;
      }

      TextInput.finishAutofillContext();

      context.read<AuthBloc>().add(
            LoginSubmitted(
              email: email,
              password: password,
              rememberMe: _rememberMe,
              captchaId: _captchaId,
              captchaAnswer: captchaAnswer,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF141614),
          body: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                final msg = state.message.toLowerCase();
                if (msg.contains('verification code') || msg.contains('captcha')) {
                  setState(() => _captchaError = state.message);
                  _fetchCaptcha(preserveError: true);
                } else {
                  _showErrorDialog("Login Failed", state.message);
                  _fetchCaptcha();
                }
              } else if (state is MfaChallengeRequired) {
                MfaVerifyDialog.show(context, state);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Full-bleed villa background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/landing_villa.webp',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) => Image.asset(
                      'assets/images/landing_villa.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),

                // 2. Multi-stop dark gradient scrim
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.35, 0.55, 1.0],
                        colors: [
                          Color(0x1F050A08), // rgba(5, 10, 8, 0.12)
                          Color(0x1F050A08),
                          Color(0x2E050A08), // rgba(5, 10, 8, 0.18)
                          Color(0xA6050A08), // rgba(5, 10, 8, 0.65)
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Responsive Content Layer
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 950;
                      if (isDesktop) {
                        return _buildDesktopLayout(constraints);
                      }
                      return _buildMobileLayout(constraints);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Desktop Layout: Side-by-side hero editorial copy + floating frosted sign-in card
  Widget _buildDesktopLayout(BoxConstraints constraints) {
    final horizontalPadding = (constraints.maxWidth * 0.05).clamp(32.0, 78.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Brand Navigation Bar
          _buildBrandBar(),

          // Main Center Area: Left Editorial Copy, Right Frosted Card
          Expanded(
            child: Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Story Copy
                  Expanded(
                    flex: 11,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Eyebrow tag + Rule
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'YOUR NEXT CHAPTER STARTS HERE',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 1,
                                width: 32,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Editorial Headline in Inclusive Sans
                          Text(
                            'Your next home.\nOne step closer.',
                            style: GoogleFonts.inclusiveSans(
                              fontSize: constraints.maxWidth > 1200 ? 66 : 52,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 0.98,
                              shadows: const [
                                Shadow(
                                  offset: Offset(1, 5),
                                  blurRadius: 10,
                                  color: Color(0x80000000),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Description
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 580),
                            child: Text(
                              'Log in to revisit your favourites, explore premium properties, and make your next move with confidence.',
                              style: GoogleFonts.inter(
                                fontSize: constraints.maxWidth > 1200 ? 20 : 17,
                                color: Colors.white.withValues(alpha: 0.82),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Frosted Glass Sign-In Card
                  SizedBox(
                    width: 460,
                    child: SingleChildScrollView(
                      child: _buildSignInCard(isDesktop: true),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Member Benefits Row
          _buildMemberBenefitsRow(),
        ],
      ),
    );
  }

  /// Mobile & Tablet Layout: Single-column clean vertical stack
  Widget _buildMobileLayout(BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Brand Bar
          _buildBrandBar(),
          const SizedBox(height: 28),

          // Story copy
          Text(
            'Your next home.\nOne step closer.',
            style: GoogleFonts.inclusiveSans(
              fontSize: (constraints.maxWidth * 0.08).clamp(32.0, 44.0),
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.05,
              shadows: const [
                Shadow(
                  offset: Offset(1, 4),
                  blurRadius: 8,
                  color: Color(0x80000000),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Log in to revisit your favourites, explore premium properties, and make your next move with confidence.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Centered Sign-In Card
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _buildSignInCard(isDesktop: false),
            ),
          ),
          const SizedBox(height: 28),

          // Member Benefits
          Center(child: _buildMemberBenefitsRow()),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Top Brand Logo and Monogram
  Widget _buildBrandBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand Mark Logo matching Get Started screen
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/landing_logo.webp',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/landing_logo.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Colors.black,
                  child: Icon(Icons.apartment_rounded, color: Color(0xFFD9AD6E)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'PropKart',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
            height: 1.0,
            shadows: const [
              Shadow(
                color: Color.fromRGBO(0, 0, 0, 0.50),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Member Benefits Footer strip
  Widget _buildMemberBenefitsRow() {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildBenefitText('Saved properties'),
        _buildBenefitDot(),
        _buildBenefitText('Personalised matches'),
        _buildBenefitDot(),
        _buildBenefitText('Seamless enquiries'),
      ],
    );
  }

  Widget _buildBenefitText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _buildBenefitDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }

  /// Frosted White Sign-In Card matching Shubhangi's design specifications
  Widget _buildSignInCard({required bool isDesktop}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000), // rgba(0, 0, 0, 0.15)
            offset: Offset(0, 20),
            blurRadius: 60,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 24,
        vertical: isDesktop ? 32 : 26,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Title in Inclusive Sans
            Text(
              'Welcome back.',
              style: GoogleFonts.inclusiveSans(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141614),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle - Maintains exact test assertion string "Go ahead to your account"
            Text(
              'Go ahead to your account',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF737773),
              ),
            ),
            const SizedBox(height: 22),

            // Form Fields in AutofillGroup
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email Address
                  Text(
                    'Email Address',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF141614),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF141614)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFFCFCFA),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'Enter your email address',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF737773)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCDDD8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCDDD8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF141614), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: CRMColors.danger),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: CRMColors.danger, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,10}$').hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  Text(
                    'Password',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF141614),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF141614)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFFCFCFA),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'Enter your password',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF737773)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF737773),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCDDD8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCDDD8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF141614), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: CRMColors.danger),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: CRMColors.danger, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Preferences: Remember Me & Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: const Color(0xFF141614),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFDCDDD8), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Text(
                        'Remember me',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF737773),
                        ),
                      ),
                    ),
                  ],
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF141614),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Security Verification / CAPTCHA Section matching Shubhangi's design
            Text(
              'Security verification',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141614),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Enter the code shown on the right',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF777E78),
              ),
            ),
            const SizedBox(height: 8),

            // CAPTCHA Row: Input on Left, Live Distorted Image on Right, Refresh Button
            Row(
              children: [
                // 1. CAPTCHA Input Field
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 48,
                    child: TextFormField(
                      controller: _captchaController,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.0,
                        fontSize: 15,
                        color: Color(0xFF141614),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFCFCFA),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        hintText: 'Enter CAPTCHA',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFA3A9A4),
                          letterSpacing: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _captchaError != null ? CRMColors.danger : const Color(0xFFDCDDD8),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _captchaError != null ? CRMColors.danger : const Color(0xFFDCDDD8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _captchaError != null ? CRMColors.danger : const Color(0xFF141614),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        if (_captchaError != null) {
                          setState(() => _captchaError = null);
                        }
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Distorted Live PNG CAPTCHA Image Container (Slight blur / antialiased security rendering)
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF1F5), // Light square vector fill
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD9DDD8), width: 1.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _isLoadingCaptcha
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF141614),
                              ),
                            ),
                          )
                        : _captchaImageBytes != null
                            ? Image.memory(
                                _captchaImageBytes!,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.medium, // Produces the slight blur / antialiased look
                              )
                            : Center(
                                child: Text(
                                  _captchaError ?? 'Click refresh',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF737773),
                                  ),
                                ),
                              ),
                  ),
                ),
                const SizedBox(width: 6),

                // 3. Refresh Action Button
                Tooltip(
                  message: 'Refresh verification code',
                  child: InkWell(
                    onTap: _isLoadingCaptcha ? null : _fetchCaptcha,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 48,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7F6), // Square vector fill
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD9DDD8), width: 1.0),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: Color(0xFF141614),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_captchaError != null) ...[
              const SizedBox(height: 5),
              Text(
                _captchaError!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: CRMColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 22),

            // Log In Button with Arrow Icon
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF141614),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Log In',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            // Legal notice
            Align(
              alignment: Alignment.center,
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'By continuing, you agree to our ',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF737773),
                      height: 1.6,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/terms-and-conditions'),
                    child: Text(
                      'Terms of Service',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF141614),
                        decoration: TextDecoration.underline,
                        height: 1.6,
                      ),
                    ),
                  ),
                  Text(
                    ' and ',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF737773),
                      height: 1.6,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/privacy-policy'),
                    child: Text(
                      'Privacy Policy',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF141614),
                        decoration: TextDecoration.underline,
                        height: 1.6,
                      ),
                    ),
                  ),
                  Text(
                    '.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF737773),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
