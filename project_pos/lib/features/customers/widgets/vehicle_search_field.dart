import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/customers/providers/customer_vehicles_provider.dart';

/// Sprint 11d — Plaka arama (Autocomplete) ortak widget'ı.
/// Sprint 11e — Suggestion list inline yerine `OverlayEntry` ile render
/// edilir; modal/dar layout'larda form akışını şişirmez ve Material wrapper
/// sayesinde InkWell tap'leri kayıp gitmez.
///
/// POS [CustomerVehiclePicker] ve [PaymentRecordModal] içindeki
/// `_buildVehicleFilter()` bu widget'ı kullanır.
///
/// Davranış:
///   - Focus → boş query'de tüm aktif plakalar overlay'de listelenir
///   - Yazma → 300 ms debounce → server-side prefix search
///   - Seçim → input metni `plateDisplay`, overlay kapanır, focus düşer
///   - [allowClear] true ise seçim varken suffix × ikonu → `onSelected(null)`
///   - [trailing] verilirse input'un sağında render edilir (POS "+ yeni plaka")
///   - Outside tap (TapRegion + groupId) → overlay kapanır, seçim yapılmaz
class VehicleSearchField extends ConsumerStatefulWidget {
  final String customerId;
  final Map<String, dynamic>? selectedVehicle;
  final ValueChanged<Map<String, dynamic>?> onSelected;
  final String? labelText;
  final String? hintText;
  final Widget? trailing;
  final bool allowClear;
  final bool dense;

  const VehicleSearchField({
    super.key,
    required this.customerId,
    required this.selectedVehicle,
    required this.onSelected,
    this.labelText,
    this.hintText,
    this.trailing,
    this.allowClear = false,
    this.dense = false,
  });

  @override
  ConsumerState<VehicleSearchField> createState() =>
      _VehicleSearchFieldState();
}

class _VehicleSearchFieldState extends ConsumerState<VehicleSearchField> {
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final ValueNotifier<String> _queryNotifier = ValueNotifier<String>('');
  late final Object _tapRegionGroup;
  Timer? _debounce;
  OverlayEntry? _overlayEntry;

  String Function(String) get t => i18nOf(ref);

  @override
  void initState() {
    super.initState();
    _tapRegionGroup = Object();
    _ctrl = TextEditingController(text: _displayOf(widget.selectedVehicle));
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant VehicleSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedVehicle != oldWidget.selectedVehicle &&
        !_focusNode.hasFocus) {
      _ctrl.text = _displayOf(widget.selectedVehicle);
      _queryNotifier.value = '';
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _debounce?.cancel();
    _queryNotifier.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String _displayOf(Map<String, dynamic>? v) {
    if (v == null) return '';
    return v['plateDisplay']?.toString() ??
        v['plateNormalized']?.toString() ??
        '';
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    }
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _queryNotifier.value = text.trim();
    });
    if (_overlayEntry == null) _showOverlay();
  }

  void _select(Map<String, dynamic>? v) {
    _ctrl.text = _displayOf(v);
    _queryNotifier.value = '';
    _hideOverlay();
    _focusNode.unfocus();
    widget.onSelected(v);
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final fieldSize = renderBox.size;

    _overlayEntry = OverlayEntry(builder: (overlayCtx) {
      return Positioned(
        width: fieldSize.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: TapRegion(
            groupId: _tapRegionGroup,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: _buildSuggestionsContent(),
            ),
          ),
        ),
      );
    });
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionsContent() {
    return ValueListenableBuilder<String>(
      valueListenable: _queryNotifier,
      builder: (ctx, query, _) {
        return Consumer(
          builder: (ctx, ref, _) {
            final hasQuery = query.isNotEmpty;
            final asyncList = hasQuery
                ? ref.watch(customerVehicleSearchProvider(
                    CustomerVehicleSearchKey(widget.customerId, query)))
                : ref.watch(customerVehiclesProvider(widget.customerId));
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: asyncList.when(
                data: (vehicles) => _buildList(vehicles, hasQuery),
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(t('common.error'),
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildList(List<Map<String, dynamic>> vehicles, bool hasQuery) {
    if (vehicles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Text(
          hasQuery ? t('common.no_records') : t('vehicle.no_vehicles'),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: vehicles.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (_, i) {
        final v = vehicles[i];
        final display = _displayOf(v);
        final make = v['make']?.toString() ?? '';
        final model = v['model']?.toString() ?? '';
        final detail = (make.isNotEmpty || model.isNotEmpty)
            ? '$make $model'.trim()
            : '';
        return InkWell(
          onTap: () => _select(v),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.directions_car,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(display,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      if (detail.isNotEmpty)
                        Text(detail,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.selectedVehicle != null;
    final field = TextField(
      controller: _ctrl,
      focusNode: _focusNode,
      textCapitalization: TextCapitalization.characters,
      onChanged: _onChanged,
      onTap: _showOverlay,
      decoration: InputDecoration(
        labelText: widget.labelText ?? t('vehicle.plate'),
        hintText: widget.hintText ?? t('vehicle.search_placeholder'),
        prefixIcon: const Icon(Icons.directions_car,
            color: AppColors.primary, size: 18),
        suffixIcon: (widget.allowClear && hasSelection)
            ? IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: AppColors.textMuted),
                tooltip: t('common.clear'),
                onPressed: () => _select(null),
              )
            : null,
        isDense: widget.dense,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: widget.dense
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : null,
      ),
    );

    final fieldWithLink = CompositedTransformTarget(
      link: _layerLink,
      child: TapRegion(
        groupId: _tapRegionGroup,
        onTapOutside: (_) => _hideOverlay(),
        child: field,
      ),
    );

    if (widget.trailing == null) return fieldWithLink;
    return Row(
      children: [
        Expanded(child: fieldWithLink),
        const SizedBox(width: 8),
        widget.trailing!,
      ],
    );
  }
}
