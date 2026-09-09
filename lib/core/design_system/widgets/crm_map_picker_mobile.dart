import 'package:flutter/material.dart';
import 'crm_map_picker.dart';

class PlatformMapPicker extends StatefulWidget implements CRMMapPicker {
  @override
  final double? initialLatitude;
  @override
  final double? initialLongitude;
  @override
  final Function(double lat, double lng) onLocationPicked;
  @override
  final Function(Map<String, dynamic> place) onPlaceSelected;

  const PlatformMapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationPicked,
    required this.onPlaceSelected,
  });

  @override
  State<PlatformMapPicker> createState() => _PlatformMapPickerMobileState();
}

class _PlatformMapPickerMobileState extends State<PlatformMapPicker> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Text("Interactive Map Picker (Web Only)"),
      ),
    );
  }
}
