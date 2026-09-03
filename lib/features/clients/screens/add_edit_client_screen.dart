import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/clients_bloc.dart';
import '../models/client_model.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/inputs.dart';

class AddEditClientScreen extends StatefulWidget {
  final ClientModel? client;
  final VoidCallback onSaved;

  const AddEditClientScreen({
    super.key,
    this.client,
    required this.onSaved,
  });

  @override
  State<AddEditClientScreen> createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _agentController = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedStage = "Lead";
  String _selectedSource = "Call";

  @override
  void initState() {
    super.initState();
    if (widget.client != null) {
      final c = widget.client!;
      _nameController.text = c.name;
      _emailController.text = c.email;
      _mobileController.text = c.mobile;
      _agentController.text = c.assignedAgent ?? '';
      _remarksController.text = c.remarks ?? '';
      _selectedStage = c.stage;
      _selectedSource = c.source;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _agentController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final client = ClientModel(
      id: widget.client?.id ?? '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      stage: _selectedStage,
      source: _selectedSource,
      assignedAgent: _agentController.text.trim().isEmpty ? null : _agentController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      createdAt: widget.client?.createdAt ?? DateTime.now(),
    );

    if (widget.client == null) {
      context.read<ClientsBloc>().add(CreateClientEvent(client));
    } else {
      context.read<ClientsBloc>().add(UpdateClientEvent(client));
    }

    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;

    return Dialog(
      backgroundColor: CRMColors.surfaceElevatedOf(context),
      elevation: 8,
      shadowColor: CRMColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
        side: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? "Edit Client Profile" : "Register Prospect Lead",
                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                  ),
                  const SizedBox(height: CRMSpacing.xs),
                  Text(
                    "Setup contact information and update pipeline sales funnel status",
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                  ),
                  const SizedBox(height: CRMSpacing.l),

                  // Full Name
                  CRMTextField(
                    controller: _nameController,
                    labelText: 'Client Full Name *',
                    hintText: 'Enter name',
                    prefixIcon: Icons.person_rounded,
                    validator: (v) => v == null || v.isEmpty ? 'Client name is required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Email
                  CRMTextField(
                    controller: _emailController,
                    labelText: 'Email Address *',
                    hintText: 'client@example.com',
                    prefixIcon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Email address is required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Mobile
                  CRMTextField(
                    controller: _mobileController,
                    labelText: 'Mobile Phone *',
                    hintText: '+91 XXXXX XXXXX',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Mobile number is required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Stage & Source Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Pipeline Stage *',
                          value: _selectedStage,
                          items: ["Lead", "Contacted", "Site Visit", "Negotiation", "Won", "Lost"].map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedStage = val ?? "Lead"),
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.m),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Acquisition Source *',
                          value: _selectedSource,
                          items: ["Call", "Referral", "Website", "Ads", "WhatsApp"].map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedSource = val ?? "Call"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Assigned Agent
                  CRMTextField(
                    controller: _agentController,
                    labelText: 'Assigned Agent Representative',
                    hintText: 'e.g. Agent Name',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Remarks
                  CRMTextField(
                    controller: _remarksController,
                    labelText: 'Internal CRM Remarks',
                    hintText: 'Add summary notes or background context...',
                    prefixIcon: Icons.note_add_outlined,
                  ),
                  const SizedBox(height: CRMSpacing.xl),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CRMButton(
                        label: 'Cancel',
                        variant: CRMButtonVariant.outline,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: CRMSpacing.s),
                      CRMButton(
                        label: isEditing ? 'Save Changes' : 'Create Profile',
                        onPressed: _submitForm,
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
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(height: CRMSpacing.xs),
        DropdownButtonFormField<T>(
          value: value,
          dropdownColor: CRMColors.cardBgOf(context),
          style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
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
      ],
    );
  }
}
