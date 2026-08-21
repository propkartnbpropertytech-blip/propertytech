import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../api/api_client.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../buttons.dart';

class CRMAddressDetails {
  final String formattedAddress;
  final String landmark;
  final double latitude;
  final double longitude;
  final String placeId;
  final String area;
  final String city;
  final String state;
  final String country;
  final String pincode;

  const CRMAddressDetails({
    required this.formattedAddress,
    required this.landmark,
    required this.latitude,
    required this.longitude,
    required this.placeId,
    required this.area,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
  });
}

class CRMAddressInput extends StatefulWidget {
  final String labelText;
  final String? initialValue;
  final Function(CRMAddressDetails details) onAddressSelected;
  final bool isRequired;
  final bool enabled;

  const CRMAddressInput({
    super.key,
    required this.labelText,
    required this.onAddressSelected,
    this.initialValue,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  State<CRMAddressInput> createState() => _CRMAddressInputState();
}

class _CRMAddressInputState extends State<CRMAddressInput> {
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  List<dynamic> _suggestions = [];
  Timer? _debounce;
  bool _isLoadingSuggestions = false;
  bool _showOverrides = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _addressController.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    _landmarkController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _suggestions = [];
        });
        return;
      }

      setState(() {
        _isLoadingSuggestions = true;
      });

      try {
        final client = ApiClient();
        final response = await client.get('/places/autocomplete', queryParameters: {'query': query});
        debugPrint("[AUTOCOMPLETE DEBUG] response.data: ${response.data}");
        dynamic responseData = response.data;
        if (responseData is String) {
          try {
            responseData = jsonDecode(responseData);
          } catch (_) {}
        }
        setState(() {
          _suggestions = (responseData is Map ? responseData['data'] : null) as List<dynamic>? ?? [];
          debugPrint("[AUTOCOMPLETE DEBUG] _suggestions list: $_suggestions (length: ${_suggestions.length})");
          _isLoadingSuggestions = false;
        });
      } catch (e) {
        debugPrint("Error fetching places autocomplete: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Autocomplete Error: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  Future<void> _fetchPlaceDetails(String placeId) async {
    setState(() {
      _suggestions = [];
      _isLoadingSuggestions = true;
    });

    try {
      final client = ApiClient();
      final response = await client.get('/places/details', queryParameters: {
        'placeId': placeId,
        'query': _addressController.text,
      });
      dynamic responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (_) {}
      }
      final data = responseData is Map ? responseData['data'] : null;
      if (data == null) {
        throw Exception("Invalid details response structure");
      }

      final String address = data['formattedAddress'] ?? '';
      final String landmark = data['landmark'] ?? '';
      final double lat = (data['coordinates']?['latitude'] as num?)?.toDouble() ?? 0.0;
      final double lng = (data['coordinates']?['longitude'] as num?)?.toDouble() ?? 0.0;
      final String area = data['area'] ?? '';
      final String city = data['city'] ?? '';
      final String state = data['state'] ?? '';
      final String country = data['country'] ?? '';
      final String pincode = data['pincode'] ?? '';

      _addressController.text = address;
      _landmarkController.text = landmark;
      _latitudeController.text = lat.toString();
      _longitudeController.text = lng.toString();

      setState(() {
        _isLoadingSuggestions = false;
      });

      widget.onAddressSelected(CRMAddressDetails(
        formattedAddress: address,
        landmark: landmark,
        latitude: lat,
        longitude: lng,
        placeId: placeId,
        area: area,
        city: city,
        state: state,
        country: country,
        pincode: pincode,
      ));
    } catch (e) {
      debugPrint("Error fetching place details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Place Details Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  void _triggerManualOverride() {
    final double lat = double.tryParse(_latitudeController.text) ?? 0.0;
    final double lng = double.tryParse(_longitudeController.text) ?? 0.0;
    
    widget.onAddressSelected(CRMAddressDetails(
      formattedAddress: _addressController.text,
      landmark: _landmarkController.text,
      latitude: lat,
      longitude: lng,
      placeId: '',
      area: '',
      city: '',
      state: '',
      country: '',
      pincode: '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.labelText}${widget.isRequired ? " *" : ""}',
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        TextField(
          controller: _addressController,
          enabled: widget.enabled,
          style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
          decoration: InputDecoration(
            hintText: 'Enter complete address...',
            hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMutedOf(context)),
            suffixIcon: _isLoadingSuggestions
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.location_on_outlined, color: CRMColors.textMutedOf(context)),
            contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
            filled: true,
            fillColor: widget.enabled ? CRMColors.cardBgOf(context) : CRMColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
            ),
          ),
          onChanged: _onSearchChanged,
        ),
        if (_addressController.text.trim().isNotEmpty && _suggestions.isEmpty && !_isLoadingSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: CRMSpacing.xs, left: CRMSpacing.xs),
            child: InkWell(
              onTap: () {
                setState(() {
                  _showOverrides = true;
                });
              },
              child: Row(
                children: [
                  Icon(Icons.edit_road_rounded, size: 14, color: CRMColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'No matching locations found. Use manual entry.',
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.warning,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4.0),
            padding: const EdgeInsets.all(CRMSpacing.xs),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              border: Border.all(color: CRMColors.borderOf(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  title: Text(suggestion['mainText'] ?? '', style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context))),
                  subtitle: Text(suggestion['description'] ?? '', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                  onTap: () => _fetchPlaceDetails(suggestion['placeId']),
                );
              },
            ),
          ),
        const SizedBox(height: CRMSpacing.s),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TextButton.icon(
                    icon: Icon(
                      _showOverrides ? Icons.unfold_less_rounded : Icons.tune_rounded,
                      size: 16,
                    ),
                    label: Text(_showOverrides ? 'Hide Overrides' : 'Manual Coordinates & Landmark'),
                    onPressed: () {
                      setState(() {
                        _showOverrides = !_showOverrides;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_showOverrides) ...[
          const SizedBox(height: CRMSpacing.s),
          TextField(
            controller: _landmarkController,
            style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
            decoration: InputDecoration(
              labelText: 'Landmark / Building Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
            ),
            onChanged: (_) => _triggerManualOverride(),
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latitudeController,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _triggerManualOverride(),
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: TextField(
                  controller: _longitudeController,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _triggerManualOverride(),
                ),
              ),
            ],
          ),
        ]
      ],
    );
  }
}
