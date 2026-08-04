import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/builders_bloc.dart';
import '../models/builder_model.dart';
import 'add_edit_builder_screen.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/dialogs.dart';

class BuildersScreen extends StatefulWidget {
  const BuildersScreen({super.key});

  @override
  State<BuildersScreen> createState() => _BuildersScreenState();
}

class _BuildersScreenState extends State<BuildersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTier = "All";

  @override
  void initState() {
    super.initState();
    _triggerFetch();
  }

  void _triggerFetch() {
    context.read<BuildersBloc>().add(
          FetchBuildersEvent(
            search: _searchController.text.trim(),
            tier: _selectedTier,
          ),
        );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedTier = "All";
    });
    _triggerFetch();
  }

  void _showAddEditDialog([BuilderModel? builder]) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditBuilderScreen(
        builder: builder,
        onSaved: () {
          _triggerFetch();
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(BuilderModel builder) async {
    final confirmed = await CRMDialogs.showDeleteConfirmation(
      context,
      title: "Delete Builder Profile",
      content: "Are you sure you want to delete ${builder.companyName}? This will remove their record from active partnerships.",
    );
    if (confirmed == true && mounted) {
      context.read<BuildersBloc>().add(DeleteBuilderEvent(builder.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: BlocListener<BuildersBloc, BuildersState>(
        listener: (context, state) {
          if (state is BuildersSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: CRMColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _triggerFetch();
          } else if (state is BuildersError) {
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

              // Search & Filters Card
              _buildSearchAndFiltersCard(),
              const SizedBox(height: CRMSpacing.l),

              // Main Table
              _buildBuildersTable(),
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
              "Builders & Developers",
              style: CRMTypography.pageTitle.copyWith(color: CRMColors.text),
            ),
            const SizedBox(height: 4.0),
            Text(
              "Central registry of construction firms, developer representatives, and projects",
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
            ),
          ],
        ),
        CRMButton(
          label: "Add Developer Group",
          prefixIcon: Icons.add_business_rounded,
          onPressed: () => _showAddEditDialog(),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return BlocBuilder<BuildersBloc, BuildersState>(
      builder: (context, state) {
        int total = 0;
        int tier1 = 0;
        if (state is BuildersLoaded) {
          total = state.builders.length;
          tier1 = state.builders.where((b) => b.tier == 'Tier 1').length;
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
              childAspectRatio: isWide ? 2.5 : 1.5,
              children: [
                CRMKPICard(
                  title: "DEVELOPER PARTNERS",
                  value: total.toString(),
                  icon: Icons.business_rounded,
                  iconColor: CRMColors.primary,
                ),
                CRMKPICard(
                  title: "TIER 1 ORGANIZATIONS",
                  value: tier1.toString(),
                  icon: Icons.verified_user_rounded,
                  iconColor: CRMColors.success,
                ),
                CRMKPICard(
                  title: "ACTIVE SITES",
                  value: (total * 2).toString(), // Mock project scale
                  icon: Icons.foundation_rounded,
                  iconColor: CRMColors.info,
                ),
              ],
            );
          },
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
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    hintText: 'Search by developer company, contact person, project names...',
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
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Wrap(
            spacing: CRMSpacing.m,
            runSpacing: CRMSpacing.s,
            children: [
              _buildDropdownFilter(
                label: 'Developer Tier Rank',
                value: _selectedTier,
                items: ["All", "Tier 1", "Tier 2", "Tier 3"].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedTier = val ?? "All");
                  _triggerFetch();
                },
              ),
              CRMButton(
                label: "Clear Filters",
                variant: CRMButtonVariant.outline,
                onPressed: _clearFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 220,
      height: 44,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        dropdownColor: CRMColors.cardBgOf(context),
        style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 4),
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
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBuildersTable() {
    return BlocBuilder<BuildersBloc, BuildersState>(
      builder: (context, state) {
        final isLoading = state is BuildersLoading || state is BuildersInitial;
        List<BuilderModel> builders = [];

        if (state is BuildersLoaded) {
          builders = state.builders;
        }

        return CRMDataTable(
          isLoading: isLoading,
          emptyTitle: 'No Developers Registered',
          emptyDescription: 'Adjust search filter parameters or add a developer profile.',
          columns: const [
            DataColumn(label: Text('Developer Group')),
            DataColumn(label: Text('Contact Person')),
            DataColumn(label: Text('Contact Phone')),
            DataColumn(label: Text('Email Address')),
            DataColumn(label: Text('Ongoing Projects')),
            DataColumn(label: Text('Tier Rank')),
            DataColumn(label: Text('Actions')),
          ],
          rows: builders.map((bld) {
            final isTier1 = bld.tier == 'Tier 1';
            return DataRow(
              cells: [
                DataCell(Text(bld.companyName, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text))),
                DataCell(Text(bld.contactPerson, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(Text(bld.mobile, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(Text(bld.email, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(
                  Tooltip(
                    message: bld.activeProjects.join(', '),
                    child: Text(
                      bld.activeProjects.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                    decoration: BoxDecoration(
                      color: isTier1 ? CRMColors.warning.withOpacity(0.12) : CRMColors.textMuted.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                    ),
                    child: Text(
                      bld.tier,
                      style: CRMTypography.captionBold.copyWith(
                        color: isTier1 ? CRMColors.warning : CRMColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 18),
                        onPressed: () => _showAddEditDialog(bld),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                        onPressed: () => _showDeleteConfirmDialog(bld),
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
