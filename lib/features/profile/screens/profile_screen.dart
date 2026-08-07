import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/design_system/widgets/inputs.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  bool _isUploadingPhoto = false;
  bool _isSavingDetails = false;
  bool _isLoadingAdminInfo = false;
  String? _loadedAdminName;
  String? _loadedAdminEmail;
  String? _loadedAdminRole;
  String? _loadedCreatedAt;
  String? _lastUserId;
  bool _isHealing = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  String _formatCreatedDate(String? rawDate) {
    final dateStr = (rawDate != null && rawDate.isNotEmpty) ? rawDate : _loadedCreatedAt;
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthStr = months[dt.month - 1];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minStr = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $monthStr ${dt.year}, $hour:$minStr $ampm';
    } catch (_) {
      return dateStr;
    }
  }

  void _syncUserData(UserModel user) {
    if (_lastUserId != user.id) {
      _lastUserId = user.id;
      _fullNameController.text = user.fullName;
      _mobileController.text = user.mobile ?? '';

      _loadedAdminName = user.adminName;
      _loadedAdminEmail = user.adminEmail;
      _loadedAdminRole = user.adminRole;
      _loadedCreatedAt = user.createdAt;

      _fetchUserExtraDetails(user);
    } else {
      if (_fullNameController.text != user.fullName && !_isSavingDetails) {
        _fullNameController.text = user.fullName;
      }
      if (_mobileController.text != (user.mobile ?? '') && !_isSavingDetails) {
        _mobileController.text = user.mobile ?? '';
      }
      if (_loadedAdminName != user.adminName) {
        _loadedAdminName = user.adminName;
      }
      if (_loadedAdminEmail != user.adminEmail) {
        _loadedAdminEmail = user.adminEmail;
      }
      if (_loadedAdminRole != user.adminRole) {
        _loadedAdminRole = user.adminRole;
      }
      if (_loadedCreatedAt != user.createdAt) {
        _loadedCreatedAt = user.createdAt;
      }
    }

    final isEmployee = user.role == 'Sales' || user.role == 'Telecaller';
    final hasSalesOrTelecallerCreator = _loadedAdminRole == 'Sales' || _loadedAdminRole == 'Telecaller';
    if (((user.role == 'Admin' && _loadedAdminRole == 'Sales') ||
        (isEmployee && hasSalesOrTelecallerCreator)) && !_isHealing) {
      _isHealing = true;
      _healDatabaseHierarchy(user);
    }
  }

  Future<void> _healDatabaseHierarchy(UserModel user) async {
    try {
      if (ApiConstants.useSupabaseDirect) {
        await Supabase.instance.client
            .from('users')
            .update({'admin_id': null})
            .eq('id', user.id);
      } else {
        await DioClient.dio.put('/users/${user.id}', data: {'admin_id': null});
      }
      if (mounted) {
        context.read<AuthBloc>().add(AuthCheckStatus());
      }
    } catch (_) {
      // Fail silently
    }
  }

  Future<void> _fetchUserExtraDetails(UserModel user) async {
    if (_isLoadingAdminInfo) return;
    setState(() {
      _isLoadingAdminInfo = true;
    });

    try {
      final response = await DioClient.dio.get('/users');
      if (response.data != null && response.data['data'] != null) {
        final usersList = response.data['data']['users'] as List? ?? [];

        // Look up self details for created_at if missing
        final selfMatch = usersList.firstWhere(
          (u) => u['id']?.toString() == user.id,
          orElse: () => null,
        );

        if (selfMatch != null && selfMatch['created_at'] != null) {
          _loadedCreatedAt = selfMatch['created_at']?.toString();
        }
      }
    } catch (_) {
      // Non-critical fallback
    }

    if (mounted) {
      setState(() {
        _isLoadingAdminInfo = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto(UserModel user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      MultipartFile multipartFile;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          throw Exception("Image size must be less than 2 MB.");
        }
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: pickedFile.name,
          contentType: MediaType('image', 'jpeg'),
        );
      } else {
        final File file = File(pickedFile.path);
        final int sizeInBytes = await file.length();
        File uploadFile = file;

        if (sizeInBytes > 0) {
          final String targetPath =
              "${Directory.systemTemp.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg";

          XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 80,
            minWidth: 800,
            minHeight: 800,
          );

          if (compressedFile != null) {
            uploadFile = File(compressedFile.path);
            int compressedSize = await uploadFile.length();

            if (compressedSize > 500 * 1024) {
              final String secondPath =
                  "${Directory.systemTemp.path}/profile_70_${DateTime.now().millisecondsSinceEpoch}.jpg";
              final XFile? secondCompressed = await FlutterImageCompress.compressAndGetFile(
                file.absolute.path,
                secondPath,
                quality: 70,
                minWidth: 800,
                minHeight: 800,
              );
              if (secondCompressed != null) {
                uploadFile = File(secondCompressed.path);
              }
            }
          }
        }

        multipartFile = await MultipartFile.fromFile(
          uploadFile.path,
          filename: 'profile_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
      }

      final formData = FormData.fromMap({'file': multipartFile});
      final response = await DioClient.dio.post('/users/upload-profile', data: formData);

      if (response.data != null && response.data['data'] != null) {
        final publicUrl = response.data['data']['publicUrl'];

        // Save updated profile photo to user profile
        try {
          await DioClient.dio.put('/users/${user.id}', data: {'profile_photo': publicUrl});
        } catch (_) {
          await DioClient.dio.patch('/auth/me', data: {'profile_photo': publicUrl});
        }

        if (mounted) {
          context.read<AuthBloc>().add(AuthCheckStatus());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile picture updated successfully!"),
              backgroundColor: CRMColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      String errorMsg = 'Failed to upload photo.';
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      } else if (e is Exception) {
        errorMsg = e.toString().replaceAll("Exception: ", "");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: CRMColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _deletePhoto(UserModel user) async {
    final confirm = await CRMDialogs.showDeleteConfirmation(
      context,
      title: "Remove Profile Photo",
      content: "Are you sure you want to remove your profile picture? Default avatar will be restored.",
    );

    if (confirm != true) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      try {
        await DioClient.dio.put('/users/${user.id}', data: {'profile_photo': null});
      } catch (_) {
        await DioClient.dio.patch('/auth/me', data: {'profile_photo': null});
      }

      if (mounted) {
        context.read<AuthBloc>().add(AuthCheckStatus());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile picture removed."),
            backgroundColor: CRMColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to remove profile picture."),
            backgroundColor: CRMColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _saveProfileDetails(UserModel user) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSavingDetails = true;
    });

    try {
      final updatedData = {
        'full_name': _fullNameController.text.trim(),
        'mobile': _mobileController.text.trim(),
      };

      try {
        await DioClient.dio.put('/users/${user.id}', data: updatedData);
      } catch (_) {
        await DioClient.dio.patch('/auth/me', data: {
          'fullName': _fullNameController.text.trim(),
          'mobile': _mobileController.text.trim(),
        });
      }

      if (mounted) {
        context.read<AuthBloc>().add(AuthCheckStatus());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile details saved successfully!"),
            backgroundColor: CRMColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      String errorMsg = "Failed to update profile details.";
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: CRMColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Register theme dependency
    final authState = context.watch<AuthBloc>().state;

    if (authState is! Authenticated) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = authState.user;
    _syncUserData(user);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header Title
            const CRMPageHeader(
              eyebrow: 'Account',
              title: 'My Profile',
              benefit:
                  'Keep your credentials, role, and photo current so teammates always reach the right you',
            ),
            const SizedBox(height: CRMSpacing.l),

            // Profile Card Header with Avatar, Pencil Edit, Trash Delete & Badges
            _buildProfileAvatarHeaderCard(user, isMobile),
            const SizedBox(height: CRMSpacing.l),

            // Personal Information Card & Creator Admin Card Layout
            if (isMobile) ...[
              _buildPersonalDetailsCard(user),
              const SizedBox(height: CRMSpacing.l),
              _buildCreatorAdminCard(user),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildPersonalDetailsCard(user),
                  ),
                  const SizedBox(width: CRMSpacing.l),
                  Expanded(
                    flex: 2,
                    child: _buildCreatorAdminCard(user),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatarHeaderCard(UserModel user, bool isMobile) {
    final bool hasPhoto = user.profilePhoto != null && user.profilePhoto!.isNotEmpty;
    final String roleLower = user.role.toLowerCase();

    Color roleColor = CRMColors.primaryOf(context);
    if (roleLower.contains('super')) {
      roleColor = CRMColors.secondary; // Secondary accent for Super Admin
    } else if (roleLower.contains('admin')) {
      roleColor = CRMColors.info; // Blue for Admin
    }

    return CRMCard(
      elevated: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m),
        child: Column(
          children: [
            // Avatar Stack with Edit Pencil & Delete Trash Buttons
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Ring Container
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: CRMColors.backgroundOf(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: roleColor.withOpacity(0.3), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _isUploadingPhoto
                          ? Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: CRMColors.primary,
                                ),
                              ),
                            )
                          : (hasPhoto
                              ? Image.network(
                                  user.profilePhoto!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildDefaultAvatarIcon(),
                                )
                              : _buildDefaultAvatarIcon()),
                    ),
                  ),

                  // Edit Pencil Button (Bottom Right) with Popup Menu
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: PopupMenuButton<String>(
                        tooltip: "Edit profile picture",
                        onSelected: (value) {
                          if (value == 'change') {
                            if (!_isUploadingPhoto) _pickAndUploadPhoto(user);
                          } else if (value == 'delete') {
                            _deletePhoto(user);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'change',
                            child: Row(
                              children: [
                                Icon(Icons.photo_library_rounded, size: 18, color: CRMColors.textOf(context)),
                                const SizedBox(width: 8),
                                Text('Change profile picture', style: CRMTypography.body.copyWith(color: CRMColors.textOf(context))),
                              ],
                            ),
                          ),
                          if (hasPhoto)
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded, size: 18, color: CRMColors.danger),
                                  const SizedBox(width: 8),
                                  Text('Delete profile picture', style: CRMTypography.body.copyWith(color: CRMColors.danger)),
                                ],
                              ),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CRMColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 16,
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

            // User Name
            Text(
              user.fullName,
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CRMSpacing.xs),

            // Email text
            Text(
              user.email,
              style: CRMTypography.body.copyWith(
                color: CRMColors.textSecondaryOf(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CRMSpacing.m),

            // Badges Row: Role Badge, Active Status Badge, and Account Creation Date Badge
            Wrap(
              alignment: WrapAlignment.center,
              spacing: CRMSpacing.s,
              runSpacing: CRMSpacing.xs,
              children: [
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        roleLower.contains('admin')
                            ? Icons.admin_panel_settings_rounded
                            : Icons.badge_rounded,
                        size: 14,
                        color: roleColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.role,
                        style: CRMTypography.captionBold.copyWith(
                          color: roleColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Active / Inactive Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? CRMColors.success.withOpacity(0.12)
                        : CRMColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                    border: Border.all(
                      color: (user.isActive ? CRMColors.success : CRMColors.danger).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: user.isActive ? CRMColors.success : CRMColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.isActive ? "Active Account" : "Inactive Account",
                        style: CRMTypography.captionBold.copyWith(
                          color: user.isActive ? CRMColors.success : CRMColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Account Creation Date Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: CRMColors.info.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                    border: Border.all(color: CRMColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: CRMColors.info,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Joined: ${_formatCreatedDate(user.createdAt)}",
                        style: CRMTypography.captionBold.copyWith(
                          color: CRMColors.info,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatarIcon() {
    return Container(
      color: CRMColors.primary.withOpacity(0.08),
      child: Icon(
        Icons.person_rounded,
        size: 56,
        color: CRMColors.primary,
      ),
    );
  }

  Widget _buildPersonalDetailsCard(UserModel user) {
    return CRMCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_pin_rounded, color: CRMColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  "Personal Details",
                  style: CRMTypography.sectionTitle.copyWith(
                    color: CRMColors.textOf(context),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.xs),
            Text(
              "Update your display name and contact phone number.",
              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: CRMSpacing.l),
            Divider(color: CRMColors.borderOf(context).withOpacity(0.5)),
            const SizedBox(height: CRMSpacing.l),

            // Full Name Input
            CRMTextField(
              controller: _fullNameController,
              labelText: 'Full Name *',
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_rounded,
              validator: (val) => val == null || val.trim().isEmpty ? "Full name required" : null,
            ),
            const SizedBox(height: CRMSpacing.m),

            // Mobile Phone Input
            CRMTextField(
              controller: _mobileController,
              labelText: 'Mobile Phone Number',
              hintText: '+91 XXXXX XXXXX',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: CRMSpacing.m),

            // Email Address (Read-only)
            CRMTextField(
              controller: TextEditingController(text: user.email),
              labelText: 'Email Address (System Login)',
              hintText: user.email,
              prefixIcon: Icons.email_rounded,
              readOnly: true,
              suffixIcon: Tooltip(
                message: "Email cannot be changed",
                child: Icon(Icons.lock_rounded, size: 16, color: CRMColors.textMuted),
              ),
            ),
            const SizedBox(height: CRMSpacing.m),

            // System Role (Read-only)
            CRMTextField(
              controller: TextEditingController(text: user.role),
              labelText: 'System Access Role',
              hintText: user.role,
              prefixIcon: Icons.admin_panel_settings_rounded,
              readOnly: true,
              suffixIcon: Tooltip(
                message: "Assigned by Administrator",
                child: Icon(Icons.verified_user_rounded, size: 16, color: CRMColors.primary),
              ),
            ),
            const SizedBox(height: CRMSpacing.m),

            // Account Created Date (Read-only)
            CRMTextField(
              controller: TextEditingController(text: _formatCreatedDate(user.createdAt)),
              labelText: 'Account Registration Date',
              hintText: 'Creation timestamp',
              prefixIcon: Icons.calendar_today_rounded,
              readOnly: true,
              suffixIcon: Tooltip(
                message: "System registration timestamp",
                child: Icon(Icons.access_time_filled_rounded, size: 16, color: CRMColors.info),
              ),
            ),
            const SizedBox(height: CRMSpacing.xl),

            // Action Button
            Align(
              alignment: Alignment.centerRight,
              child: CRMButton(
                label: "Save Profile Changes",
                prefixIcon: Icons.check_circle_rounded,
                isLoading: _isSavingDetails,
                onPressed: _isSavingDetails ? null : () => _saveProfileDetails(user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorAdminCard(UserModel user) {
    final String roleLower = user.role.toLowerCase();
    final bool isSuperAdmin = roleLower.contains('super');
    final bool isAdmin = roleLower == 'admin';

    String cardTitle = "Assigned Administrator";
    String cardSub = "Details of the administrator who added and manages this account.";

    if (isSuperAdmin) {
      cardTitle = "Account Hierarchy";
      cardSub = "Primary Enterprise Root Super Administrator Account.";
    } else if (isAdmin) {
      cardTitle = "Managing Super Admin";
      cardSub = "Details of the Super Administrator who onboarded this admin profile.";
    }

    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuperAdmin ? Icons.workspace_premium_rounded : Icons.supervisor_account_rounded,
                color: isSuperAdmin ? CRMColors.secondary : CRMColors.info,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cardTitle,
                  style: CRMTypography.sectionTitle.copyWith(
                    color: CRMColors.textOf(context),
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.xs),
          Text(
            cardSub,
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: CRMSpacing.l),
          Divider(color: CRMColors.borderOf(context).withOpacity(0.5)),
          const SizedBox(height: CRMSpacing.l),

          if (isSuperAdmin) ...[
            // Root Account Badge Container
            Container(
              padding: const EdgeInsets.all(CRMSpacing.m),
              decoration: BoxDecoration(
                color: CRMColors.secondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                border: Border.all(color: CRMColors.secondary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 40,
                    color: CRMColors.secondary,
                  ),
                  const SizedBox(height: CRMSpacing.s),
                  Text(
                    "Primary Workspace Root",
                    style: CRMTypography.bodyMedium.copyWith(
                      color: CRMColors.textOf(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "You hold full Super Administrator credentials for this enterprise workspace.",
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else if (_isLoadingAdminInfo) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else ...[
            // Creator / Administrator Profile View
            Container(
              padding: const EdgeInsets.all(CRMSpacing.m),
              decoration: BoxDecoration(
                color: CRMColors.backgroundOf(context),
                borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (isAdmin ? CRMColors.secondary : CRMColors.info).withOpacity(0.12),
                    radius: 22,
                    child: Icon(
                      isAdmin ? Icons.workspace_premium_rounded : Icons.admin_panel_settings_rounded,
                      color: isAdmin ? CRMColors.secondary : CRMColors.info,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loadedAdminName ?? (isAdmin ? "Super Administrator" : "Workspace Administrator"),
                          style: CRMTypography.bodyMedium.copyWith(
                            color: CRMColors.textOf(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (_loadedAdminEmail != null && _loadedAdminEmail!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _loadedAdminEmail!,
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isAdmin ? CRMColors.secondary : CRMColors.info).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                    ),
                    child: Text(
                      _loadedAdminRole ?? (isAdmin ? "Super Admin" : "Admin"),
                      style: CRMTypography.captionBold.copyWith(
                        color: isAdmin ? CRMColors.secondary : CRMColors.info,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CRMSpacing.m),

            // Relation detail pill
            Container(
              padding: const EdgeInsets.all(CRMSpacing.m),
              decoration: BoxDecoration(
                color: CRMColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                border: Border.all(color: CRMColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: CRMColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAdmin
                          ? "This profile was created & authorized by the workspace Super Administrator."
                          : "This sales user account was added & onboarded by the Administrator shown above.",
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textOf(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
