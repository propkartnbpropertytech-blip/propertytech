import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../../../../features/properties/models/property_model.dart';

class CRMMultiSelectDropdown extends StatefulWidget {
  final String label;
  final List<String> selectedIds;
  final List<LookupItem> items;
  final ValueChanged<List<String>> onChanged;

  const CRMMultiSelectDropdown({
    Key? key,
    required this.label,
    required this.selectedIds,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CRMMultiSelectDropdown> createState() => _CRMMultiSelectDropdownState();
}

class _CRMMultiSelectDropdownState extends State<CRMMultiSelectDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  static _CRMMultiSelectDropdownState? _currentlyOpen;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_currentlyOpen != null && _currentlyOpen != this) {
      _currentlyOpen!._closeDropdown();
    }
    _currentlyOpen = this;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    if (_currentlyOpen == this) {
      _currentlyOpen = null;
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  @override
  void dispose() {
    if (_currentlyOpen == this) {
      _currentlyOpen = null;
    }
    _overlayEntry?.remove();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    String searchQuery = '';

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeDropdown,
            child: const SizedBox.expand(),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 5.0),
              child: Material(
                elevation: 8.0,
                color: CRMColors.cardBgOf(context),
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                shadowColor: Colors.black.withOpacity(0.1),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                    border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.4), width: 0.5),
                  ),
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setOverlayState) {
                      final filteredItems = widget.items.where((item) {
                        if (searchQuery.trim().isEmpty) return true;
                        return item.name.toLowerCase().contains(searchQuery.trim().toLowerCase());
                      }).toList();

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                            child: SizedBox(
                              height: 34,
                              child: TextField(
                                onChanged: (val) {
                                  setOverlayState(() {
                                    searchQuery = val;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                                  prefixIcon: const Icon(Icons.search, size: 16),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: CRMColors.primaryOf(context)),
                                  ),
                                ),
                                style: TextStyle(fontSize: 12, color: CRMColors.textOf(context)),
                              ),
                            ),
                          ),
                          const Divider(height: 1, thickness: 0.5),
                          Expanded(
                            child: filteredItems.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      'No items found',
                                      style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 12),
                                    ),
                                  )
                                : ListView(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    children: filteredItems.map((item) {
                                      final isChecked = widget.selectedIds.contains(item.id);
                                      return CheckboxListTile(
                                        activeColor: CRMColors.primary,
                                        title: Text(item.name, style: TextStyle(color: CRMColors.textOf(context), fontSize: 13)),
                                        value: isChecked,
                                        dense: true,
                                        controlAffinity: ListTileControlAffinity.trailing,
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            if (checked == true) {
                                              widget.selectedIds.add(item.id);
                                            } else {
                                              widget.selectedIds.remove(item.id);
                                            }
                                          });
                                          setOverlayState(() {});
                                          widget.onChanged(List<String>.from(widget.selectedIds));
                                        },
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const Divider(height: 1, thickness: 0.5),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _closeDropdown,
                                  child: Text('Done', style: TextStyle(color: CRMColors.primaryOf(context), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayTexts = widget.selectedIds.map((id) {
      final match = widget.items.firstWhere((item) => item.id == id, orElse: () => LookupItem(id: id, name: id));
      return match.name;
    }).toList();
    final displayText = displayTexts.isNotEmpty ? displayTexts.join(', ') : 'All ${widget.label}';

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            filled: true,
            fillColor: CRMColors.backgroundOf(context),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: CRMSpacing.m, vertical: 8),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                borderSide: BorderSide.none),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: CRMTypography.body.copyWith(
                    color: widget.selectedIds.isNotEmpty ? CRMColors.textOf(context) : CRMColors.textSecondaryOf(context),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: CRMColors.textSecondaryOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
