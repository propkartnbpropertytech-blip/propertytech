import 'dart:async';
import 'package:flutter/material.dart';
import '../../properties/models/property_model.dart';
import '../../properties/repository/properties_repository.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/design_system/crm_design_system.dart';
import '../../../core/design_system/widgets/drawers.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  PropertyModel? _property;
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _propertiesSubscription;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadProperty();
    _propertiesSubscription =
        RepositoryCoordinator().propertiesStream.listen((_) {
      if (mounted && !_isRefreshing) {
        _loadLocalOnly();
      }
    });
  }

  @override
  void dispose() {
    _propertiesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLocalOnly() async {
    try {
      final local =
          await PropertiesRepository().getPropertyById(widget.propertyId);
      if (local != null && mounted) {
        setState(() {
          _property = local;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProperty() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final repository = PropertiesRepository();

      // 1. Instant local read for first paint
      final local = await repository.getPropertyById(widget.propertyId);
      if (local != null && mounted) {
        setState(() {
          _property = local;
          _isLoading = false;
          _error = null;
        });
      }

      // 2. Refresh only this property — never the full inventory list
      final fresh = await repository.getPropertyById(
        widget.propertyId,
        refreshFromServer: true,
      );

      if (fresh != null && mounted) {
        setState(() {
          _property = fresh;
          _isLoading = false;
          _error = null;
        });
      } else if (_property == null && mounted) {
        setState(() {
          _error = 'Property not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_property == null && mounted) {
        setState(() {
          _error = 'Failed to load details: $e';
          _isLoading = false;
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _property == null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _property == null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: CRMColors.danger, size: 48),
              const SizedBox(height: CRMSpacing.m),
              Text(
                _error!,
                style: CRMTypography.bodyMedium
                    .copyWith(color: CRMColors.textSecondaryOf(context)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: BuildPropertyDetailWidget(
        property: _property!,
        showHeaderClose: false,
      ),
    );
  }
}
