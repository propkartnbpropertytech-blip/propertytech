import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/builders_bloc.dart';
import '../models/builder_model.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/inputs.dart';

class AddEditBuilderScreen extends StatefulWidget {
  final BuilderModel? builder;
  final VoidCallback onSaved;

  const AddEditBuilderScreen({
    super.key,
    this.builder,
    required this.onSaved,
  });

  @override
  State<AddEditBuilderScreen> createState() => _AddEditBuilderScreenState();
}

class _AddEditBuilderScreenState extends State<AddEditBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyController = TextEditingController();
  final _contactController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _projectsController = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedTier = "Tier 3";

  @override
  void initState() {
    super.initState();
    if (widget.builder != null) {
      final b = widget.builder!;
      _companyController.text = b.companyName;
      _contactController.text = b.contactPerson;
      _mobileController.text = b.mobile;
      _emailController.text = b.email;
      _projectsController.text = b.activeProjects.join(', ');
      _remarksController.text = b.remarks ?? '';
      _selectedTier = b.tier;
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _contactController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _projectsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final List<String> projects = _projectsController.text
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final builder = BuilderModel(
      id: widget.builder?.id ?? '',
      companyName: _companyController.text.trim(),
      contactPerson: _contactController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      activeProjects: projects,
      tier: _selectedTier,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      createdAt: widget.builder?.createdAt ?? DateTime.now(),
    );

    if (widget.builder == null) {
      context.read<BuildersBloc>().add(CreateBuilderEvent(builder));
    } else {
      context.read<BuildersBloc>().add(UpdateBuilderEvent(builder));
    }

    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.builder != null;

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
                    isEditing ? "Edit Developer Group Profile" : "Register Builder Group",
                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                  ),
                  const SizedBox(height: CRMSpacing.xs),
                  Text(
                    "Setup contact information and active construction site listings",
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                  ),
                  const SizedBox(height: CRMSpacing.l),

                  // Company Name
                  CRMTextField(
                    controller: _companyController,
                    labelText: 'Company / Group Name *',
                    hintText: 'e.g. Adani Realty',
                    prefixIcon: Icons.business_rounded,
                    validator: (v) => v == null || v.isEmpty ? 'Company name is required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Contact Person
                  CRMTextField(
                    controller: _contactController,
                    labelText: 'Key Contact Representative *',
                    hintText: 'Enter name',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => v == null || v.isEmpty ? 'Representative name is required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Mobile
                  CRMTextField(
                    controller: _mobileController,
                    labelText: 'Representative Phone *',
                    hintText: '+91 XXXXX XXXXX',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Phone number is required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Email
                  CRMTextField(
                    controller: _emailController,
                    labelText: 'Email Address *',
                    hintText: 'realty.group@example.com',
                    prefixIcon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Email address is required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Active Projects
                  CRMTextField(
                    controller: _projectsController,
                    labelText: 'Active Projects (comma separated) *',
                    hintText: 'e.g. Swara, Sarvesh, Swarad City',
                    prefixIcon: Icons.foundation_rounded,
                    validator: (v) => v == null || v.isEmpty ? 'Please enter at least one project' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Tier
                  _buildDropdown(
                    label: 'Developer Tier Rank *',
                    value: _selectedTier,
                    items: ["Tier 1", "Tier 2", "Tier 3"].map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTier = val ?? "Tier 3"),
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
