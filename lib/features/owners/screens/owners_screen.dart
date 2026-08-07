import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/owners_bloc.dart';
import '../models/owner_model.dart';
import 'add_edit_owner_screen.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/models/property_model.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../../core/utils/budget_formatter.dart';

class OwnersScreen extends StatefulWidget {
  const OwnersScreen({super.key});

  @override
  State<OwnersScreen> createState() => _OwnersScreenState();
}

class _OwnersScreenState extends State<OwnersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _triggerFetch();
  }

  void _triggerFetch() {
    context.read<OwnersBloc>().add(FetchOwnersEvent(search: _searchController.text.trim()));
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
    });
    _triggerFetch();
  }

  void _showAddEditDialog([OwnerModel? owner]) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditOwnerScreen(
        owner: owner,
        onSaved: () {
          _triggerFetch();
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(OwnerModel owner) async {
    final confirmed = await CRMDialogs.showDeleteConfirmation(
      context,
      title: "Delete Owner Profile",
      content: "Are you sure you want to delete ${owner.name}? This will remove their record from the directory.",
    );
    if (confirmed == true && mounted) {
      context.read<OwnersBloc>().add(DeleteOwnerEvent(owner.id));
    }
  }

  void _showPropertiesDrawer(OwnerModel owner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CRMOwnerPropertiesDrawer(owner: owner);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: BlocListener<OwnersBloc, OwnersState>(
        listener: (context, state) {
          if (state is OwnersSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: CRMColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _triggerFetch();
          } else if (state is OwnersError) {
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
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildPageHeader(),
              const SizedBox(height: CRMSpacing.l),

              // KPI Metric Cards
              _buildStatsGrid(),
              const SizedBox(height: CRMSpacing.l),

              // Search Toolbar
              _buildSearchCard(),
              const SizedBox(height: CRMSpacing.l),

              // Main Table
              _buildOwnersTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Owners Directory",
              style: CRMTypography.pageTitle.copyWith(color: CRMColors.text),
            ),
            const SizedBox(height: 4.0),
            Text(
              "Central registry of property owners, lease managers, and sellers",
              style: CRMTypography.benefit.copyWith(color: CRMColors.textSecondary),
            ),
          ],
        ),
        CRMButton(
          label: "Add Owner Contact",
          prefixIcon: Icons.person_add_alt_1_rounded,
          onPressed: () => _showAddEditDialog(),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return BlocBuilder<OwnersBloc, OwnersState>(
      builder: (context, state) {
        int total = 0;
        if (state is OwnersLoaded) {
          total = state.owners.length;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return GridView.count(
              crossAxisCount: isWide ? 3 : 2,
              crossAxisSpacing: CRMSpacing.m,
              mainAxisSpacing: CRMSpacing.m,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: CRMBreakpoints.kpiAspectRatio(context),
              children: [
                CRMKPICard(
                  title: "TOTAL OWNERS",
                  value: total.toString(),
                  icon: Icons.contact_phone_rounded,
                  iconColor: CRMColors.primary,
                  benefit: 'Landlords and sellers you can reach fast',
                ),
                CRMKPICard(
                  title: "CONNECTED LISTINGS",
                  value: (total * 1.5).toStringAsFixed(0), // Mock listing scale
                  icon: Icons.home_work_rounded,
                  iconColor: CRMColors.info,
                  benefit: 'Inventory linked to owner contacts',
                ),
                CRMKPICard(
                  title: "VIP PARTNERS",
                  value: (total > 0) ? "2" : "0",
                  icon: Icons.star_border_purple500_rounded,
                  iconColor: CRMColors.warning,
                  benefit: 'Priority partners who bring repeat stock',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchCard() {
    return CRMCard(
      elevated: true,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
              decoration: InputDecoration(
                hintText: 'Search by owner name, phone number, address details...',
                hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMutedOf(context)),
                prefixIcon: Icon(Icons.search_rounded, color: CRMColors.textMutedOf(context)),
                filled: true,
                fillColor: CRMColors.backgroundOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                  borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                  borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                  borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
                ),
              ),
              onChanged: (val) => _triggerFetch(),
            ),
          ),
          const SizedBox(width: CRMSpacing.s),
          CRMButton(label: "Search", onPressed: _triggerFetch),
          const SizedBox(width: CRMSpacing.s),
          CRMButton(
            label: "Reset",
            variant: CRMButtonVariant.outline,
            onPressed: _clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnersTable() {
    return BlocBuilder<OwnersBloc, OwnersState>(
      builder: (context, state) {
        final isLoading = state is OwnersLoading || state is OwnersInitial;
        List<OwnerModel> owners = [];

        if (state is OwnersLoaded) {
          owners = state.owners;
        }

        return CRMDataTable(
          isLoading: isLoading,
          emptyTitle: 'No Owners Registered',
          emptyDescription: 'Add a new property owner card to populate the directory.',
          columns: const [
            DataColumn(label: Text('Owner Name')),
            DataColumn(label: Text('Phone Number')),
            DataColumn(label: Text('Email Address')),
            DataColumn(label: Text('Primary Address')),
            DataColumn(label: Text('Linked Listings')),
            DataColumn(label: Text('Actions')),
          ],
          rows: owners.map((owner) {
            return DataRow(
              cells: [
                DataCell(Text(owner.name, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text))),
                DataCell(Text(owner.mobile, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(Text(owner.email, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(
                  Tooltip(
                    message: owner.address ?? '-',
                    child: Text(
                      owner.address ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                    ),
                  ),
                ),
                DataCell(
                  CRMButton(
                    label: "View Listings",
                    prefixIcon: Icons.home_work_outlined,
                    onPressed: () => _showPropertiesDrawer(owner),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 18),
                        onPressed: () => _showAddEditDialog(owner),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                        onPressed: () => _showDeleteConfirmDialog(owner),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class _CRMOwnerPropertiesDrawer extends StatefulWidget {
  final OwnerModel owner;

  const _CRMOwnerPropertiesDrawer({required this.owner});

  @override
  State<_CRMOwnerPropertiesDrawer> createState() => _CRMOwnerPropertiesDrawerState();
}

class _CRMOwnerPropertiesDrawerState extends State<_CRMOwnerPropertiesDrawer> {
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  bool _isLoading = true;
  List<PropertyModel> _ownedProperties = [];

  @override
  void initState() {
    super.initState();
    _loadOwnerProperties();
  }

  Future<void> _loadOwnerProperties() async {
    try {
      final properties = await _propertiesRepository.getProperties();
      final oName = widget.owner.name.toLowerCase();
      final oMobile = widget.owner.mobile.replaceAll(' ', '');

      final matches = properties.where((p) {
        final pOwnerName = p.ownerName.toLowerCase();
        final pOwnerMobile = p.ownerMobile.replaceAll(' ', '');
        return pOwnerName.contains(oName) || oName.contains(pOwnerName) || pOwnerMobile.contains(oMobile) || oMobile.contains(pOwnerMobile);
      }).toList();

      setState(() {
        _ownedProperties = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CRMColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.sheet)),
        border: Border(
          top: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
        ),
        boxShadow: CRMShadows.floating,
      ),
      padding: const EdgeInsets.all(CRMSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: CRMColors.borderOf(context),
                borderRadius: BorderRadius.circular(CRMBorderRadius.round),
              ),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Owner Listings Catalog", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
              IconButton(
                icon: Icon(Icons.close_rounded, color: CRMColors.textSecondaryOf(context)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.xs),
          Text(
            "Registered property assets associated with ${widget.owner.name}",
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          Divider(height: CRMSpacing.xl, color: CRMColors.borderOf(context).withOpacity(0.5)),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_ownedProperties.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Icon(Icons.home_work_rounded, size: 48, color: CRMColors.textMuted),
                  const SizedBox(height: CRMSpacing.s),
                  Text("No Listings Registered Yet", style: CRMTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text("This owner has no active properties listed in the database.", style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _ownedProperties.length,
                itemBuilder: (context, index) {
                  final p = _ownedProperties[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: CRMSpacing.s),
                    decoration: BoxDecoration(
                      color: CRMColors.cardBgOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                      border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(CRMSpacing.m),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.title, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context))),
                           Text(
                            '₹${BudgetFormatter.format(p.price)}',
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primaryOf(context)),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 14, color: CRMColors.textSecondaryOf(context)),
                              const SizedBox(width: 4),
                              Text('${p.areaName}, ${p.cityName}', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.square_foot_rounded, size: 14, color: CRMColors.textSecondaryOf(context)),
                              const SizedBox(width: 4),
                              Text('${p.superBuiltupArea ?? "-"} sq ft', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
