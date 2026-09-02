import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart' as auth_model;
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/design_system/widgets/inputs.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../../core/api/dio_client.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/utils/budget_formatter.dart';
import '../../../core/security/role_guard.dart';
import '../../properties/repository/properties_repository.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../../properties/models/property_model.dart';
import '../../requirements/models/requirement_model.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRoleId;
  String _selectedStatus = "All";

  List<dynamic> _passwordResets = [];
  bool _isLoadingResets = false;
  int _activeTabIndex = 0;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _triggerFetch();
    _fetchPasswordResets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPasswordResets() async {
    final authState = context.read<AuthBloc>().state;
    // Only fetch if authenticated and caller is Admin or Super Admin
    if (authState is Authenticated) {
      final roleName = authState.user.role;
      if (roleName != 'Admin' && roleName != 'Super Admin') {
        return;
      }
    } else {
      return;
    }

    setState(() {
      _isLoadingResets = true;
    });
    try {
      final response = await DioClient.dio.get('/users/password-resets');
      final data = response.data['data']['resets'] as List? ?? [];
      setState(() {
        _passwordResets = data;
        _isLoadingResets = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingResets = false;
      });
    }
  }

  void _triggerFetch() {
    context.read<UsersBloc>().add(
      FetchUsers(
        search: _searchController.text.trim(),
        roleId: _selectedRoleId,
        status: _selectedStatus,
      ),
    );
  }

  void _showAddEditUserDialog([UserModel? user]) {
    final isEditing = user != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: user?.fullName);
    final emailController = TextEditingController(text: user?.email);
    final mobileController = TextEditingController(text: user?.mobile);
    final passwordController = TextEditingController();

    String? localSelectedRoleId = user?.roleId;
    bool obscurePassword = true;
    String? uploadedPhotoUrl = user?.profilePhoto;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final authState = context.read<AuthBloc>().state;
        final callerRole = authState is Authenticated
            ? authState.user.role
            : '';

        final usersState = context.read<UsersBloc>().state;
        List<RoleModel> roles = [];
        if (usersState is UsersLoaded) {
          if (callerRole == 'Admin' || callerRole == 'Telecaller') {
            final salesRole = usersState.roles.firstWhere(
              (r) => r.name.toLowerCase() == 'sales',
              orElse: () => const RoleModel(id: '', name: 'Sales', description: ''),
            );
            final adminRole = usersState.roles.firstWhere(
              (r) => r.name.toLowerCase() == 'admin',
              orElse: () => const RoleModel(id: '', name: 'Admin', description: ''),
            );
            roles = [
              if (salesRole.id.isNotEmpty) salesRole,
              if (adminRole.id.isNotEmpty)
                RoleModel(
                  id: adminRole.id,
                  name: 'Telecaller',
                  description: 'Telecaller with Admin privileges',
                ),
            ];
          } else if (callerRole == 'Super Admin') {
            roles = usersState.roles
                .where((r) => r.name.toLowerCase() != 'super admin')
                .toList();
          }
        }

        if (localSelectedRoleId == null && roles.isNotEmpty) {
          localSelectedRoleId = roles.any((r) => r.id == user?.roleId)
              ? user?.roleId
              : roles.first.id;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final double screenWidth = MediaQuery.of(context).size.width;
            final bool isMobile = screenWidth < 600;

            return Dialog(
              backgroundColor: CRMColors.surfaceElevatedOf(context),
              elevation: 8,
              shadowColor: CRMColors.shadow,
              insetPadding: isMobile
                  ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0)
                  : const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 24.0,
                    ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  isMobile ? CRMBorderRadius.m : CRMBorderRadius.dialog,
                ),
                side: BorderSide(
                  color: CRMColors.borderOf(context).withOpacity(0.5),
                  width: 0.5,
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 500,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? "Edit User Account"
                                : "Add User Account",
                            style: CRMTypography.sectionTitle.copyWith(
                              color: CRMColors.text,
                            ),
                          ),
                          const SizedBox(height: CRMSpacing.xs),
                          Text(
                            isEditing
                                ? "Modify the system credentials and role permissions."
                                : "Create new employee logins for the NB Realty system.",
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: CRMSpacing.l),

                          // Profile Photo Picker Avatar
                          Align(
                            alignment: Alignment.center,
                            child: Stack(
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: CRMColors.backgroundOf(context),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: CRMColors.borderOf(
                                        context,
                                      ).withOpacity(0.6),
                                      width: 2,
                                    ),
                                    boxShadow: CRMShadows.soft,
                                  ),
                                  child: ClipOval(
                                    child: _isUploadingPhoto
                                        ? Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: CRMColors.primary,
                                              ),
                                            ),
                                          )
                                        : (uploadedPhotoUrl != null &&
                                              uploadedPhotoUrl!.isNotEmpty)
                                        ? Image.network(
                                            uploadedPhotoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      Icons.person_rounded,
                                                      size: 48,
                                                      color:
                                                          CRMColors.textMuted,
                                                    ),
                                          )
                                        : Icon(
                                            Icons.person_rounded,
                                            size: 48,
                                            color: CRMColors.textMuted,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _isUploadingPhoto
                                          ? null
                                          : () => _pickAndUploadPhoto(
                                              setState,
                                              (url) {
                                                setState(() {
                                                  uploadedPhotoUrl = url;
                                                });
                                              },
                                            ),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: CRMColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Full Name Input
                          CRMTextField(
                            controller: nameController,
                            labelText: 'Full Name *',
                            hintText: 'Enter complete name',
                            prefixIcon: Icons.person_rounded,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? "Full name required"
                                : null,
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Email Input
                          CRMTextField(
                            controller: emailController,
                            labelText: 'Email Address *',
                            hintText: 'user@nbrealty.com',
                            prefixIcon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? "Email required"
                                : null,
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Mobile Phone
                          CRMTextField(
                            controller: mobileController,
                            labelText: 'Phone Number',
                            hintText: 'e.g. 9876543210',
                            prefixIcon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              final digits = (val ?? '').replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              if (digits.isEmpty)
                                return 'Phone number required';
                              if (digits.length != 10)
                                return 'Enter a valid 10-digit mobile';
                              return null;
                            },
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Password Input with Show/Hide Eye Toggle
                          CRMTextField(
                            controller: passwordController,
                            labelText: isEditing
                                ? "New Password (Optional)"
                                : "Password *",
                            hintText: 'Min 8 characters',
                            prefixIcon: Icons.lock_rounded,
                            obscureText: obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: CRMColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            validator: (val) {
                              if (!isEditing && (val == null || val.isEmpty)) {
                                return "Password required";
                              }
                              if (val != null &&
                                  val.isNotEmpty &&
                                  val.length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Role Selector
                          if (roles.isEmpty) ...[
                            Text(
                              'System Role *',
                              style: CRMTypography.bodyMedium.copyWith(
                                color: CRMColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: CRMSpacing.xs),
                            Container(
                              padding: const EdgeInsets.all(CRMSpacing.m),
                              decoration: BoxDecoration(
                                color: CRMColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  CRMBorderRadius.input,
                                ),
                                border: Border.all(
                                  color: CRMColors.danger.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: CRMColors.danger,
                                  ),
                                  const SizedBox(width: CRMSpacing.s),
                                  Expanded(
                                    child: Text(
                                      'No roles loaded. Please close and reopen this page.',
                                      style: CRMTypography.body.copyWith(
                                        color: CRMColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: CRMSpacing.xl),
                          ] else ...[
                            Text(
                              'System Role *',
                              style: CRMTypography.bodyMedium.copyWith(
                                color: CRMColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: CRMSpacing.xs),
                            DropdownButtonFormField<String>(
                              value: localSelectedRoleId,
                              dropdownColor: CRMColors.cardBgOf(context),
                              style: CRMTypography.body.copyWith(
                                color: CRMColors.textOf(context),
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: CRMColors.textMutedOf(context),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: CRMSpacing.m,
                                  vertical: CRMSpacing.s,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CRMBorderRadius.input,
                                  ),
                                  borderSide: BorderSide(
                                    color: CRMColors.borderOf(
                                      context,
                                    ).withValues(alpha: 0.6),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CRMBorderRadius.input,
                                  ),
                                  borderSide: BorderSide(
                                    color: CRMColors.borderOf(
                                      context,
                                    ).withValues(alpha: 0.6),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CRMBorderRadius.input,
                                  ),
                                  borderSide: BorderSide(
                                    color: CRMColors.primaryOf(context),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              items: roles.map((r) {
                                return DropdownMenuItem<String>(
                                  value: r.id,
                                  child: Text(r.name),
                                );
                              }).toList(),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'System role is required';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                setState(() {
                                  localSelectedRoleId = val;
                                });
                              },
                            ),
                            const SizedBox(height: CRMSpacing.xl),
                          ],

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CRMButton(
                                label: 'Cancel',
                                variant: CRMButtonVariant.outline,
                                onPressed: () => Navigator.pop(dialogContext),
                              ),
                              const SizedBox(width: CRMSpacing.s),
                              CRMButton(
                                label: isEditing
                                    ? 'Save Changes'
                                    : 'Create Account',
                                onPressed: roles.isEmpty
                                    ? null
                                    : () {
                                        if (formKey.currentState?.validate() ??
                                            false) {
                                          final String inputMobile =
                                              mobileController.text.trim();
                                          final String cleanInputMobile =
                                              inputMobile.replaceAll(
                                                RegExp(r'\D'),
                                                '',
                                              );

                                          if (!isEditing) {
                                            final usersState = context
                                                .read<UsersBloc>()
                                                .state;
                                            if (usersState is UsersLoaded) {
                                              final exists = usersState.users
                                                  .any((u) {
                                                    final cleanUserMobile =
                                                        (u.mobile ?? '')
                                                            .replaceAll(
                                                              RegExp(r'\D'),
                                                              '',
                                                            );
                                                    return cleanUserMobile ==
                                                        cleanInputMobile;
                                                  });
                                              if (exists) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'A sales user with this mobile number already exists.',
                                                    ),
                                                    backgroundColor:
                                                        CRMColors.danger,
                                                  ),
                                                );
                                                return;
                                              }

                                              final emailExists = usersState.users
                                                  .any((u) => u.email.trim().toLowerCase() == emailController.text.trim().toLowerCase());
                                              if (emailExists) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'A sales user with this email address already exists.',
                                                    ),
                                                    backgroundColor:
                                                        CRMColors.danger,
                                                  ),
                                                );
                                                return;
                                              }
                                            }
                                          }

                                          final userData = {
                                            'full_name': nameController.text
                                                .trim(),
                                            'email': emailController.text
                                                .trim(),
                                            'mobile': inputMobile,
                                            'role_id': localSelectedRoleId,
                                            'profile_photo': uploadedPhotoUrl,
                                          };

                                          if (passwordController
                                              .text
                                              .isNotEmpty) {
                                            userData['password'] =
                                                passwordController.text;
                                          }

                                          if (isEditing) {
                                            context.read<UsersBloc>().add(
                                              UpdateUserRequested(
                                                id: user.id,
                                                userData: userData,
                                              ),
                                            );
                                          } else {
                                            context.read<UsersBloc>().add(
                                              CreateUserRequested(
                                                userData: userData,
                                              ),
                                            );
                                          }

                                          Navigator.pop(dialogContext);
                                        }
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(UserModel user) async {
    final confirmed = await CRMDialogs.showDeleteConfirmation(
      context,
      title: "Confirm Deletion",
      content:
          "Are you sure you want to delete ${user.fullName}? This user will be permanently removed from the system.",
    );
    if (confirmed == true && mounted) {
      context.read<UsersBloc>().add(DeleteUserRequested(id: user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthInitial || authState is AuthLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    bool hasAccess = false;
    if (authState is Authenticated) {
      hasAccess = authState.user.permissions.contains("users.read") ||
          authState.user.role.toLowerCase() == 'admin' ||
          authState.user.role.toLowerCase() == 'super admin' ||
          authState.user.role.toLowerCase() == 'telecaller' ||
          authState.user.role.toLowerCase() == 'sales';
    }

    if (!hasAccess) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.gpp_bad_rounded,
                  color: CRMColors.danger,
                  size: 72,
                ),
                const SizedBox(height: CRMSpacing.m),
                Text(
                  "403 - Forbidden",
                  style: CRMTypography.pageTitle.copyWith(
                    color: CRMColors.text,
                  ),
                ),
                const SizedBox(height: CRMSpacing.xs),
                Text(
                  "You do not have permission to view this page.",
                  style: CRMTypography.body.copyWith(
                    color: CRMColors.textSecondary,
                  ),
                ),
                const SizedBox(height: CRMSpacing.xl),
                CRMButton(
                  label: "Back to Dashboard",
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state is UsersOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: CRMColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _triggerFetch();
          } else if (state is UsersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${state.message}"),
                backgroundColor: CRMColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Row
              _buildPageHeader(),
              const SizedBox(height: CRMSpacing.l),

              // 2. Statistics Overview Cards
              _buildStatisticsRow(),
              const SizedBox(height: CRMSpacing.l),

              // TabBar for Admin & Super Admin
              if (authState is Authenticated &&
                  (authState.user.role == 'Super Admin' || authState.user.role == 'Admin')) ...[
                _buildTabBar(),
                const SizedBox(height: CRMSpacing.m),
              ],

              // Content based on active tab
              if (_activeTabIndex == 1)
                _buildPasswordResetsTabContent()
              else ...[
                _buildSearchAndFiltersCard(),
                const SizedBox(height: CRMSpacing.l),
                _buildEmployeesTable(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return CRMPageHeader(
      title: "Employees",
      trailing: CRMButton(
        label: "Add Employee",
        prefixIcon: Icons.add_rounded,
        height: 40,
        onPressed: () => _showAddEditUserDialog(),
      ),
    );
  }

  Widget _buildStatisticsRow() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        int total = 0;
        int active = 0;
        int admins = 0;

        if (state is UsersLoaded) {
          final authState = context.read<AuthBloc>().state;
          String? currentUserId;
          if (authState is Authenticated) {
            currentUserId = authState.user.id;
          }

          final list = state.users.where((u) => u.id != currentUserId).toList();

          total = list.length;
          active = list.where((u) => u.isActive).length;
          admins = list
              .where((u) => u.roleName.toLowerCase() == 'admin')
              .length;
        }

        return CRMResponsiveKpiRow(
          children: [
            CRMKPICard(
              title: "TOTAL EMPLOYEES",
              value: total.toString(),
              icon: Icons.people_rounded,
              iconColor: CRMColors.terracotta,
              backgroundColor: CRMColors.kpiPlum,
            ),
            CRMKPICard(
              title: "ACTIVE SYSTEM USERS",
              value: active.toString(),
              icon: Icons.check_circle_outline_rounded,
              iconColor: CRMColors.text,
              backgroundColor: CRMColors.kpiSage,
            ),
            CRMKPICard(
              title: "ADMINISTRATORS",
              value: admins.toString(),
              icon: Icons.admin_panel_settings_rounded,
              iconColor: CRMColors.terracotta,
              backgroundColor: CRMColors.kpiRose,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFiltersCard() {
    return CRMCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(
                    color: CRMColors.textOf(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by employee name, email, phone number...',
                    hintStyle: CRMTypography.body.copyWith(
                      color: CRMColors.textMutedOf(context),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: CRMColors.textMutedOf(context),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: CRMColors.textMutedOf(context),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _triggerFetch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: CRMColors.backgroundOf(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: CRMSpacing.m,
                      vertical: CRMSpacing.s,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        CRMBorderRadius.input,
                      ),
                      borderSide: BorderSide(
                        color: CRMColors.borderOf(context).withOpacity(0.6),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        CRMBorderRadius.input,
                      ),
                      borderSide: BorderSide(
                        color: CRMColors.borderOf(context).withOpacity(0.6),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        CRMBorderRadius.input,
                      ),
                      borderSide: BorderSide(
                        color: CRMColors.primaryOf(context),
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (val) => _triggerFetch(),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(label: "Search", onPressed: _triggerFetch),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),

          // Role & Status Dropdown Row
          BlocBuilder<UsersBloc, UsersState>(
            builder: (context, state) {
              List<RoleModel> roles = [];
              if (state is UsersLoaded) {
                roles = state.roles;
              }

              final authState = context.watch<AuthBloc>().state;
              String? userRole;
              if (authState is Authenticated) {
                userRole = authState.user.role;
              }
              final bool isSuperAdmin = userRole == 'Super Admin';

              return Wrap(
                spacing: CRMSpacing.m,
                runSpacing: CRMSpacing.s,
                children: [
                  // Role Filter
                  if (isSuperAdmin)
                    _buildDropdown(
                      label: 'Filter by Role',
                      value: _selectedRoleId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text("All Roles"),
                        ),
                        ...roles.map(
                          (r) => DropdownMenuItem<String?>(
                            value: r.id,
                            child: Text(r.name),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedRoleId = val;
                        });
                        _triggerFetch();
                      },
                    ),

                  // Status Filter
                  _buildDropdown(
                    label: 'Filter by Status',
                    value: _selectedStatus,
                    items: ["All", "Active", "Inactive"].map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val ?? "All";
                      });
                      _triggerFetch();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 200,
      height: 44,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        dropdownColor: CRMColors.cardBgOf(context),
        style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: CRMTypography.caption.copyWith(
            color: CRMColors.textSecondaryOf(context),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CRMSpacing.m,
            vertical: 4,
          ),
          filled: true,
          fillColor: CRMColors.backgroundOf(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.input),
            borderSide: BorderSide(
              color: CRMColors.borderOf(context).withOpacity(0.6),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.input),
            borderSide: BorderSide(
              color: CRMColors.borderOf(context).withOpacity(0.6),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.input),
            borderSide: BorderSide(
              color: CRMColors.primaryOf(context),
              width: 1.5,
            ),
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEmployeesTable() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        final isLoading = state is UsersLoading || state is UsersInitial;
        List<UserModel> users = [];
        final authState = context.read<AuthBloc>().state;
        auth_model.UserModel? currentUser;
        if (authState is Authenticated) {
          currentUser = authState.user;
        }
        final isCurrentUserAdmin =
            currentUser != null &&
            (currentUser.role == 'Admin' ||
                currentUser.role == 'Super Admin' ||
                RoleGuard.isAdmin(currentUser.role));

        if (state is UsersLoaded) {
          users = state.users;
          final isSuperAdmin =
              currentUser != null && currentUser.role == 'Super Admin';
          if (isSuperAdmin) {
            if (_activeTabIndex == 2) {
              users = users
                  .where((u) => u.roleName.toLowerCase() == 'admin')
                  .toList();
            } else {
              users = users
                  .where((u) => u.roleName.toLowerCase() == 'sales' || u.roleName.toLowerCase() == 'telecaller')
                  .toList();
            }
          } else if (currentUser != null && (currentUser.role == 'Admin' || currentUser.role == 'Telecaller')) {
            // Admins and Telecallers can see and manage Sales and Telecaller users
            users = users
                .where(
                  (u) => u.roleName.toLowerCase() == 'sales' || u.roleName.toLowerCase() == 'telecaller',
                )
                .toList();
          }
        }

        if (isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (users.isEmpty) {
          final isInactiveFilter = _selectedStatus.toLowerCase() == 'inactive';
          return Center(
            child: CRMCard(
              elevated: true,
              child: Padding(
                padding: const EdgeInsets.all(CRMSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isInactiveFilter
                          ? 'No Inactive Employees Found'
                          : 'No Employees Found',
                      style: CRMTypography.sectionTitle.copyWith(
                        color: CRMColors.textOf(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    Text(
                      'Try adjusting your filters or add a new employee profile.',
                      style: CRMTypography.body.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (isMobile) {
          return Column(
            children: users.map((user) => _buildMobileUserCard(user)).toList(),
          );
        }

        return _buildFullWidthEmployeesTable(
          users: users,
          isCurrentUserAdmin: isCurrentUserAdmin,
        );
      },
    );
  }

  Widget _buildFullWidthEmployeesTable({
    required List<UserModel> users,
    required bool isCurrentUserAdmin,
  }) {
    Widget headerCell(String label, {TextAlign align = TextAlign.left}) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CRMSpacing.s,
          vertical: CRMSpacing.s,
        ),
        child: Text(
          label,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CRMTypography.captionBold.copyWith(
            color: CRMColors.textSecondaryOf(context),
          ),
        ),
      );
    }

    Widget bodyCell(Widget child) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CRMSpacing.s,
          vertical: CRMSpacing.xs,
        ),
        child: child,
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: CRMColors.borderOf(context).withOpacity(0.55),
          width: 0.5,
        ),
        boxShadow: CRMShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.4),
          1: FlexColumnWidth(1.1),
          2: FlexColumnWidth(2.4),
          3: FlexColumnWidth(1.4),
          4: FlexColumnWidth(1.3),
          5: FlexColumnWidth(1.1),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: CRMColors.sidebarBgOf(context),
            ),
            children: [
              headerCell('Full Name'),
              headerCell('Role'),
              headerCell('Email Address'),
              headerCell('Mobile'),
              headerCell('Active Logins'),
              headerCell('Actions'),
            ],
          ),
          ...users.map((user) {
            final isAdmin = user.roleName.toLowerCase() == 'admin' ||
                user.roleName.toLowerCase() == 'telecaller';
            final isClickable = isCurrentUserAdmin &&
                (user.roleName.toLowerCase() == 'sales' ||
                    user.roleName.toLowerCase() == 'telecaller');

            return TableRow(
              decoration: BoxDecoration(
                color: CRMColors.cardBgOf(context),
                border: Border(
                  top: BorderSide(
                    color: CRMColors.borderOf(context).withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
              ),
              children: [
                bodyCell(
                  InkWell(
                    onTap: isClickable ? () => _showSalesmanDetails(user) : null,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isAdmin
                              ? CRMColors.info.withOpacity(0.1)
                              : CRMColors.primary.withOpacity(0.1),
                          radius: 16,
                          backgroundImage: (user.profilePhoto != null &&
                                  user.profilePhoto!.isNotEmpty)
                              ? NetworkImage(user.profilePhoto!)
                              : null,
                          child: (user.profilePhoto != null &&
                                  user.profilePhoto!.isNotEmpty)
                              ? null
                              : Icon(
                                  isAdmin
                                      ? Icons.admin_panel_settings_rounded
                                      : Icons.person_rounded,
                                  color: isAdmin
                                      ? CRMColors.info
                                      : CRMColors.primary,
                                  size: 16,
                                ),
                        ),
                        const SizedBox(width: CRMSpacing.s),
                        Expanded(
                          child: Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CRMTypography.bodyMedium.copyWith(
                              color: CRMColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bodyCell(
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CRMSpacing.s,
                        vertical: CRMSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? CRMColors.info.withOpacity(0.12)
                            : CRMColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(
                          CRMBorderRadius.round,
                        ),
                      ),
                      child: Text(
                        user.roleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CRMTypography.captionBold.copyWith(
                          color: isAdmin ? CRMColors.info : CRMColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                bodyCell(
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CRMTypography.body.copyWith(
                      color: CRMColors.textSecondary,
                    ),
                  ),
                ),
                bodyCell(
                  Text(
                    user.mobile ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CRMTypography.body.copyWith(
                      color: CRMColors.textSecondary,
                    ),
                  ),
                ),
                bodyCell(
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Switch(
                      value: user.isActive,
                      activeColor: CRMColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) {
                        context.read<UsersBloc>().add(
                          ToggleUserStatusRequested(id: user.id, isActive: val),
                        );
                      },
                    ),
                  ),
                ),
                bodyCell(
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAdmin)
                            IconButton(
                              icon: const Icon(
                                Icons.analytics_outlined,
                                color: CRMColors.warning,
                                size: 18,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => _showAdminStatsDialog(user),
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: CRMColors.primary,
                              size: 18,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () => _showAddEditUserDialog(user),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: CRMColors.danger,
                              size: 18,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () => _showDeleteConfirmDialog(user),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileUserCard(UserModel user) {
    final isAdmin = user.roleName.toLowerCase() == 'admin';
    final authState = context.read<AuthBloc>().state;
    auth_model.UserModel? currentUser;
    if (authState is Authenticated) {
      currentUser = authState.user;
    }
    final isCurrentUserAdmin =
        currentUser != null &&
        (currentUser.role == 'Admin' ||
            currentUser.role == 'Super Admin' ||
            RoleGuard.isAdmin(currentUser.role));
    final bool isClickable =
        isCurrentUserAdmin && (user.roleName.toLowerCase() == 'sales' || user.roleName.toLowerCase() == 'telecaller');

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: CRMColors.borderOf(context).withOpacity(0.55),
          width: 0.5,
        ),
        boxShadow: CRMShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isAdmin
                    ? CRMColors.info.withOpacity(0.1)
                    : CRMColors.primary.withOpacity(0.1),
                radius: 18,
                backgroundImage: (user.profilePhoto != null && user.profilePhoto!.isNotEmpty)
                    ? NetworkImage(user.profilePhoto!)
                    : null,
                child: (user.profilePhoto != null && user.profilePhoto!.isNotEmpty)
                    ? null
                    : Icon(
                        isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.person_rounded,
                        color: isAdmin ? CRMColors.info : CRMColors.primary,
                        size: 18,
                      ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.textOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CRMSpacing.s,
                  vertical: CRMSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? CRMColors.info.withOpacity(0.12)
                      : CRMColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                ),
                child: Text(
                  user.roleName,
                  style: CRMTypography.captionBold.copyWith(
                    color: isAdmin ? CRMColors.info : CRMColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Divider(
            color: CRMColors.borderOf(context).withOpacity(0.5),
            height: 1,
          ),
          const SizedBox(height: CRMSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.phone_rounded,
                    size: 16,
                    color: CRMColors.textMutedOf(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.mobile ?? '-',
                    style: CRMTypography.body.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Active Login',
                    style: CRMTypography.body.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.xs),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: user.isActive,
                      activeColor: CRMColors.primary,
                      onChanged: (val) {
                        context.read<UsersBloc>().add(
                          ToggleUserStatusRequested(id: user.id, isActive: val),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          Divider(
            color: CRMColors.borderOf(context).withOpacity(0.5),
            height: 1,
          ),
          const SizedBox(height: CRMSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isAdmin) ...[
                TextButton.icon(
                  onPressed: () => _showAdminStatsDialog(user),
                  icon: const Icon(
                    Icons.analytics_outlined,
                    color: CRMColors.warning,
                    size: 16,
                  ),
                  label: const Text(
                    'Stats',
                    style: TextStyle(color: CRMColors.warning),
                  ),
                ),
                const SizedBox(width: CRMSpacing.s),
              ],
              TextButton.icon(
                onPressed: () => _showAddEditUserDialog(user),
                icon: Icon(
                  Icons.edit_outlined,
                  color: CRMColors.primary,
                  size: 16,
                ),
                label: Text('Edit', style: TextStyle(color: CRMColors.primary)),
              ),
              const SizedBox(width: CRMSpacing.s),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmDialog(user),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: CRMColors.danger,
                  size: 16,
                ),
                label: Text(
                  'Delete',
                  style: TextStyle(color: CRMColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return isClickable
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
              onTap: () => _showSalesmanDetails(user),
              child: cardContent,
            ),
          )
        : cardContent;
  }

  Widget _buildPasswordResetsSection() {
    if (_passwordResets.isEmpty) return const SizedBox.shrink();

    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.vpn_key_rounded,
                color: CRMColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Pending Password Reset Requests (${_passwordResets.length})",
                style: CRMTypography.sectionTitle.copyWith(
                  color: CRMColors.text,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _passwordResets.length,
            separatorBuilder: (context, index) =>
                Divider(color: CRMColors.border.withOpacity(0.5)),
            itemBuilder: (context, index) {
              final r = _passwordResets[index];
              final userName = r['userName'] ?? '';
              final userEmail = r['userEmail'] ?? '';
              final roleName = r['roleName'] ?? '';
              final createdAtStr = r['createdAt'] ?? '';

              String timeDisplay = 'recently';
              try {
                final dt = DateTime.parse(createdAtStr);
                final diff = DateTime.now().difference(dt);
                if (diff.inMinutes < 60) {
                  timeDisplay = '${diff.inMinutes}m ago';
                } else if (diff.inHours < 24) {
                  timeDisplay = '${diff.inHours}h ago';
                } else {
                  timeDisplay = '${diff.inDays}d ago';
                }
              } catch (_) {}

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: CRMTypography.bodyMedium.copyWith(
                                  color: CRMColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: CRMColors.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  roleName,
                                  style: CRMTypography.caption.copyWith(
                                    color: CRMColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$userEmail • Requested $timeDisplay",
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CRMButton(
                      label: "Reset Password",
                      variant: CRMButtonVariant.primary,
                      onPressed: () => _showResetPasswordDialog(r),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(dynamic request) {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: CRMColors.surfaceElevatedOf(context),
              elevation: 8,
              shadowColor: CRMColors.shadow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
                side: BorderSide(
                  color: CRMColors.borderOf(context).withOpacity(0.5),
                  width: 0.5,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reset Password for ${request['userName']}",
                          style: CRMTypography.sectionTitle.copyWith(
                            color: CRMColors.text,
                          ),
                        ),
                        const SizedBox(height: CRMSpacing.xs),
                        Text(
                          "Enter a new password for ${request['userEmail']} (${request['roleName']}).",
                          style: CRMTypography.caption.copyWith(
                            color: CRMColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: CRMSpacing.l),

                        CRMTextField(
                          controller: passwordController,
                          labelText: 'New Password *',
                          hintText: 'Min 6 characters',
                          prefixIcon: Icons.lock_rounded,
                          obscureText: obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: CRMColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Password required";
                            }
                            if (val.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: CRMSpacing.xl),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CRMButton(
                              label: 'Cancel',
                              variant: CRMButtonVariant.outline,
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                            ),
                            const SizedBox(width: CRMSpacing.s),
                            CRMButton(
                              label: 'Save Password',
                              variant: CRMButtonVariant.primary,
                              isLoading: isSaving,
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (formKey.currentState?.validate() ??
                                          false) {
                                        setState(() {
                                          isSaving = true;
                                        });
                                        try {
                                          final newPassword =
                                              passwordController.text;
                                          await DioClient.dio.post(
                                            '/users/password-resets/${request['id']}/resolve',
                                            data: {
                                              'newPassword': newPassword,
                                              'userId': request['userId'],
                                              'email': request['userEmail'],
                                            },
                                          );

                                          Navigator.pop(dialogContext);

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Password updated successfully.",
                                              ),
                                              backgroundColor:
                                                  CRMColors.success,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );

                                          _fetchPasswordResets();
                                          _triggerFetch();
                                        } catch (e) {
                                          setState(() {
                                            isSaving = false;
                                          });
                                          String errorMsg =
                                              'Failed to reset password. Please try again.';
                                          if (e is DioException) {
                                            errorMsg =
                                                e.response?.data['message'] ??
                                                e.message ??
                                                errorMsg;
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $errorMsg"),
                                              backgroundColor: CRMColors.danger,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabBar() {
    final authState = context.read<AuthBloc>().state;
    final isSuperAdmin = authState is Authenticated && authState.user.role == 'Super Admin';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.m),
          border: Border.all(
            color: CRMColors.borderOf(context).withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: CRMShadows.soft,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabItem(0, "Employees", Icons.people_rounded),
              const SizedBox(width: 4),
              _buildTabItem(
                1,
                _passwordResets.isNotEmpty
                    ? "Password Requests (${_passwordResets.length})"
                    : "Password Requests",
                Icons.vpn_key_rounded,
                badgeCount: _passwordResets.length,
              ),
              if (isSuperAdmin) ...[
                const SizedBox(width: 4),
                _buildTabItem(2, "Administrators", Icons.admin_panel_settings_rounded),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon, {int badgeCount = 0}) {
    final isSelected = _activeTabIndex == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: CRMMotion.fast,
          curve: CRMMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? CRMColors.primaryOf(context).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? CRMColors.primaryOf(context)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? CRMColors.primaryOf(context)
                    : CRMColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: CRMTypography.bodyMedium.copyWith(
                  color: isSelected
                      ? CRMColors.primaryOf(context)
                      : CRMColors.textSecondaryOf(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CRMColors.warning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordResetsTabContent() {
    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.vpn_key_rounded,
                    color: CRMColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Pending Password Reset Requests (${_passwordResets.length})",
                    style: CRMTypography.sectionTitle.copyWith(
                      color: CRMColors.textOf(context),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh Requests',
                onPressed: _fetchPasswordResets,
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          if (_isLoadingResets)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_passwordResets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 48, color: CRMColors.success.withOpacity(0.8)),
                    const SizedBox(height: 12),
                    Text(
                      "No Pending Password Reset Requests",
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Requests submitted by salespeople will appear here.",
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _passwordResets.length,
              separatorBuilder: (context, index) =>
                  Divider(color: CRMColors.borderOf(context).withOpacity(0.5)),
              itemBuilder: (context, index) {
                final r = _passwordResets[index];
                final userName = r['userName'] ?? '';
                final userEmail = r['userEmail'] ?? '';
                final roleName = r['roleName'] ?? 'Sales';
                final createdAtStr = r['createdAt'] ?? '';

                String timeDisplay = 'recently';
                try {
                  final dt = DateTime.parse(createdAtStr);
                  final diff = DateTime.now().difference(dt);
                  if (diff.inMinutes < 60) {
                    timeDisplay = '${diff.inMinutes}m ago';
                  } else if (diff.inHours < 24) {
                    timeDisplay = '${diff.inHours}h ago';
                  } else {
                    timeDisplay = '${diff.inDays}d ago';
                  }
                } catch (_) {}

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: CRMColors.warning.withOpacity(0.15),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: CRMColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  userName,
                                  style: CRMTypography.bodyMedium.copyWith(
                                    color: CRMColors.textOf(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CRMColors.warning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    roleName,
                                    style: CRMTypography.caption.copyWith(
                                      color: CRMColors.warning,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$userEmail • Requested $timeDisplay",
                              style: CRMTypography.caption.copyWith(
                                color: CRMColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CRMButton(
                        label: "Reset Password",
                        variant: CRMButtonVariant.primary,
                        onPressed: () => _showResetPasswordDialog(r),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _getListingTypeLabelForSalesman(RequirementModel r) {
    final name = r.listingTypeName ?? '';
    final id = r.listingTypeId ?? '';
    final combined = '$name $id'.toLowerCase();
    if (combined.contains('rent')) {
      return 'Rent';
    } else if (combined.contains('sale') || combined.contains('resale')) {
      return 'Re-Sale';
    }
    return 'Rent';
  }

  void _showSalesmanDetails(UserModel salesman) {
    String activeTab = 'Rent';
    String currentView = 'stats';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenWidth = MediaQuery.of(dialogContext).size.width;
            final isMobile = screenWidth < 600;

            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 0 : 40,
                vertical: isMobile ? 0 : 24,
              ),
              backgroundColor: CRMColors.surfaceElevatedOf(dialogContext),
              elevation: 8,
              shadowColor: CRMColors.shadow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  isMobile ? 0 : CRMBorderRadius.dialog,
                ),
                side: BorderSide(
                  color: CRMColors.borderOf(dialogContext).withOpacity(0.5),
                  width: 0.5,
                ),
              ),
              child: Container(
                width: isMobile ? double.infinity : 650,
                height: isMobile ? double.infinity : 550,
                padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.l),
                child: FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    PropertiesRepository().getProperties(
                      createdBy: salesman.id,
                    ),
                    RequirementsRepository().getRequirements(),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: CRMColors.danger,
                            size: 48,
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          Text(
                            "Failed to load statistics",
                            style: CRMTypography.sectionTitle,
                          ),
                          const SizedBox(height: CRMSpacing.l),
                          CRMButton(
                            label: "Close",
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      );
                    }

                    final properties =
                        (snapshot.data?[0] as List<PropertyModel>?) ?? [];
                    final allReqs =
                        (snapshot.data?[1] as List<RequirementModel>?) ?? [];
                    final requirements = allReqs
                        .where((r) => r.adminId == salesman.id)
                        .toList();

                    // Filter helper functions
                    List<PropertyModel> getFilteredProperties() {
                      return properties.where((p) {
                        final ltName = p.listingTypeName.toLowerCase();
                        final matchesListing = activeTab == 'Rent'
                            ? ltName.contains('rent')
                            : (ltName.contains('sale') ||
                                  ltName.contains('resale') ||
                                  !ltName.contains('rent'));
                        return matchesListing;
                      }).toList();
                    }

                    List<RequirementModel> getFilteredRequirements() {
                      return requirements.where((r) {
                        final matchesListing =
                            _getListingTypeLabelForSalesman(r) == activeTab;
                        return matchesListing;
                      }).toList();
                    }

                    // Count helpers
                    final filteredProps = getFilteredProperties();
                    final filteredReqs = getFilteredRequirements();
                    final wonReqs = filteredReqs
                        .where((r) => r.status == 'Won' || r.status == 'Closed')
                        .length;

                    // Building Views
                    if (currentView == 'properties') {
                      return _buildPropertiesView(
                        salesman,
                        filteredProps,
                        () => setDialogState(() => currentView = 'stats'),
                        isMobile,
                      );
                    }

                    if (currentView == 'requirements') {
                      return _buildRequirementsView(
                        salesman,
                        filteredReqs,
                        () => setDialogState(() => currentView = 'stats'),
                        isMobile,
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      CRMColors.primary.withOpacity(0.1),
                                  radius: 20,
                                  backgroundImage: (salesman.profilePhoto != null && salesman.profilePhoto!.isNotEmpty)
                                      ? NetworkImage(salesman.profilePhoto!)
                                      : null,
                                  child: (salesman.profilePhoto != null && salesman.profilePhoto!.isNotEmpty)
                                      ? null
                                      : Icon(
                                          Icons.person_rounded,
                                          color: CRMColors.primary,
                                          size: 20,
                                        ),
                                ),
                                const SizedBox(width: CRMSpacing.m),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      salesman.fullName,
                                      style: CRMTypography.sectionTitle
                                          .copyWith(
                                            color: CRMColors.textOf(context),
                                          ),
                                    ),
                                    Text(
                                      "Salesman Profile & Metrics",
                                      style: CRMTypography.caption.copyWith(
                                        color: CRMColors.textSecondaryOf(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: CRMColors.textMutedOf(context),
                              ),
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: CRMSpacing.m),
                        Divider(
                          color: CRMColors.borderOf(context).withOpacity(0.5),
                        ),
                        const SizedBox(height: CRMSpacing.m),

                        // Contact info
                        Row(
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 16,
                              color: CRMColors.textSecondaryOf(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              salesman.email,
                              style: CRMTypography.bodyMedium.copyWith(
                                color: CRMColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                        if (salesman.mobile != null &&
                            salesman.mobile!.isNotEmpty) ...[
                          const SizedBox(height: CRMSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: CRMColors.textSecondaryOf(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                salesman.mobile!,
                                style: CRMTypography.bodyMedium.copyWith(
                                  color: CRMColors.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: CRMSpacing.l),

                        // Rent vs Re-Sale Toggle Buttons
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 44,
                            width: 240,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: CRMColors.backgroundOf(context),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: CRMColors.borderOf(
                                  context,
                                ).withOpacity(0.6),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setDialogState(
                                      () => activeTab = 'Rent',
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: activeTab == 'Rent'
                                            ? CRMColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Rent',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: activeTab == 'Rent'
                                              ? Colors.white
                                              : const Color(0xFF6B7280),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setDialogState(
                                      () => activeTab = 'Re-Sale',
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: activeTab == 'Re-Sale'
                                            ? CRMColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Re-Sale',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: activeTab == 'Re-Sale'
                                              ? Colors.white
                                              : const Color(0xFF6B7280),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: CRMSpacing.l),

                        // KPI boxes
                        Wrap(
                          spacing: CRMSpacing.s,
                          runSpacing: CRMSpacing.s,
                          children: [
                            _buildDialogStatCard(
                              "Properties Added",
                              filteredProps.length.toString(),
                              Icons.home_work_outlined,
                              CRMColors.primary,
                              isMobile,
                            ),
                            _buildDialogStatCard(
                              "Requirements",
                              filteredReqs.length.toString(),
                              Icons.assignment_outlined,
                              CRMColors.info,
                              isMobile,
                            ),
                            _buildDialogStatCard(
                              "Won Clients",
                              wonReqs.toString(),
                              Icons.workspace_premium_outlined,
                              CRMColors.success,
                              isMobile,
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Bottom Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.home_work_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  isMobile
                                      ? "Properties"
                                      : "View Properties Added",
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide(
                                    color: CRMColors.primary,
                                  ),
                                  foregroundColor: CRMColors.primary,
                                ),
                                onPressed: () => setDialogState(
                                  () => currentView = 'properties',
                                ),
                              ),
                            ),
                            const SizedBox(width: CRMSpacing.m),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.assignment_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  isMobile
                                      ? "Requirements"
                                      : "View Requirements",
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor: CRMColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => setDialogState(
                                  () => currentView = 'requirements',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return Container(
      width: isMobile ? double.infinity : 180,
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(
          color: CRMColors.borderOf(context).withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CRMTypography.caption.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: CRMTypography.sectionTitle.copyWith(
                    color: CRMColors.textOf(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesView(
    UserModel salesman,
    List<PropertyModel> list,
    VoidCallback onBack,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
            ),
            const SizedBox(width: CRMSpacing.s),
            Expanded(
              child: Text(
                "Properties Added by ${salesman.fullName}",
                style: CRMTypography.sectionTitle.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: CRMSpacing.m),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text("No properties found for this listing type."),
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = list[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        p.title,
                        style: CRMTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: CRMColors.textOf(context),
                        ),
                      ),
                      subtitle: Text(
                        "${p.propertyCode} • ${p.areaName} • ${p.configurationName ?? p.bedrooms.toString() + ' BHK'}",
                        style: CRMTypography.caption.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                      trailing: Text(
                        BudgetFormatter.format(p.price),
                        style: CRMTypography.bodyMedium.copyWith(
                          color: CRMColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequirementsView(
    UserModel salesman,
    List<RequirementModel> list,
    VoidCallback onBack,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
            ),
            const SizedBox(width: CRMSpacing.s),
            Expanded(
              child: Text(
                "Requirements Added by ${salesman.fullName}",
                style: CRMTypography.sectionTitle.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: CRMSpacing.m),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text("No requirements found for this listing type."),
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = list[index];
                    final specLabel =
                        '${r.propertyTypeName} (${r.configurationName ?? ""})';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        r.clientName,
                        style: CRMTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: CRMColors.textOf(context),
                        ),
                      ),
                      subtitle: Text(
                        "${r.clientMobile} • $specLabel\nTarget: ${r.areaNames.join(', ')}",
                        style: CRMTypography.caption.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${BudgetFormatter.format(r.minBudget)} - ₹${BudgetFormatter.format(r.maxBudget)}",
                            style: CRMTypography.bodyMedium.copyWith(
                              color: CRMColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (r.status == 'Won' || r.status == 'Closed')
                                  ? CRMColors.success.withOpacity(0.1)
                                  : CRMColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              r.status,
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    (r.status == 'Won' || r.status == 'Closed')
                                    ? CRMColors.success
                                    : CRMColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAdminStatsDialog(UserModel user) {
    // Capture once so dialog rebuilds do not re-fire the network call.
    final statsFuture = DioClient.dio.get('/users/admins/${user.id}/stats');
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: CRMColors.surfaceElevatedOf(dialogContext),
          elevation: 8,
          shadowColor: CRMColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
            side: BorderSide(
              color: CRMColors.borderOf(dialogContext).withOpacity(0.5),
              width: 0.5,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: FutureBuilder<Response>(
              future: statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: CRMColors.primary,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data?.data['success'] == false) {
                  return Padding(
                    padding: const EdgeInsets.all(CRMSpacing.l),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: CRMColors.danger,
                          size: 48,
                        ),
                        const SizedBox(height: CRMSpacing.m),
                        Text(
                          "Failed to load statistics.",
                          style: CRMTypography.sectionTitle.copyWith(
                            color: CRMColors.text,
                          ),
                        ),
                        const SizedBox(height: CRMSpacing.l),
                        CRMButton(
                          label: "Close",
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  );
                }

                final stats = snapshot.data!.data['data'];
                final adminName = stats['adminName'] ?? user.fullName;
                final salesCreated = stats['salesCreated'] ?? 0;
                final activeSales = stats['activeSales'] ?? 0;
                final inactiveSales = stats['inactiveSales'] ?? 0;
                final propertiesAdded = stats['propertiesAdded'] ?? 0;
                final requirementsAdded = stats['requirementsAdded'] ?? 0;

                Widget buildStatCard(
                  String title,
                  String value,
                  IconData icon,
                  Color color,
                ) {
                  return Container(
                    padding: const EdgeInsets.all(CRMSpacing.m),
                    decoration: BoxDecoration(
                      color: CRMColors.backgroundOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                      border: Border.all(
                        color: CRMColors.borderOf(context).withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: CRMTypography.caption.copyWith(
                                  color: CRMColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                value,
                                style: CRMTypography.sectionTitle.copyWith(
                                  color: CRMColors.text,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: CRMColors.info,
                                radius: 20,
                                child: Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: CRMSpacing.m),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    adminName,
                                    style: CRMTypography.sectionTitle.copyWith(
                                      color: CRMColors.text,
                                    ),
                                  ),
                                  Text(
                                    "Administrator Profile & Metrics",
                                    style: CRMTypography.caption.copyWith(
                                      color: CRMColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: CRMColors.textMuted,
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      Divider(
                        color: CRMColors.borderOf(context).withOpacity(0.5),
                      ),
                      const SizedBox(height: CRMSpacing.m),

                      // Contact info
                      Row(
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            size: 16,
                            color: CRMColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.email,
                            style: CRMTypography.bodyMedium.copyWith(
                              color: CRMColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (user.mobile != null && user.mobile!.isNotEmpty) ...[
                        const SizedBox(height: CRMSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: CRMColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user.mobile!,
                              style: CRMTypography.bodyMedium.copyWith(
                                color: CRMColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: CRMSpacing.l),

                      Text(
                        "TEAM STATISTICS",
                        style: CRMTypography.captionBold.copyWith(
                          color: CRMColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: CRMSpacing.s),

                      // Metrics Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: CRMSpacing.s,
                        mainAxisSpacing: CRMSpacing.s,
                        childAspectRatio: 2.8,
                        children: [
                          buildStatCard(
                            "Sales Created",
                            salesCreated.toString(),
                            Icons.group_add_rounded,
                            CRMColors.primary,
                          ),
                          buildStatCard(
                            "Active Sales",
                            activeSales.toString(),
                            Icons.check_circle_outline_rounded,
                            CRMColors.success,
                          ),
                          buildStatCard(
                            "Inactive Sales",
                            inactiveSales.toString(),
                            Icons.cancel_outlined,
                            CRMColors.danger,
                          ),
                          buildStatCard(
                            "Properties",
                            propertiesAdded.toString(),
                            Icons.home_work_outlined,
                            CRMColors.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: CRMSpacing.s),
                      buildStatCard(
                        "Requirements Added",
                        requirementsAdded.toString(),
                        Icons.assignment_outlined,
                        CRMColors.warning,
                      ),

                      const SizedBox(height: CRMSpacing.xl),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CRMButton(
                          label: "Dismiss",
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(
    StateSetter dialogSetState,
    Function(String) onUploaded,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    dialogSetState(() {
      _isUploadingPhoto = true;
    });

    try {
      final String fileExt = pickedFile.name.split('.').last.toLowerCase();
      final bool isPng = fileExt == 'png';
      MultipartFile multipartFile;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          throw Exception("Image size must be less than 2 MB.");
        }
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: pickedFile.name,
          contentType: MediaType('image', isPng ? 'png' : 'jpeg'),
        );
      } else {
        final File file = File(pickedFile.path);
        final int sizeInBytes = await file.length();

        File uploadFile = file;

        // Deterministic compression pipeline
        if (sizeInBytes > 0) {
          final String targetPath =
              "${Directory.systemTemp.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.${isPng ? 'png' : 'jpg'}";

          // Step 1: Compress with 80% quality and resize max 800x800 px
          XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 80,
            format: isPng ? CompressFormat.png : CompressFormat.jpeg,
            minWidth: 800,
            minHeight: 800,
          );

          if (compressedFile != null) {
            uploadFile = File(compressedFile.path);
            int compressedSize = await uploadFile.length();

            // Step 2: If size exceeds 500 KB limit, re-compress with 70% quality
            if (compressedSize > 500 * 1024) {
              final String secondPath =
                  "${Directory.systemTemp.path}/compressed_70_${DateTime.now().millisecondsSinceEpoch}.${isPng ? 'png' : 'jpg'}";
              final XFile? secondCompressed =
                  await FlutterImageCompress.compressAndGetFile(
                    file.absolute.path,
                    secondPath,
                    quality: 70,
                    format: isPng ? CompressFormat.png : CompressFormat.jpeg,
                    minWidth: 800,
                    minHeight: 800,
                  );
              if (secondCompressed != null) {
                uploadFile = File(secondCompressed.path);
                compressedSize = await uploadFile.length();
              }
            }

            // Step 3: Assert ultimate limit of 2 MB
            if (compressedSize > 2 * 1024 * 1024) {
              throw Exception(
                "Compressed image size exceeds the required 2 MB limit.",
              );
            }
          }
        }

        multipartFile = await MultipartFile.fromFile(
          uploadFile.path,
          filename: isPng ? 'profile_photo.png' : 'profile_photo.jpg',
          contentType: MediaType('image', isPng ? 'png' : 'jpeg'),
        );
      }

      final formData = FormData.fromMap({'file': multipartFile});

      Response? response;
      int retries = 3;
      while (retries > 0) {
        try {
          response = await DioClient.dio.post(
            '/users/upload-profile?updateSelf=false',
            data: formData,
          );
          break;
        } catch (e) {
          retries--;
          if (retries == 0) rethrow;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (response != null && response.data != null) {
        final publicUrl = response.data['data']['publicUrl'];
        onUploaded(publicUrl);
      }
    } catch (e) {
      String errorMsg = 'Failed to upload photo.';
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      } else if (e is Exception) {
        errorMsg = e.toString().replaceAll("Exception: ", "");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: CRMColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      dialogSetState(() {
        _isUploadingPhoto = false;
      });
    }
  }
}
