import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../../../core/design_system/widgets/inputs.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../../core/design_system/widgets/crm_network_image.dart';
import '../../../core/design_system/widgets/app_status_snackbar.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/search/search_request_gate.dart';
import '../../../core/api/cloudinary_uploader.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:go_router/go_router.dart';
import '../../../core/security/permission_matrix_service.dart';
import '../../../core/security/role_guard.dart';
import '../widgets/employees_ui/employees_tokens.dart';
import '../widgets/employees_ui/employees_widgets.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchRequestGate _searchGate = SearchRequestGate();
  String? _selectedRoleId;
  String _selectedStatus = "All";

  List<dynamic> _passwordResets = [];
  bool _isLoadingResets = false;
  int _activeTabIndex = 0;
  bool _isUploadingPhoto = false;

  /// New_UI filter chips (employees.html). Role uses name match; login maps to status.
  String _roleChip = ''; // '' | Sales | Telecaller | Admin
  String _loginChip = ''; // '' | 1 | 0
  String? _focusedUserId;

  @override
  void initState() {
    super.initState();
    _triggerFetch();
    _fetchPasswordResets();
    _employeeActionSignature = _currentEmployeeActionSignature();
    PermissionMatrixService.instance.addListener(_onEmployeeActionPermissionsChanged);
  }

  @override
  void dispose() {
    PermissionMatrixService.instance.removeListener(_onEmployeeActionPermissionsChanged);
    _searchGate.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _employeeActionSignature = '';

  bool _can(String actionKey) => RoleGuard.canAction(actionKey);

  String _currentEmployeeActionSignature() => PermissionMatrixService.adminActionKeys
      .where((k) => k.startsWith('page.employees.'))
      .map((k) => _can(k) ? '1' : '0')
      .join();

  void _onEmployeeActionPermissionsChanged() {
    final signature = _currentEmployeeActionSignature();
    if (!mounted || signature == _employeeActionSignature) return;
    _employeeActionSignature = signature;
    setState(() {});
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

    if (!mounted) return;
    setState(() {
      _isLoadingResets = true;
    });
    try {
      final response = await DioClient.dio.get('/users/password-resets');
      final data = response.data['data']['resets'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _passwordResets = data;
        _isLoadingResets = false;
      });
    } catch (e) {
      if (!mounted) return;
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
            final telecallerRole = usersState.roles.firstWhere(
              (r) => r.name.toLowerCase() == 'telecaller',
              orElse: () => const RoleModel(id: '', name: 'Telecaller', description: ''),
            );
            roles = [
              if (salesRole.id.isNotEmpty) salesRole,
              if (telecallerRole.id.isNotEmpty) telecallerRole,
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
                  color: CRMColors.borderOf(context).withValues(alpha: 0.5),
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
                                      ).withValues(alpha: 0.6),
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
                                        ? CrmNetworkImage(
                                            url: uploadedPhotoUrl!,
                                            fit: BoxFit.cover,
                                            width: 90,
                                            height: 90,
                                            cacheLogicalWidth: 90,
                                            error: (context) => Icon(
                                              Icons.person_rounded,
                                              size: 48,
                                              color: CRMColors.textMuted,
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
                              if (digits.isEmpty) {
                                return 'Phone number required';
                              }
                              if (digits.length != 10) {
                                return 'Enter a valid 10-digit mobile';
                              }
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
                              initialValue: localSelectedRoleId,
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
                                                AppStatusSnackBar.show(
                                                  context,
                                                  message: 'A sales user with this mobile number already exists.',
                                                  isSuccess: false,
                                                );
                                                return;
                                              }

                                              final emailExists = usersState.users
                                                  .any((u) => u.email.trim().toLowerCase() == emailController.text.trim().toLowerCase());
                                              if (emailExists) {
                                                AppStatusSnackBar.show(
                                                  context,
                                                  message: 'A sales user with this email address already exists.',
                                                  isSuccess: false,
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
          if (!mounted) return;
          if (state is UsersOperationSuccess) {
            AppStatusSnackBar.show(
              context,
              message: state.message,
              isSuccess: true,
            );
            _triggerFetch();
            _fetchPasswordResets();
          } else if (state is UsersError) {
            AppStatusSnackBar.show(
              context,
              message: "Error: ${state.message}",
              isSuccess: false,
            );
          }
        },
        child: SingleChildScrollView(
          clipBehavior: Clip.hardEdge,
          padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader(),
              const SizedBox(height: CRMSpacing.l),
              _buildStatisticsRow(),
              const SizedBox(height: CRMSpacing.m),
              _buildLoginOffBanner(),
              if (authState is Authenticated &&
                  (authState.user.role == 'Super Admin' || authState.user.role == 'Admin') &&
                  _can('page.employees.tree')) ...[
                const SizedBox(height: CRMSpacing.s),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/users/tree'),
                    icon: const Icon(Icons.account_tree_rounded, size: 18),
                    label: Text(authState.user.role == 'Super Admin' ? 'User Tree' : 'Employee Tree'),
                  ),
                ),
              ],
              const SizedBox(height: CRMSpacing.m),
              if (authState is Authenticated &&
                  (authState.user.role == 'Super Admin' || authState.user.role == 'Admin')) ...[
                _buildTabBar(),
                const SizedBox(height: CRMSpacing.m),
              ],
              if (_activeTabIndex == 1)
                _buildPasswordResetsTabContent()
              else ...[
                _buildSearchAndFiltersCard(),
                const SizedBox(height: CRMSpacing.l),
                _buildEmployeesBody(),
                const SizedBox(height: CRMSpacing.l),
                _buildRoleSummaries(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<UserModel> _teamWithoutSelf(List<UserModel> users) {
    final authState = context.read<AuthBloc>().state;
    final selfId = authState is Authenticated ? authState.user.id : null;
    return users.where((u) => u.id != selfId).toList();
  }

  void _applyFilters({
    String? roleChip,
    String? loginChip,
    List<RoleModel> roles = const [],
  }) {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    final isSuperAdmin = authState is Authenticated && authState.user.role == 'Super Admin';
    setState(() {
      if (roleChip != null) {
        _roleChip = roleChip;
        if (roleChip.isEmpty) {
          _selectedRoleId = null;
        } else {
          final match = roles.where((r) => r.name.toLowerCase() == roleChip.toLowerCase());
          _selectedRoleId = match.isEmpty ? null : match.first.id;
        }
      }
      if (loginChip != null) {
        _loginChip = loginChip;
        if (loginChip == '1') {
          _selectedStatus = 'Active';
        } else if (loginChip == '0') {
          _selectedStatus = 'Inactive';
        } else {
          _selectedStatus = 'All';
        }
      }
      if (isSuperAdmin && _roleChip.toLowerCase() == 'admin') {
        _activeTabIndex = 2;
      } else if (_activeTabIndex != 1) {
        _activeTabIndex = 0;
      }
    });
    _triggerFetch();
  }

  void _applyRoleChip(String roleName, List<RoleModel> roles) {
    _applyFilters(roleChip: roleName, roles: roles);
  }

  void _applyLoginChip(String login) {
    _applyFilters(loginChip: login);
  }

  Future<void> _callUser(UserModel user) async {
    final raw = user.mobile?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (raw.isEmpty) return;
    final uri = Uri.parse('tel:$raw');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      AppStatusSnackBar.show(context, message: 'Could not start call', isSuccess: false);
    }
  }

  Widget _buildPageHeader() {
    final authState = context.read<AuthBloc>().state;
    final isSuperAdmin = authState is Authenticated && authState.user.role == 'Super Admin';
    final canLeadAlloc = _can('page.lead_allocation');
    final narrow = MediaQuery.of(context).size.width < 900;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSuperAdmin ? 'Users' : 'Employees',
          style: CRMTypography.pageTitle.copyWith(color: EmTokens.ink(context)),
        ),
        const SizedBox(height: 4),
        Text(
          'Your team, their roles, who can log in, and the work each person is carrying.',
          style: CRMTypography.body.copyWith(color: EmTokens.muted(context), fontSize: 13.5),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: narrow ? WrapAlignment.start : WrapAlignment.end,
      children: [
        if (canLeadAlloc)
          OutlinedButton(
            onPressed: () => context.go('/admin/lead-allocation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: EmTokens.ink(context),
              side: BorderSide(color: EmTokens.line(context)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: const Text('Lead allocation rules'),
          ),
        if (_can('page.employees.add'))
          FilledButton.icon(
            onPressed: () => _showAddEditUserDialog(),
            style: FilledButton.styleFrom(
              backgroundColor: EmTokens.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Employee'),
          ),
      ],
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 12),
          actions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }

  Widget _buildStatisticsRow() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        var total = 0;
        var canLogin = 0;
        var sales = 0;
        var tele = 0;
        var admins = 0;
        List<RoleModel> roles = const [];

        if (state is UsersLoaded) {
          roles = state.roles;
          final list = _teamWithoutSelf(state.users);
          total = list.length;
          canLogin = list.where((u) => u.isActive).length;
          sales = list.where((u) => u.roleName.toLowerCase() == 'sales').length;
          tele = list.where((u) => u.roleName.toLowerCase() == 'telecaller').length;
          admins = list.where((u) => u.roleName.toLowerCase() == 'admin').length;
        }

        final width = MediaQuery.of(context).size.width;
        final columns = width >= 1200 ? 5 : (width >= 800 ? 3 : 2);
        final gap = 11.0;

        final cards = [
          EmKpiCard(
            label: 'Total employees',
            value: '$total',
            hint: 'Everyone on the team',
            dot: EmTokens.gray,
            selected: _roleChip.isEmpty && _loginChip.isEmpty,
            onTap: () => _applyFilters(roleChip: '', loginChip: '', roles: roles),
          ),
          EmKpiCard(
            label: 'Can log in',
            value: '$canLogin',
            hint: '${total - canLogin} with login off',
            dot: EmTokens.greenBright,
            selected: _loginChip == '1' && _roleChip.isEmpty,
            onTap: () => _applyFilters(roleChip: '', loginChip: '1', roles: roles),
          ),
          EmKpiCard(
            label: 'Sales',
            value: '$sales',
            hint: 'Handle leads & site visits',
            dot: EmTokens.green,
            selected: _roleChip == 'Sales',
            onTap: () => _applyFilters(roleChip: 'Sales', loginChip: '', roles: roles),
          ),
          EmKpiCard(
            label: 'Telecallers',
            value: '$tele',
            hint: 'First call on new leads',
            dot: EmTokens.violet,
            selected: _roleChip == 'Telecaller',
            onTap: () => _applyFilters(roleChip: 'Telecaller', loginChip: '', roles: roles),
          ),
          EmKpiCard(
            label: 'Administrators',
            value: '$admins',
            hint: 'Besides Propkart Admin',
            dot: EmTokens.red,
            selected: _roleChip == 'Admin',
            onTap: () => _applyFilters(roleChip: 'Admin', loginChip: '', roles: roles),
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final cardW = columns == 1
                ? maxW
                : (maxW - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: cards
                  .map((c) => SizedBox(width: cardW.isFinite ? cardW : maxW, child: c))
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildLoginOffBanner() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        if (state is! UsersLoaded) return const SizedBox.shrink();
        final off = _teamWithoutSelf(state.users).where((u) => !u.isActive).toList();
        if (off.isEmpty) return const SizedBox.shrink();
        final names = off.map((u) => u.fullName).take(3).join(' and ');
        final more = off.length > 3 ? ' and ${off.length - 3} more' : '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: EmLoginOffBanner(
            names: '$names$more',
            onShow: () => _applyFilters(roleChip: '', loginChip: '0', roles: state.roles),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFiltersCard() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        final roles = state is UsersLoaded ? state.roles : <RoleModel>[];
        final list = state is UsersLoaded ? _teamWithoutSelf(state.users) : <UserModel>[];
        final salesN = list.where((u) => u.roleName.toLowerCase() == 'sales').length;
        final teleN = list.where((u) => u.roleName.toLowerCase() == 'telecaller').length;
        final adminN = list.where((u) => u.roleName.toLowerCase() == 'admin').length;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            EmFilterChip(
              label: 'All',
              count: '${list.length}',
              selected: _roleChip.isEmpty,
              onTap: () => _applyRoleChip('', roles),
            ),
            EmFilterChip(
              label: 'Sales',
              count: '$salesN',
              selected: _roleChip == 'Sales',
              onTap: () => _applyRoleChip('Sales', roles),
            ),
            EmFilterChip(
              label: 'Telecallers',
              count: '$teleN',
              selected: _roleChip == 'Telecaller',
              onTap: () => _applyRoleChip('Telecaller', roles),
            ),
            EmFilterChip(
              label: 'Admins',
              count: '$adminN',
              selected: _roleChip == 'Admin',
              onTap: () => _applyRoleChip('Admin', roles),
            ),
            Container(width: 1, height: 24, color: EmTokens.line(context), margin: const EdgeInsets.symmetric(horizontal: 4)),
            EmFilterChip(
              label: 'Any login',
              selected: _loginChip.isEmpty,
              onTap: () => _applyLoginChip(''),
            ),
            EmFilterChip(
              label: 'Can log in',
              selected: _loginChip == '1',
              onTap: () => _applyLoginChip('1'),
            ),
            EmFilterChip(
              label: 'Login off',
              selected: _loginChip == '0',
              onTap: () => _applyLoginChip('0'),
            ),
            SizedBox(
              width: (MediaQuery.sizeOf(context).width - 48).clamp(200.0, 340.0),
              child: TextField(
                controller: _searchController,
                style: CRMTypography.body.copyWith(color: EmTokens.ink(context)),
                decoration: InputDecoration(
                  hintText: 'Name, email or phone number',
                  hintStyle: CRMTypography.body.copyWith(color: EmTokens.muted(context)),
                  prefixIcon: Icon(Icons.search_rounded, color: EmTokens.muted(context)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: EmTokens.muted(context)),
                          onPressed: () {
                            _searchController.clear();
                            _triggerFetch();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: EmTokens.panelBg(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EmTokens.line(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: EmTokens.line(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: EmTokens.green, width: 1.5),
                  ),
                ),
                onChanged: (_) => _searchGate.schedule((_) {
                  if (mounted) _triggerFetch();
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmployeesBody() {
    final wide = MediaQuery.of(context).size.width >= 1100;
    if (!wide) {
      return _buildEmployeesTable();
    }
    return BlocBuilder<UsersBloc, UsersState>(
      buildWhen: (prev, next) =>
          next is UsersLoaded || next is UsersLoading || next is UsersError,
      builder: (context, state) {
        if (state is! UsersLoaded) {
          return _buildEmployeesTable();
        }
        final list = _teamWithoutSelf(state.users);
        UserModel? focused;
        if (list.isNotEmpty) {
          for (final u in list) {
            if (u.id == _focusedUserId) {
              focused = u;
              break;
            }
          }
          focused ??= list.first;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildEmployeesTable()),
            if (focused != null) ...[
              const SizedBox(width: 14),
              SizedBox(
                width: 340,
                child: EmDetailPanel(
                  key: ValueKey('em-det-${focused.id}'),
                  user: focused,
                  canEdit: _can('page.employees.edit'),
                  canDelete: _can('page.employees.delete'),
                  canToggle: _can('page.employees.active_toggle'),
                  canOpen: _can('page.employees.details'),
                  onCall: () => _callUser(focused!),
                  onEdit: () => _showAddEditUserDialog(focused),
                  onOpenProfile: () => _openEmployeePage(focused!),
                  onToggleLogin: (val) {
                    context.read<UsersBloc>().add(
                          ToggleUserStatusRequested(id: focused!.id, isActive: val),
                        );
                  },
                  onRemove: () => _showDeleteConfirmDialog(focused!),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRoleSummaries() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        if (state is! UsersLoaded) return const SizedBox.shrink();
        final list = _teamWithoutSelf(state.users);
        final sales = list.where((u) => u.roleName.toLowerCase() == 'sales').toList();
        final tele = list.where((u) => u.roleName.toLowerCase() == 'telecaller').toList();
        final admins = list.where((u) => u.roleName.toLowerCase() == 'admin').toList();
        final width = MediaQuery.of(context).size.width;
        final columns = width >= 1100 ? 3 : 1;
        final gap = 14.0;

        final cards = [
          EmRoleSummaryCard(
            title: 'Sales',
            badgeColor: EmTokens.green,
            badgeBg: EmTokens.roleBg('Sales'),
            count: sales.length,
            blurb: 'Own leads after the first call, run site visits and close deals.',
            people: sales,
            onPersonTap: _can('page.employees.details') ? _openEmployeePage : null,
          ),
          EmRoleSummaryCard(
            title: 'Telecallers',
            badgeColor: EmTokens.violet,
            badgeBg: EmTokens.roleBg('Telecaller'),
            count: tele.length,
            blurb: 'Make the first call on new leads and pass interested ones to sales.',
            people: tele,
            onPersonTap: _can('page.employees.details') ? _openEmployeePage : null,
          ),
          EmRoleSummaryCard(
            title: 'Administrators',
            badgeColor: EmTokens.red,
            badgeBg: EmTokens.roleBg('Admin'),
            count: admins.length,
            blurb: 'Can manage settings, employees and allocation rules.',
            people: admins,
            onPersonTap: _can('page.employees.details') ? _openEmployeePage : null,
            emptyChild: admins.isNotEmpty
                ? null
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: EmTokens.line(context)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'No administrators yet. Add one so someone besides Propkart Admin can manage settings.',
                          textAlign: TextAlign.center,
                          style: CRMTypography.caption.copyWith(color: EmTokens.muted(context)),
                        ),
                        if (_can('page.employees.add')) ...[
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: () => _showAddEditUserDialog(),
                            style: FilledButton.styleFrom(backgroundColor: EmTokens.green),
                            child: const Text('+ Add administrator'),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardW = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: cards.map((c) => SizedBox(width: cardW, child: c)).toList(),
            );
          },
        );
      },
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
          final emptyWorkspace = currentUser != null &&
              currentUser.role == 'Admin' &&
              !isInactiveFilter;
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
                          : emptyWorkspace
                              ? 'No employees in this workspace'
                              : 'No Employees Found',
                      style: CRMTypography.sectionTitle.copyWith(
                        color: CRMColors.textOf(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    Text(
                      isInactiveFilter
                          ? 'Try adjusting your filters or add a new employee profile.'
                          : emptyWorkspace
                              ? 'This admin workspace starts empty. Add Sales and Telecaller users here — they will not see another admin\'s inventory or campaign inbox.'
                              : 'Try adjusting your filters or add a new employee profile.',
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
        );
      },
    );
  }

  Widget _buildFullWidthEmployeesTable({
    required List<UserModel> users,
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
          color: CRMColors.borderOf(context).withValues(alpha: 0.55),
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

            return TableRow(
              decoration: BoxDecoration(
                color: CRMColors.cardBgOf(context),
                border: Border(
                  top: BorderSide(
                    color: CRMColors.borderOf(context).withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              children: [
                bodyCell(
                  InkWell(
                    onTap: () {
                      _focusEmployee(user);
                      _openEmployeePage(user);
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isAdmin
                              ? CRMColors.info.withValues(alpha: 0.1)
                              : CRMColors.primary.withValues(alpha: 0.1),
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
                            ? CRMColors.info.withValues(alpha: 0.12)
                            : CRMColors.primary.withValues(alpha: 0.12),
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
                      key: ValueKey('em-login-table-${user.id}'),
                      value: user.isActive,
                      activeTrackColor: CRMColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: !_can('page.employees.active_toggle') ? null : (val) {
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
                          if (_can('page.employees.details'))
                          IconButton(
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              color: CRMColors.primary,
                              size: 20,
                            ),
                            tooltip: 'Open employee page',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () => _openEmployeePage(user),
                          ),
                          if (_can('page.employees.edit'))
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
                          if (_can('page.employees.delete'))
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

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: CRMColors.borderOf(context).withValues(alpha: 0.55),
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
                    ? CRMColors.info.withValues(alpha: 0.1)
                    : CRMColors.primary.withValues(alpha: 0.1),
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
                      ? CRMColors.info.withValues(alpha: 0.12)
                      : CRMColors.primary.withValues(alpha: 0.12),
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
            color: CRMColors.borderOf(context).withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: CRMSpacing.s),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: CRMSpacing.s,
            runSpacing: CRMSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
                mainAxisSize: MainAxisSize.min,
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
                      activeTrackColor: CRMColors.primary,
                      onChanged: !_can('page.employees.active_toggle') ? null : (val) {
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
            color: CRMColors.borderOf(context).withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: CRMSpacing.s),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: CRMSpacing.s,
            runSpacing: 4,
            children: [
              if (_can('page.employees.details'))
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => _openEmployeePage(user),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: CRMColors.primary,
                  size: 16,
                ),
                label: Text('Open', style: TextStyle(color: CRMColors.primary)),
              ),
              if (_can('page.employees.edit'))
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => _showAddEditUserDialog(user),
                icon: Icon(
                  Icons.edit_outlined,
                  color: CRMColors.primary,
                  size: 16,
                ),
                label: Text('Edit', style: TextStyle(color: CRMColors.primary)),
              ),
              if (_can('page.employees.delete'))
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
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

    return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
              onTap: () => _openEmployeePage(user),
              child: cardContent,
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
                  color: CRMColors.borderOf(context).withValues(alpha: 0.5),
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

                                          if (dialogContext.mounted) {
                                            Navigator.pop(dialogContext);
                                          }

                                          if (context.mounted) {
                                            AppStatusSnackBar.show(
                                              context,
                                              message: "Password updated successfully.",
                                              isSuccess: true,
                                            );
                                          }

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
                                          if (context.mounted) {
                                            AppStatusSnackBar.show(
                                              context,
                                              message: "Error: $errorMsg",
                                              isSuccess: false,
                                            );
                                          }
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
            color: CRMColors.borderOf(context).withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: CRMShadows.soft,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabItem(0, isSuperAdmin ? "Users" : "Employees", Icons.people_rounded),
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
                ? CRMColors.primaryOf(context).withValues(alpha: 0.1)
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
                        size: 48, color: CRMColors.success.withValues(alpha: 0.8)),
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
                  Divider(color: CRMColors.borderOf(context).withValues(alpha: 0.5)),
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
                        backgroundColor: CRMColors.warning.withValues(alpha: 0.15),
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
                                    color: CRMColors.warning.withValues(alpha: 0.15),
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

  void _openEmployeePage(UserModel user) {
    setState(() => _focusedUserId = user.id);
    if (!_can('page.employees.details')) return;
    context.push('/users/${user.id}');
  }

  void _focusEmployee(UserModel user) {
    setState(() => _focusedUserId = user.id);
  }


  Future<void> _pickAndUploadPhoto(
    StateSetter dialogSetState,
    Function(String) onUploaded,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    dialogSetState(() {
      _isUploadingPhoto = true;
    });

    try {
      final String fileExt = pickedFile.name.contains('.')
          ? pickedFile.name.split('.').last.toLowerCase()
          : 'jpg';
      String mimeType = 'image/jpeg';
      if (fileExt == 'png') {
        mimeType = 'image/png';
      } else if (fileExt == 'webp') {
        mimeType = 'image/webp';
      } else if (fileExt == 'gif') {
        mimeType = 'image/gif';
      } else if (fileExt == 'bmp') {
        mimeType = 'image/bmp';
      } else if (fileExt == 'heic') {
        mimeType = 'image/heic';
      } else if (fileExt == 'avif') {
        mimeType = 'image/avif';
      }

      final bytes = await pickedFile.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception("Image size must be less than 5 MB.");
      }

      String? uploadedUrl;
      final String filename = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'profile_photo.$fileExt';

      // 1. Try Cloudinary direct signed upload
      try {
        uploadedUrl = await CloudinaryUploader.upload(
          bytes: bytes,
          filename: filename,
          mimeType: mimeType,
          resourceType: 'image',
          folder: 'profiles',
          fallbackEndpoint: '/users/upload-profile?updateSelf=false',
        );
      } catch (cloudErr) {
        if (kDebugMode) {
          print('⚠️ Cloudinary direct upload failed, attempting direct backend upload: $cloudErr');
        }
      }

      // 2. Fallback to direct backend upload if needed
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        final multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        );

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
          final data = response.data['data'];
          if (data is Map) {
            uploadedUrl = data['url'] ?? data['publicUrl'];
          }
        }
      }

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        onUploaded(uploadedUrl);
      } else {
        throw Exception("Upload succeeded but failed to retrieve image URL.");
      }
    } catch (e) {
      String errorMsg = 'Failed to upload photo.';
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      } else if (e is Exception) {
        errorMsg = e.toString().replaceAll("Exception: ", "");
      }
      if (mounted) {
        AppStatusSnackBar.show(
          context,
          message: errorMsg,
          isSuccess: false,
        );
      }
    } finally {
      dialogSetState(() {
        _isUploadingPhoto = false;
      });
    }
  }
}
