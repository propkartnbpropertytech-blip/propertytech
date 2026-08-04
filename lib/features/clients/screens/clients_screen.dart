import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/clients_bloc.dart';
import '../models/client_model.dart';
import 'add_edit_client_screen.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/dialogs.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStage = "All";
  String _selectedSource = "All";
  bool _isPipelineView = true; // Board vs Table toggle

  @override
  void initState() {
    super.initState();
    _triggerFetch();
  }

  void _triggerFetch() {
    context.read<ClientsBloc>().add(
          FetchClientsEvent(
            search: _searchController.text.trim(),
            stage: _selectedStage,
            source: _selectedSource,
          ),
        );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStage = "All";
      _selectedSource = "All";
    });
    _triggerFetch();
  }

  void _showAddEditDialog([ClientModel? client]) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditClientScreen(
        client: client,
        onSaved: () {
          _triggerFetch();
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(ClientModel client) async {
    final confirmed = await CRMDialogs.showDeleteConfirmation(
      context,
      title: "Delete Client Profile",
      content: "Are you sure you want to delete ${client.name}? This will permanently remove their profile.",
    );
    if (confirmed == true && mounted) {
      context.read<ClientsBloc>().add(DeleteClientEvent(client.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<ClientsBloc, ClientsState>(
        listener: (context, state) {
          if (state is ClientsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: CRMColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _triggerFetch();
          } else if (state is ClientsError) {
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

              // KPI Stats
              _buildStatsGrid(),
              const SizedBox(height: CRMSpacing.l),

              // Filters & Toggle Bar
              _buildSearchAndFiltersCard(),
              const SizedBox(height: CRMSpacing.l),

              // Active View (Board / Table)
              _isPipelineView ? _buildPipelineBoard() : _buildClientsTable(),
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
              "Clients & Leads",
              style: CRMTypography.pageTitle.copyWith(color: CRMColors.text),
            ),
            const SizedBox(height: 4.0),
            Text(
              "Track pipeline stages, target source channels, and conversions",
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
            ),
          ],
        ),
        CRMButton(
          label: "Add Client",
          prefixIcon: Icons.person_add_rounded,
          onPressed: () => _showAddEditDialog(),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return BlocBuilder<ClientsBloc, ClientsState>(
      builder: (context, state) {
        int total = 0;
        int pipeline = 0;
        int won = 0;

        if (state is ClientsLoaded) {
          total = state.clients.length;
          pipeline = state.clients.where((c) => c.stage != 'Won' && c.stage != 'Lost').length;
          won = state.clients.where((c) => c.stage == 'Won').length;
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
                  title: "TOTAL CUSTOMERS",
                  value: total.toString(),
                  icon: Icons.people_rounded,
                  iconColor: CRMColors.primary,
                ),
                CRMKPICard(
                  title: "ACTIVE PIPELINE DEALS",
                  value: pipeline.toString(),
                  icon: Icons.bubble_chart_rounded,
                  iconColor: CRMColors.info,
                ),
                CRMKPICard(
                  title: "DEALS CONVERTED (WON)",
                  value: won.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: CRMColors.success,
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
                    hintText: 'Search by client name, email, mobile, comments...',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filters wrap
              Expanded(
                child: Wrap(
                  spacing: CRMSpacing.m,
                  runSpacing: CRMSpacing.s,
                  children: [
                    _buildDropdownFilter(
                      label: 'Pipeline Stage',
                      value: _selectedStage,
                      items: ["All", "Lead", "Contacted", "Site Visit", "Negotiation", "Won", "Lost"].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedStage = val ?? "All");
                        _triggerFetch();
                      },
                    ),
                    _buildDropdownFilter(
                      label: 'Lead Source',
                      value: _selectedSource,
                      items: ["All", "Call", "Referral", "Website", "Ads", "WhatsApp"].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedSource = val ?? "All");
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
              ),
              
              // View toggle segment control style
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: CRMColors.backgroundOf(context),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleOption(icon: Icons.grid_view_rounded, isSelected: _isPipelineView, onTap: () => setState(() => _isPipelineView = true)),
                    _buildToggleOption(icon: Icons.list_alt_rounded, isSelected: !_isPipelineView, onTap: () => setState(() => _isPipelineView = false)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? CRMColors.cardBgOf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
          boxShadow: isSelected ? CRMShadows.soft : null,
        ),
        child: Icon(icon, color: isSelected ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context), size: 20),
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
      width: 180,
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

  Widget _buildPipelineBoard() {
    return BlocBuilder<ClientsBloc, ClientsState>(
      builder: (context, state) {
        if (state is ClientsLoading || state is ClientsInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        List<ClientModel> clients = [];
        if (state is ClientsLoaded) {
          clients = state.clients;
        }

        final List<String> stages = ["Lead", "Contacted", "Site Visit", "Negotiation", "Won"];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            
            Widget boardBody = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stages.map((stage) {
                final stageClients = clients.where((c) => c.stage == stage).toList();
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: CRMSpacing.m),
                    decoration: BoxDecoration(
                      color: CRMColors.sidebarBgOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.l),
                      border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
                    ),
                    padding: const EdgeInsets.all(CRMSpacing.s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Column header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(stage.toUpperCase(), style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xs, vertical: 2),
                              decoration: BoxDecoration(color: CRMColors.borderOf(context).withOpacity(0.6), borderRadius: BorderRadius.circular(10)),
                              child: Text('${stageClients.length}', style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context))),
                            ),
                          ],
                        ),
                        Divider(height: CRMSpacing.m, color: CRMColors.borderOf(context).withOpacity(0.5)),
                        
                        // Cards scroll list
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 150, maxHeight: 500),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: stageClients.length,
                            itemBuilder: (context, index) {
                              final c = stageClients[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: CRMSpacing.xs),
                                decoration: BoxDecoration(
                                  color: CRMColors.cardBgOf(context),
                                  borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                                  border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
                                  boxShadow: CRMShadows.soft,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(CRMSpacing.m),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.name,
                                              style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined, size: 16, color: CRMColors.primary),
                                            onPressed: () => _showAddEditDialog(c),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(c.mobile, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                                      const SizedBox(height: CRMSpacing.s),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xs, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: CRMColors.primary.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(c.source, style: CRMTypography.captionBold.copyWith(fontSize: 10, color: CRMColors.primary)),
                                          ),
                                          DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: c.stage,
                                              dropdownColor: CRMColors.cardBg,
                                              style: CRMTypography.caption.copyWith(color: CRMColors.text),
                                              items: stages.map((st) {
                                                return DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 11)));
                                              }).toList(),
                                              onChanged: (newStage) {
                                                if (newStage != null && newStage != c.stage) {
                                                  context.read<ClientsBloc>().add(UpdateClientEvent(c.copyWith(stage: newStage)));
                                                }
                                              },
                                            ),
                                          ),
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
                  ),
                );
              }).toList(),
            );

            return isWide
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 1200,
                        maxWidth: constraints.maxWidth > 1200 ? constraints.maxWidth : 1200,
                      ),
                      child: boardBody,
                    ),
                  )
                : SingleChildScrollView(child: Column(children: stages.map((st) {
                    final stageClients = clients.where((c) => c.stage == st).toList();
                    return Container(
                      margin: const EdgeInsets.only(bottom: CRMSpacing.m),
                      decoration: BoxDecoration(
                        color: CRMColors.sidebarBgOf(context),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.l),
                        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
                      ),
                      padding: const EdgeInsets.all(CRMSpacing.m),
                      child: ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(st, style: CRMTypography.bodyMedium),
                            Text('(${stageClients.length})', style: CRMTypography.captionBold),
                          ],
                        ),
                        children: stageClients.map((c) => ListTile(
                          title: Text(c.name),
                          subtitle: Text(c.mobile),
                          trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showAddEditDialog(c)),
                        )).toList(),
                      ),
                    );
                  }).toList()));
          },
        );
      },
    );
  }

  Widget _buildClientsTable() {
    return BlocBuilder<ClientsBloc, ClientsState>(
      builder: (context, state) {
        final isLoading = state is ClientsLoading || state is ClientsInitial;
        List<ClientModel> clients = [];

        if (state is ClientsLoaded) {
          clients = state.clients;
        }

        return CRMDataTable(
          isLoading: isLoading,
          emptyTitle: 'No Clients Profile Found',
          emptyDescription: 'Adjust search filter parameters or add a new customer.',
          columns: const [
            DataColumn(label: Text('Client Name')),
            DataColumn(label: Text('Mobile')),
            DataColumn(label: Text('Email Address')),
            DataColumn(label: Text('Pipeline Stage')),
            DataColumn(label: Text('Acquisition Source')),
            DataColumn(label: Text('Assigned Representative')),
            DataColumn(label: Text('Actions')),
          ],
          rows: clients.map((c) {
            return DataRow(
              cells: [
                DataCell(Text(c.name, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text))),
                DataCell(Text(c.mobile, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(Text(c.email, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                    decoration: BoxDecoration(
                      color: CRMColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                    ),
                    child: Text(
                      c.stage,
                      style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
                    ),
                  ),
                ),
                DataCell(Text(c.source, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(Text(c.assignedAgent ?? '-', style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 18),
                        onPressed: () => _showAddEditDialog(c),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                        onPressed: () => _showDeleteConfirmDialog(c),
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
