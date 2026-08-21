import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/owners_bloc.dart';
import '../models/owner_model.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/inputs.dart';

class AddEditOwnerScreen extends StatefulWidget {
  final OwnerModel? owner;
  final VoidCallback onSaved;

  const AddEditOwnerScreen({
    super.key,
    this.owner,
    required this.onSaved,
  });

  @override
  State<AddEditOwnerScreen> createState() => _AddEditOwnerScreenState();
}

class _AddEditOwnerScreenState extends State<AddEditOwnerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.owner != null) {
      final o = widget.owner!;
      _nameController.text = o.name;
      _mobileController.text = o.mobile;
      _emailController.text = o.email;
      _addressController.text = o.address ?? '';
      _remarksController.text = o.remarks ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final owner = OwnerModel(
      id: widget.owner?.id ?? '',
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      createdAt: widget.owner?.createdAt ?? DateTime.now(),
    );

    if (widget.owner == null) {
      context.read<OwnersBloc>().add(CreateOwnerEvent(owner));
    } else {
      context.read<OwnersBloc>().add(UpdateOwnerEvent(owner));
    }

    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.owner != null;

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
                    isEditing ? "Edit Owner Contact Card" : "Register Property Owner",
                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                  ),
                  const SizedBox(height: CRMSpacing.xs),
                  Text(
                    "Setup contact information and associated asset details",
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                  ),
                  const SizedBox(height: CRMSpacing.l),

                  // Full Name
                  CRMTextField(
                    controller: _nameController,
                    labelText: 'Full Name *',
                    hintText: 'Enter name',
                    prefixIcon: Icons.person_rounded,
                    validator: (v) => v == null || v.isEmpty ? 'Owner name is required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Mobile
                  CRMTextField(
                    controller: _mobileController,
                    labelText: 'Mobile Phone *',
                    hintText: '+91 XXXXX XXXXX',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Mobile phone number is required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Email
                  CRMTextField(
                    controller: _emailController,
                    labelText: 'Email Address *',
                    hintText: 'owner@example.com',
                    prefixIcon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Email address is required' : null,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Primary Address
                  CRMTextField(
                    controller: _addressController,
                    labelText: 'Primary Mailing Address',
                    hintText: 'Enter home/office address details...',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: CRMSpacing.m),

                  // Internal remarks
                  CRMTextField(
                    controller: _remarksController,
                    labelText: 'Internal CRM Remarks',
                    hintText: 'Add summary notes or background context...',
                    prefixIcon: Icons.chat_bubble_outline_rounded,
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
                        label: isEditing ? 'Save Changes' : 'Create Contact',
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
}
