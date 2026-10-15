import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../requirements/widgets/pdf_option_selection_dialog.dart';
import '../models/property_model.dart';
import '../models/property_pdf_filter_config.dart';

class PropertyPdfContentSelectionDialog extends StatefulWidget {
  final List<PropertyModel> properties;
  final String? recipientPhone;
  final String? customMessage;

  const PropertyPdfContentSelectionDialog({
    super.key,
    required this.properties,
    this.recipientPhone,
    this.customMessage,
  });

  static Future<bool?> show(
    BuildContext context, {
    required List<PropertyModel> properties,
    String? recipientPhone,
    String? customMessage,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PropertyPdfContentSelectionDialog(
        properties: properties,
        recipientPhone: recipientPhone,
        customMessage: customMessage,
      ),
    );
  }

  @override
  State<PropertyPdfContentSelectionDialog> createState() => _PropertyPdfContentSelectionDialogState();
}

class _PropertyPdfContentSelectionDialogState extends State<PropertyPdfContentSelectionDialog> {
  final Set<String> _selectedSections = {};
  final Set<String> _selectedFields = {};
  final Set<String> _selectedAmenities = {};
  final Set<String> _availableAmenities = {};
  final Map<String, bool> _expandedSections = {};

  @override
  void initState() {
    super.initState();

    // Collect all amenities available in the given properties
    for (final p in widget.properties) {
      for (final a in p.amenities) {
        final clean = a.trim();
        if (clean.isNotEmpty) {
          _availableAmenities.add(clean);
        }
      }
    }

    // Default: select all sections and all fields
    for (final s in PropertyPdfFilterConfig.defaultSections) {
      _selectedSections.add(s.id);
      _expandedSections[s.id] = true;
      for (final f in s.fields) {
        _selectedFields.add(f.id);
      }
    }

    // Default: select all property amenities
    _selectedAmenities.addAll(_availableAmenities);
  }

  void _toggleAll(bool selectAll) {
    setState(() {
      if (selectAll) {
        for (final s in PropertyPdfFilterConfig.defaultSections) {
          _selectedSections.add(s.id);
          for (final f in s.fields) {
            _selectedFields.add(f.id);
          }
        }
        _selectedAmenities.addAll(_availableAmenities);
      } else {
        _selectedSections.clear();
        _selectedFields.clear();
        _selectedAmenities.clear();
      }
    });
  }

  void _toggleSection(String sectionId, bool value) {
    setState(() {
      final section = PropertyPdfFilterConfig.defaultSections.firstWhere((s) => s.id == sectionId);
      if (value) {
        _selectedSections.add(sectionId);
        for (final f in section.fields) {
          _selectedFields.add(f.id);
        }
        if (sectionId == 'amenities') {
          _selectedAmenities.addAll(_availableAmenities);
        }
      } else {
        _selectedSections.remove(sectionId);
        for (final f in section.fields) {
          _selectedFields.remove(f.id);
        }
        if (sectionId == 'amenities') {
          _selectedAmenities.clear();
        }
      }
    });
  }

  void _toggleField(String sectionId, String fieldId, bool value) {
    setState(() {
      final section = PropertyPdfFilterConfig.defaultSections.firstWhere((s) => s.id == sectionId);
      if (value) {
        _selectedFields.add(fieldId);
        _selectedSections.add(sectionId);
        if (sectionId == 'amenities') {
          _selectedAmenities.addAll(_availableAmenities);
        }
      } else {
        _selectedFields.remove(fieldId);
        if (sectionId == 'amenities') {
          _selectedAmenities.clear();
        }
        // If all fields of this section are unchecked, uncheck the section
        final anyChecked = section.fields.any((f) => _selectedFields.contains(f.id));
        if (!anyChecked) {
          _selectedSections.remove(sectionId);
        }
      }
    });
  }

  void _toggleAmenity(String amenity, bool value) {
    setState(() {
      if (value) {
        _selectedAmenities.add(amenity);
        _selectedSections.add('amenities');
        _selectedFields.add('amenities_all');
      } else {
        _selectedAmenities.remove(amenity);
        if (_selectedAmenities.isEmpty) {
          _selectedFields.remove('amenities_all');
          _selectedSections.remove('amenities');
        }
      }
    });
  }

