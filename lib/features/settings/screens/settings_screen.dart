import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../modules/config/services/config_service.dart';
import '../../../modules/version/presentation/update_dialogs.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/theme/theme_presets.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'sync_debug_screen.dart';
import '../../../core/storage/isar_service.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ConfigService _configService = ConfigService();
  bool _isLoading = false;
  String _activeSection = 'profile';

  @override
  void initState() {
    super.initState();
    ThemeManager().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildProfileCard(String name, String email) {
    return CRMCard(
      elevated: true,
      title: 'Profile',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: CRMColors.primary.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: CRMTypography.sectionTitle.copyWith(
                      color: CRMColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: CRMSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: CRMTypography.bodyMedium.copyWith(
                          color: CRMColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.l),
            InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              child: Container(
                padding: const EdgeInsets.all(CRMSpacing.m),
                decoration: BoxDecoration(
                  color: CRMColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: CRMColors.primary, size: 20),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(
                      child: Text(
                        'Edit & View Profile Details',
                        style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: CRMColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(bool isAdminOrSuperAdmin) {
    final isDark = ThemeManager().isDarkMode;
    final currentTheme = ThemeManager().currentTheme;
    return CRMCard(
      title: 'Appearance',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.xs),
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Application Theme',
                style: CRMTypography.bodyMedium.copyWith(
                  color: CRMColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${currentTheme.name}${currentTheme.isDefault ? " (Default)" : ""}',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
              ),
              leading: Icon(Icons.palette_rounded, color: CRMColors.primary),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CRMColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.badge),
                    ),
                    child: Text(
                      currentTheme.isDefault ? 'DEFAULT' : 'ACTIVE',
                      style: CRMTypography.captionBold.copyWith(
                        fontSize: 10,
                        color: CRMColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: CRMColors.textSecondary),
                ],
              ),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                setState(() => _activeSection = 'themes');
              },
            ),
            const Divider(height: CRMSpacing.m),
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: CRMTypography.bodyMedium.copyWith(
                  color: CRMColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Light or dark theme',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
              ),
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? CRMColors.primary : CRMColors.textSecondary,
              ),
              value: isDark,
              activeColor: CRMColors.primary,
              onChanged: (val) {
                ThemeManager().toggleTheme();
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (isAdminOrSuperAdmin) ...[
              const Divider(height: CRMSpacing.l),
              ListTile(
                title: Text(
                  'Sync Diagnostics',
                  style: CRMTypography.bodyMedium.copyWith(
                    color: CRMColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Network logs and outbox',
                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                ),
                leading: Icon(Icons.sync_rounded, color: CRMColors.primary),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: CRMColors.textSecondary),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SyncDebugScreen()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemesSection({bool isSuperAdmin = false}) {
    final themeManager = ThemeManager();
    final availableThemes = themeManager.availableThemes;
    final currentTheme = themeManager.currentTheme;
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CRMCard(
          elevated: true,
          title: 'Themes & Visual Styles',
          child: Padding(
            padding: const EdgeInsets.only(top: CRMSpacing.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSuperAdmin) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Super Administrator Theme Control',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: CRMColors.textOf(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select a theme and click "Make it as Default" to make it the default theme for anyone who visits the site or app.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CRMColors.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                ],
                Text(
                  'Personalize the look and feel of PropKart. As new UI designs are added, they will appear here for one-click switching.',
                  style: CRMTypography.body.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: CRMSpacing.l),
                for (final theme in availableThemes) ...[
                  _buildThemeCard(
                    theme,
                    isSelected: theme.id == currentTheme.id,
                    isSystemDefault: themeManager.isSystemDefault(theme.id),
                    isSuperAdmin: isSuperAdmin,
                    isDark: isDark,
                  ),
                  const SizedBox(height: CRMSpacing.m),
                ],
                _buildUpcomingThemeTeaserCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(
    AppThemePreset theme, {
    required bool isSelected,
    required bool isSystemDefault,
    required bool isSuperAdmin,
    required bool isDark,
  }) {
    final primaryColor = isDark ? theme.primaryDark : theme.primaryLight;

    return InkWell(
      onTap: () => ThemeManager().setTheme(theme.id),
      borderRadius: BorderRadius.circular(CRMBorderRadius.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(CRMSpacing.m),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.15 : 0.06)
              : CRMColors.groupedBackground,
          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          border: Border.all(
            color: isSelected ? primaryColor : CRMColors.borderOf(context),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_rounded : Icons.palette_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: CRMSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            theme.name,
                            style: CRMTypography.bodyMedium.copyWith(
                              color: CRMColors.textOf(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isSystemDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF159B73).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(
                                  CRMBorderRadius.badge,
                                ),
                                border: Border.all(
                                  color: const Color(0xFF159B73).withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 11,
                                    color: Color(0xFF159B73),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'SYSTEM DEFAULT',
                                    style: CRMTypography.captionBold.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 0.6,
                                      color: const Color(0xFF159B73),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(
                                  CRMBorderRadius.badge,
                                ),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: CRMTypography.captionBold.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 0.6,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        theme.description,
                        style: CRMTypography.caption.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            const Divider(height: 1),
            const SizedBox(height: CRMSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Palette Preview',
                      style: CRMTypography.captionBold.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        for (int i = 0; i < theme.previewColors.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: theme.previewColors[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (isSuperAdmin && !isSystemDefault)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ThemeManager().setSystemDefaultTheme(theme.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Theme "${theme.name}" is now set as the system default for all visitors!',
                            ),
                            backgroundColor: const Color(0xFF159B73),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.star_rounded, size: 14),
                    label: const Text(
                      'Make it as default',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingThemeTeaserCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: CRMColors.borderOf(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: CRMColors.textMutedOf(context).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              color: CRMColors.textMutedOf(context),
              size: 20,
            ),
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready for Your Next UI Theme',
                  style: CRMTypography.bodyMedium.copyWith(
                    color: CRMColors.textOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Provide your upcoming UI theme and we will gradually register it here for seamless theme switching.',
                  style: CRMTypography.caption.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return CRMCard(
      title: 'About',
      child: FutureBuilder<AppConfigModel>(
        future: _configService.fetchAppConfig(),
        builder: (context, configSnapshot) {
          final serverVersion = configSnapshot.data?.maxVersion;
          return FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final rawVersion = snapshot.data?.version;
              final version = (rawVersion != null && rawVersion.isNotEmpty && rawVersion != '1.0.0' && rawVersion != '1.1.1' && rawVersion != '1.1.4')
                  ? rawVersion
                  : (serverVersion ?? AppConstants.appVersion);
              final rawBuild = snapshot.data?.buildNumber;
              final buildNumber = (rawBuild != null && rawBuild.isNotEmpty && rawBuild != '1' && rawBuild != '3' && rawBuild != '6')
                  ? rawBuild
                  : AppConstants.buildNumber;

              return FutureBuilder<String>(
                future: _configService.getLastCheckedTime(),
                builder: (context, lastCheckedSnapshot) {
                  final lastChecked = lastCheckedSnapshot.data ?? 'Never Checked';

                  return Padding(
                    padding: const EdgeInsets.only(top: CRMSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAboutRow('App Version', version),
                        const Divider(height: CRMSpacing.m),
                        _buildAboutRow('Build Number', buildNumber),
                        const Divider(height: CRMSpacing.m),
                        _buildAboutRow('Last Checked', lastChecked),
                        const SizedBox(height: CRMSpacing.l),
                        CRMButton(
                          label: 'Check for Updates',
                          onPressed: () => _checkForUpdates(context),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: CRMTypography.bodyMedium.copyWith(
            color: CRMColors.textOf(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: CRMTypography.body.copyWith(
            color: CRMColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    try {
      final config = await _configService.fetchAppConfig();
      if (mounted) {
        setState(() {}); // refresh "Last Checked"
        
        if (config.versionStatus == "forceUpdate" || config.versionStatus == "softUpdate") {
          showDialog(
            context: context,
            builder: (dialogContext) => UpdateDialog(
              isForceUpdate: config.versionStatus == "forceUpdate",
              androidLink: config.androidLink,
              iosLink: config.iosLink,
              onDismiss: () => Navigator.pop(dialogContext),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your application is up to date.'),
              backgroundColor: CRMColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            backgroundColor: CRMColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildAuditLogsCard() {
    return CRMCard(
      title: 'Audit Logs',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.xs),
        child: ListTile(
          title: Text(
            'System Activity Audit Logs',
            style: CRMTypography.bodyMedium.copyWith(
              color: CRMColors.textOf(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'User actions and entity changes',
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          leading: CircleAvatar(
            backgroundColor: CRMColors.primary.withOpacity(0.1),
            radius: 18,
            child: Icon(Icons.history_rounded, color: CRMColors.primary, size: 20),
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: CRMColors.textSecondaryOf(context)),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            context.go('/settings/audit-logs');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    final authState = context.watch<AuthBloc>().state;
    String currentUserName = 'Guest';
    String currentUserEmail = '';
    bool isAdminOrSuperAdmin = false;
    bool isSuperAdmin = false;

    if (authState is Authenticated) {
      currentUserEmail = authState.user.email;
      final roleLower = authState.user.role.toLowerCase();
      isAdminOrSuperAdmin = roleLower.contains('admin');
      isSuperAdmin = roleLower == 'super admin';
      currentUserName = authState.user.fullName;
    }

    final sections = <_SettingsNavItem>[
      const _SettingsNavItem(id: 'profile', label: 'Profile', icon: Icons.person_outline_rounded),
      const _SettingsNavItem(id: 'themes', label: 'Themes', icon: Icons.palette_outlined),
      const _SettingsNavItem(id: 'appearance', label: 'Appearance', icon: Icons.tune_rounded),
      const _SettingsNavItem(id: 'locations', label: 'Locations', icon: Icons.location_city_outlined),
      if (isSuperAdmin)
        const _SettingsNavItem(id: 'audit', label: 'Audit Logs', icon: Icons.history_rounded),
      const _SettingsNavItem(id: 'system', label: 'System', icon: Icons.info_outline_rounded),
    ];

    if (!sections.any((s) => s.id == _activeSection)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeSection = 'profile');
      });
    }

    Widget sectionContent() {
      switch (_activeSection) {
        case 'themes':
          return _buildThemesSection(isSuperAdmin: isSuperAdmin);
        case 'appearance':
          return _buildAppearanceCard(isAdminOrSuperAdmin);
        case 'locations':
          return _buildLocationConfigCard();
        case 'audit':
          return _buildAuditLogsCard();
        case 'system':
          return Column(
            children: [
              _buildAboutCard(),
              if (isSuperAdmin) ...[
                const SizedBox(height: CRMSpacing.l),
                _buildDiagnosticsCard(),
              ],
            ],
          );
        case 'profile':
        default:
          return _buildProfileCard(currentUserName, currentUserEmail);
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(CRMSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CRMPageHeader(title: 'Settings'),
                  const SizedBox(height: CRMSpacing.l),
                  if (isMobile)
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: sections.length,
                              separatorBuilder: (_, __) => const SizedBox(width: CRMSpacing.xs),
                              itemBuilder: (context, index) {
                                final item = sections[index];
                                final selected = item.id == _activeSection;
                                return ChoiceChip(
                                  label: Text(item.label),
                                  selected: selected,
                                  onSelected: (_) => setState(() => _activeSection = item.id),
                                  selectedColor: CRMColors.primary.withValues(alpha: 0.12),
                                  labelStyle: CRMTypography.captionBold.copyWith(
                                    color: selected ? CRMColors.primary : CRMColors.textSecondaryOf(context),
                                  ),
                                  side: BorderSide(
                                    color: selected ? CRMColors.primary.withValues(alpha: 0.35) : CRMColors.borderOf(context),
                                  ),
                                  backgroundColor: CRMColors.cardBgOf(context),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          Expanded(
                            child: SingleChildScrollView(child: sectionContent()),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 220,
                            child: CRMCard(
                              padding: const EdgeInsets.symmetric(vertical: CRMSpacing.s),
                              child: Column(
                                children: [
                                  for (final item in sections)
                                    _buildSettingsNavTile(item),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: CRMSpacing.l),
                          Expanded(
                            child: SingleChildScrollView(child: sectionContent()),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsNavTile(_SettingsNavItem item) {
    final selected = item.id == _activeSection;
    return InkWell(
      onTap: () => setState(() => _activeSection = item.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? CRMColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: selected ? CRMColors.primary : CRMColors.textMutedOf(context),
            ),
            const SizedBox(width: CRMSpacing.s),
            Text(
              item.label,
              style: CRMTypography.bodyMedium.copyWith(
                color: selected ? CRMColors.primary : CRMColors.textOf(context),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationConfigCard() {
    return CRMCard(
      title: 'Locations',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.xs),
        child: ListTile(
          title: Text(
            'City & Area Configurations',
            style: CRMTypography.bodyMedium.copyWith(
              color: CRMColors.textOf(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Cities, areas, and pincodes',
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          leading: CircleAvatar(
            backgroundColor: CRMColors.primary.withOpacity(0.08),
            radius: 18,
            child: Icon(Icons.location_city_rounded, color: CRMColors.primary, size: 20),
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: CRMColors.textSecondaryOf(context)),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            context.go('/settings/location-config');
          },
        ),
      ),
    );
  }

  Widget _buildDiagnosticsCard() {
    return CRMCard(
      title: 'System',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CRMButton(
              label: 'Verify Sentry Setup',
              onPressed: () {
                throw StateError('This is test exception to verify Sentry Setup');
              },
            ),
            const SizedBox(height: CRMSpacing.m),
            CRMButton(
              label: 'Test Isar Database',
              onPressed: () async {
                try {
                  await IsarService().initialize();
                  final isarInstance = IsarService().isar;
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Isar DB initialized successfully! Path: ${isarInstance.path}'),
                        backgroundColor: CRMColors.success,
                      ),
                    );
                  }
                } catch (e, stack) {
                  debugPrint('🚨 Isar initialization diagnostics failed: $e');
                  debugPrint(stack.toString());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Isar DB initialization failed: $e'),
                        backgroundColor: CRMColors.danger,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ThemeManager().removeListener(_onThemeChanged);
    super.dispose();
  }
}

class _SettingsNavItem {
  final String id;
  final String label;
  final IconData icon;

  const _SettingsNavItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
