import 'package:flutter/material.dart';

class PropertyPdfFieldItem {
  final String id;
  final String label;
  final String sectionId;

  const PropertyPdfFieldItem({
    required this.id,
    required this.label,
    required this.sectionId,
  });
}

class PropertyPdfSectionItem {
  final String id;
  final String title;
  final IconData icon;
  final List<PropertyPdfFieldItem> fields;

  const PropertyPdfSectionItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.fields,
  });
}

class PropertyPdfFilterConfig {
  final Set<String> enabledSections;
  final Set<String> enabledFields;
  final Set<String> enabledAmenities;

  const PropertyPdfFilterConfig({
    required this.enabledSections,
    required this.enabledFields,
    required this.enabledAmenities,
  });

  static const List<PropertyPdfSectionItem> defaultSections = [
    PropertyPdfSectionItem(
      id: 'images',
      title: 'Images',
      icon: Icons.photo_library_outlined,
      fields: [
        PropertyPdfFieldItem(id: 'images_gallery', label: 'Photo Gallery (Hero & Photo Grid)', sectionId: 'images'),
      ],
    ),
    PropertyPdfSectionItem(
      id: 'overview',
      title: 'Overview',
      icon: Icons.dashboard_outlined,
      fields: [
        PropertyPdfFieldItem(id: 'overview_title', label: 'Project / Title', sectionId: 'overview'),
        PropertyPdfFieldItem(id: 'overview_deposit', label: 'Security Deposit', sectionId: 'overview'),
        PropertyPdfFieldItem(id: 'overview_builtup_area', label: 'Built Up Area', sectionId: 'overview'),
        PropertyPdfFieldItem(id: 'overview_furnishing', label: 'Furnishing', sectionId: 'overview'),
        PropertyPdfFieldItem(id: 'overview_bathrooms', label: 'Bathrooms', sectionId: 'overview'),
        PropertyPdfFieldItem(id: 'overview_balcony', label: 'Balcony', sectionId: 'overview'),
        PropertyPdfFieldItem(id: 'overview_available_from', label: 'Available From', sectionId: 'overview'),
        PropertyPdfFieldItem(id: 'overview_floor', label: 'Floor Number', sectionId: 'overview'),
        PropertyPdfFieldItem(id: 'overview_age', label: 'Age of Property', sectionId: 'overview'),
        PropertyPdfFieldItem(id: 'overview_parking', label: 'Parking Info', sectionId: 'overview'),
      ],
    ),
    PropertyPdfSectionItem(
      id: 'basic_details',
      title: 'Basic Details',
      icon: Icons.info_outline_rounded,
      fields: [
        PropertyPdfFieldItem(id: 'basic_property_code', label: 'Property Code', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_listing_type', label: 'Listing Type', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_category', label: 'Category', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_property_type', label: 'Property Type', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_configuration', label: 'Configuration', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_status', label: 'Status', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_price', label: 'Price / Rent', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_deposit', label: 'Security Deposit', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_maintenance', label: 'Maintenance Charges', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_created_at', label: 'Created Date', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_description', label: 'Description', sectionId: 'basic_details'),
        PropertyPdfFieldItem(id: 'basic_remarks', label: 'Internal Remarks', sectionId: 'basic_details'),
      ],
    ),
    PropertyPdfSectionItem(
      id: 'specifications',
      title: 'Specifications & Floor Details',
      icon: Icons.layers_outlined,
      fields: [
        PropertyPdfFieldItem(id: 'specs_bedrooms', label: 'Bedrooms', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_bathrooms', label: 'Bathrooms', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_balconies', label: 'Balconies', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_floor', label: 'Floor No / Total Floors', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_age', label: 'Property Age', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_super_builtup', label: 'Super Built-up Area', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_carpet', label: 'Carpet Area Size', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_plot', label: 'Plot Area Size', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_furnishing', label: 'Furnishing Type', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_facing', label: 'Facing', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_available_from', label: 'Available From', sectionId: 'specifications'),
        PropertyPdfFieldItem(id: 'specs_parking', label: 'Parking', sectionId: 'specifications'),
      ],
    ),
    PropertyPdfSectionItem(
      id: 'location',
      title: 'Location & Address',
      icon: Icons.location_on_outlined,
      fields: [
        PropertyPdfFieldItem(id: 'loc_address', label: 'Address', sectionId: 'location'),
        PropertyPdfFieldItem(id: 'loc_area', label: 'Area', sectionId: 'location'),
        PropertyPdfFieldItem(id: 'loc_city', label: 'City', sectionId: 'location'),
        PropertyPdfFieldItem(id: 'loc_pincode', label: 'Pincode', sectionId: 'location'),
        PropertyPdfFieldItem(id: 'loc_landmark', label: 'Landmark', sectionId: 'location'),
        PropertyPdfFieldItem(id: 'loc_block_wing', label: 'Block / Wing', sectionId: 'location'),
        PropertyPdfFieldItem(id: 'loc_flat_no', label: 'Flat Number', sectionId: 'location'),
        PropertyPdfFieldItem(id: 'loc_section', label: 'Section (વિભાગ)', sectionId: 'location'),
        PropertyPdfFieldItem(id: 'loc_coordinates', label: 'Coordinates (Lat / Long)', sectionId: 'location'),
      ],
    ),
    PropertyPdfSectionItem(
      id: 'amenities',
      title: 'Amenities',
      icon: Icons.pool_rounded,
      fields: [
        PropertyPdfFieldItem(id: 'amenities_all', label: 'Amenities & Features List', sectionId: 'amenities'),
      ],
    ),
    PropertyPdfSectionItem(
      id: 'contacts',
      title: 'Contacts & Key Management',
      icon: Icons.contact_phone_outlined,
      fields: [
        PropertyPdfFieldItem(id: 'contact_ownership', label: 'Ownership', sectionId: 'contacts'),
        PropertyPdfFieldItem(id: 'contact_owner_name', label: 'Owner Name', sectionId: 'contacts'),
        PropertyPdfFieldItem(id: 'contact_owner_mobile', label: 'Owner Mobile', sectionId: 'contacts'),
        PropertyPdfFieldItem(id: 'contact_refer_name', label: 'Refer Name / Key Collect', sectionId: 'contacts'),
        PropertyPdfFieldItem(id: 'contact_brokerage', label: 'Brokerage Confirmation', sectionId: 'contacts'),
      ],
    ),
  ];

