import '../../core/services/notification_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/auth_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_manager.dart';
import '../../core/design_system/tokens/app_colors.dart';
import '../../core/design_system/tokens/app_shadows.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/design_system/tokens/app_typography.dart';
import '../../core/design_system/widgets/buttons.dart';
import '../../core/api/dio_client.dart';
import 'package:dio/dio.dart';
import '../../core/utils/seo_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SeoHelper.updateTags(
      title: 'Login | PropKart CRM',
      description: 'Log in to your PropKart account to access the property management dashboard, update listings, coordinate with clients, and review lead analytics.',
      canonicalUrl: 'https://propkart.nbpropertytech.com/login',
      imageUrl: 'https://propkart.nbpropertytech.com/assets/logo.png',
    );
  }

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          ),
          backgroundColor: CRMColors.surfaceElevatedOf(context),
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
              ),
            ],
          ),
          content: Text(
            message,
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: CRMColors.primaryOf(context),
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
                borderRadius: BorderRadius.circular(CRMBorderRadius.card),
              ),
              backgroundColor: CRMColors.surfaceElevatedOf(context),
              title: Text(
                'Forgot Password',
                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter your email address below. We will email you a confirmation and send the reset request to your administrator.',
                      style: CRMTypography.subheadline.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: 18),
                    PremiumTextField(
                      controller: emailController,
                      labelText: 'Email Address',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
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
                    foregroundColor: CRMColors.textSecondaryOf(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CRMColors.primaryOf(context),
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
                              
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: CRMColors.surfaceElevatedOf(context),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                                  ),
                                  title: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded, color: CRMColors.primaryOf(context), size: 28),
                                      const SizedBox(width: 10),
                                      Text('Email Sent', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
                                    ],
                                  ),
                                  content: Text(
                                    response.data['message'] ??
                                        'A password reset link has been sent to your email. Please check your inbox and spam folder.',
                                    style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Dismiss', style: TextStyle(color: CRMColors.primaryOf(context), fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              setState(() {
                                isSubmitting = false;
                              });
                              String errorMsg = 'Failed to submit request. Please try again.';
                              if (e is DioException) {
                                final resData = e.response?.data;
                                if (resData is Map && resData['message'] != null) {
                                  errorMsg = resData['message'].toString();
                                } else if (e.message != null && e.message!.isNotEmpty) {
                                  errorMsg = e.message!;
                                }
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: AppColors.error,
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

      TextInput.finishAutofillContext();

      context.read<AuthBloc>().add(
        LoginSubmitted(email: email, password: password, rememberMe: _rememberMe),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: CRMColors.backgroundOf(context),
          body: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                _showErrorDialog("Login Failed", state.message);
              }
            },
            child: Stack(
              children: [
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Increase breakpoint to 950 to fit 1000px container and prevent test overflows at 800px width
                      final isDesktop = constraints.maxWidth >= 950;

                      if (isDesktop) {
                        return Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(CRMSpacing.l),
                              child: SizedBox(
                                width: 1000,
                                height: 600,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: CRMColors.cardBgOf(context),
                                    borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                                    border: Border.all(color: CRMColors.borderOf(context), width: 1),
                                    boxShadow: CRMShadows.large,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: _buildFormContent(isDesktop: true),
                                      ),
                                      const Expanded(
                                        flex: 6,
                                        child: _HeroSection(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      // Mobile Layout
                      return Center(
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
                            child: _buildFormContent(isDesktop: false),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: Card(
                            color: CRMColors.surfaceElevatedOf(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Syncing Data...',
                                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please wait while we sync listings and profile',
                                    style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: 200,
                                    child: LinearProgressIndicator(
                                      color: CRMColors.primaryOf(context),
                                      backgroundColor: CRMColors.borderOf(context).withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormContent({required bool isDesktop}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brand Logo
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

            // Header Texts - Retain exact string "Go ahead to your account" for test assertion
            Text(
              'Go ahead to your account',
              style: CRMTypography.headline.copyWith(color: CRMColors.textOf(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your credentials to access your account.',
              style: CRMTypography.subheadline.copyWith(color: CRMColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 28),

            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email input
                  PremiumTextField(
                    controller: _emailController,
                    labelText: 'Email Address',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password input
                  PremiumTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: CRMColors.textSecondaryOf(context),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
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
            const SizedBox(height: 16),

            // Remember me and Forgot password
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 22,
                      width: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: CRMColors.primaryOf(context),
                        checkColor: Colors.white,
                        side: BorderSide(color: CRMColors.borderOf(context), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Text(
                        'Remember me',
                        style: CRMTypography.label.copyWith(
                          color: CRMColors.textSecondaryOf(context),
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
                      'Forgot Password?',
                      style: CRMTypography.label.copyWith(
                        color: CRMColors.primaryOf(context),
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sign In Button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return CRMButton(
                  label: 'Sign In',
                  isLoading: isLoading,
                  onPressed: _submit,
                  width: double.infinity,
                  height: 48,
                  borderRadius: CRMBorderRadius.input,
                  backgroundColor: CRMColors.primaryOf(context),
                  foregroundColor: Colors.white,
                );
              },
            ),
            const SizedBox(height: 16),

            // Browsewrap legal disclaimer
            Align(
              alignment: Alignment.center,
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'By signing in, you agree to our ',
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/terms-and-conditions'),
                    child: Text(
                      'Terms & Conditions',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.primaryOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    ' and ',
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/privacy-policy'),
                    child: Text(
                      'Privacy Policy',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.primaryOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '.',
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondaryOf(context),
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

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final theme = ThemeManager().currentTheme;
    final primaryColor = isDark ? theme.primaryDark : theme.primaryLight;
    final heroBg = isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B);
    final borderLeft = isDark ? const Color(0xFF334155) : const Color(0xFF334155);

    return Container(
      decoration: BoxDecoration(
        color: heroBg,
        border: Border(
          left: BorderSide(color: borderLeft, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'REAL ESTATE CRM',
              style: CRMTypography.captionBold.copyWith(
                color: isDark ? theme.primaryHoverDark : theme.primaryLight,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Architectural precision for modern real-estate operations.',
            style: CRMTypography.display.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF8FAFC),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Manage properties, buyer requirements, and team workflows in one calm, unified workspace.',
            style: CRMTypography.body.copyWith(
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}