  void _proceedToPdfDesign() async {
    final activeSections = Set<String>.from(_selectedSections);
    final activeFields = _selectedFields.where((f) {
      final s = PropertyPdfFilterConfig.fieldToSection[f];
      return s != null && activeSections.contains(s);
    }).toSet();
    final activeAmenities = activeSections.contains('amenities')
        ? Set<String>.from(_selectedAmenities)
        : <String>{};

    final filterConfig = PropertyPdfFilterConfig(
      enabledSections: activeSections,
      enabledFields: activeFields,
      enabledAmenities: activeAmenities,
    );

    // Show Option Selection Dialog
    final result = await PdfOptionSelectionDialog.show(
      context,
      properties: widget.properties,
      filterConfig: filterConfig,
      recipientPhone: widget.recipientPhone,
      customMessage: widget.customMessage,
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isDesktop = screenWidth >= 768;

    final totalSectionsCount = PropertyPdfFilterConfig.defaultSections.length;
    final selectedSectionsCount = _selectedSections.length;
    final isAllSelected = selectedSectionsCount == totalSectionsCount;
    final hasAnySelection = _selectedSections.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: CRMColors.cardBgOf(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: screenHeight * 0.88,
        ),
        child: Column(
          children: [
            // Header Bar
            _buildDialogHeader(context, isAllSelected),
            Divider(height: 1, color: CRMColors.borderOf(context).withOpacity(0.6)),

            // Content Body (Scrollable Sections & Fields)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Info Box
                    _buildStepInfoBanner(context),
                    const SizedBox(height: 16),

                    // Sections List
                    for (final section in PropertyPdfFilterConfig.defaultSections) ...[
                      _buildSectionCard(context, section, isDesktop),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: CRMColors.borderOf(context).withOpacity(0.6)),

            // Footer Actions
            _buildDialogFooter(context, hasAnySelection),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, bool isAllSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CRMColors.primaryOf(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: CRMColors.primaryOf(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom PDF Content Selection',
                    style: CRMTypography.title.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: CRMColors.textOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.properties.length == 1
                        ? '${widget.properties.first.title} (${widget.properties.first.propertyCode})'
                        : '${widget.properties.length} Properties Selected',
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _toggleAll(!isAllSelected),
                icon: Icon(
                  isAllSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                  size: 16,
                  color: CRMColors.primaryOf(context),
                ),
                label: Text(
                  isAllSelected ? 'Deselect All' : 'Select All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CRMColors.primaryOf(context),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Close',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepInfoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CRMColors.primaryOf(context).withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CRMColors.primaryOf(context).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: CRMColors.primaryOf(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Select key sections and individual details to include in the PDF. Only the selected information will appear in the generated brochure.',
              style: CRMTypography.caption.copyWith(
                color: CRMColors.textOf(context),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    PropertyPdfSectionItem section,
    bool isDesktop,
  ) {
    final isSectionSelected = _selectedSections.contains(section.id);
    final isExpanded = _expandedSections[section.id] ?? true;

    // Count selected fields in this section
    final isAmenities = section.id == 'amenities' && _availableAmenities.isNotEmpty;
    final totalFieldsCount = isAmenities ? _availableAmenities.length : section.fields.length;
    int selectedFieldsCount = 0;
    if (isAmenities) {
      selectedFieldsCount = _selectedAmenities.length;
    } else {
      for (final f in section.fields) {
        if (_selectedFields.contains(f.id)) selectedFieldsCount++;
      }
    }

    final bool? checkboxVal = (selectedFieldsCount == 0)
        ? false
        : (selectedFieldsCount == totalFieldsCount && isSectionSelected ? true : null);

    return Container(
      decoration: BoxDecoration(
        color: isSectionSelected
            ? CRMColors.cardBgOf(context)
            : CRMColors.backgroundOf(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSectionSelected
              ? CRMColors.primaryOf(context).withOpacity(0.35)
              : CRMColors.borderOf(context).withOpacity(0.6),
          width: isSectionSelected ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Tile
          InkWell(
            onTap: () {
              setState(() {
                _expandedSections[section.id] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: isExpanded ? Radius.zero : const Radius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Section Checkbox
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: checkboxVal,
                      tristate: true,
                      activeColor: CRMColors.primaryOf(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) {
                        final shouldSelect = selectedFieldsCount < totalFieldsCount;
                        _toggleSection(section.id, shouldSelect);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    section.icon,
                    size: 19,
                    color: isSectionSelected ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            section.title,
                            style: CRMTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSectionSelected ? CRMColors.textOf(context) : CRMColors.textSecondaryOf(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSectionSelected
                                ? CRMColors.primaryOf(context).withOpacity(0.12)
                                : CRMColors.borderOf(context).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$selectedFieldsCount/$totalFieldsCount selected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSectionSelected
                                  ? CRMColors.primaryOf(context)
                                  : CRMColors.textSecondaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: CRMColors.textSecondaryOf(context),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Details Grid
          if (isExpanded) ...[
            Divider(height: 1, color: CRMColors.borderOf(context).withOpacity(0.4)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: section.id == 'amenities'
                  ? _buildAmenitiesFieldView(context)
                  : _buildStandardFieldsGrid(context, section, isDesktop),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandardFieldsGrid(
    BuildContext context,
    PropertyPdfSectionItem section,
    bool isDesktop,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width > 520 ? 3 : (width > 340 ? 2 : 1);
        final double itemWidth = (width - ((crossAxisCount - 1) * 8)) / crossAxisCount;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: section.fields.map((field) {
            final isFieldSelected = _selectedFields.contains(field.id);
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: () {
                  _toggleField(section.id, field.id, !isFieldSelected);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isFieldSelected
                        ? CRMColors.primaryOf(context).withOpacity(0.06)
                        : CRMColors.backgroundOf(context).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isFieldSelected
                          ? CRMColors.primaryOf(context).withOpacity(0.25)
                          : CRMColors.borderOf(context).withOpacity(0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: isFieldSelected,
                          activeColor: CRMColors.primaryOf(context),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            _toggleField(section.id, field.id, val ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          field.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isFieldSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isFieldSelected ? CRMColors.textOf(context) : CRMColors.textSecondaryOf(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAmenitiesFieldView(BuildContext context) {
    if (_availableAmenities.isEmpty) {
      return Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: _selectedFields.contains('amenities_all'),
              activeColor: CRMColors.primaryOf(context),
              onChanged: (val) {
                _toggleField('amenities', 'amenities_all', val ?? false);
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Include All Property Amenities',
            style: CRMTypography.bodyMedium.copyWith(fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Specific Amenities:',
              style: CRMTypography.captionBold.copyWith(
                color: CRMColors.textSecondaryOf(context),
                fontSize: 11,
              ),
            ),
            InkWell(
              onTap: () {
                final allSelected = _selectedAmenities.length == _availableAmenities.length;
                setState(() {
                  if (allSelected) {
                    _selectedAmenities.clear();
                    _selectedFields.remove('amenities_all');
                    _selectedSections.remove('amenities');
                  } else {
                    _selectedAmenities.addAll(_availableAmenities);
                    _selectedFields.add('amenities_all');
                    _selectedSections.add('amenities');
                  }
                });
              },
              child: Text(
                _selectedAmenities.length == _availableAmenities.length ? 'Deselect All' : 'Select All',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CRMColors.primaryOf(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableAmenities.map((amenity) {
            final isAmenityChecked = _selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(
                amenity,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isAmenityChecked ? FontWeight.w600 : FontWeight.normal,
                  color: isAmenityChecked ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                ),
              ),
              selected: isAmenityChecked,
              showCheckmark: true,
              checkmarkColor: CRMColors.primaryOf(context),
              selectedColor: CRMColors.primaryOf(context).withOpacity(0.12),
              backgroundColor: CRMColors.backgroundOf(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isAmenityChecked
                      ? CRMColors.primaryOf(context).withOpacity(0.4)
                      : CRMColors.borderOf(context).withOpacity(0.5),
                  width: 0.8,
                ),
              ),
              onSelected: (val) {
                _toggleAmenity(amenity, val);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDialogFooter(BuildContext context, bool hasAnySelection) {
    final selectedCount = _selectedFields.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '$selectedCount fields selected across ${_selectedSections.length} sections',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _toggleAll(true),
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 12,
                    color: CRMColors.primaryOf(context),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: hasAnySelection ? _proceedToPdfDesign : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Next: Choose PDF Design'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CRMColors.primaryOf(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