  static final Map<String, String> fieldToSection = {
    for (final s in defaultSections)
      for (final f in s.fields)
        f.id: s.id,
  };

  bool isSectionEnabled(String sectionId) => enabledSections.contains(sectionId);

  bool isFieldEnabled(String fieldId) {
    final sectionId = fieldToSection[fieldId];
    if (sectionId != null && !isSectionEnabled(sectionId)) {
      return false;
    }
    return enabledFields.contains(fieldId);
  }

  bool isAmenityEnabled(String amenity) {
    if (!isSectionEnabled('amenities')) return false;
    return enabledAmenities.contains(amenity);
  }

  factory PropertyPdfFilterConfig.allEnabled({List<String>? initialAmenities}) {
    final sections = defaultSections.map((s) => s.id).toSet();
    final fields = <String>{};
    for (final s in defaultSections) {
      for (final f in s.fields) {
        fields.add(f.id);
      }
    }
    final amenities = initialAmenities != null ? initialAmenities.toSet() : <String>{};
    return PropertyPdfFilterConfig(
      enabledSections: sections,
      enabledFields: fields,
      enabledAmenities: amenities,
    );
  }

  PropertyPdfFilterConfig copyWith({
    Set<String>? enabledSections,
    Set<String>? enabledFields,
    Set<String>? enabledAmenities,
  }) {
    return PropertyPdfFilterConfig(
      enabledSections: enabledSections ?? this.enabledSections,
      enabledFields: enabledFields ?? this.enabledFields,
      enabledAmenities: enabledAmenities ?? this.enabledAmenities,
    );
  }
}
