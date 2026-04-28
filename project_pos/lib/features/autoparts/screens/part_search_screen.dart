import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/templates/list_screen_template.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class PartSearchScreen extends ConsumerStatefulWidget {
  const PartSearchScreen({super.key});

  @override
  ConsumerState<PartSearchScreen> createState() => _PartSearchScreenState();
}

class _PartSearchScreenState extends ConsumerState<PartSearchScreen> {
  String Function(String) get t => i18nOf(ref);
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Arac filtre
  List<String> _makes = [];
  List<String> _models = [];
  String? _selectedMake;
  String? _selectedModel;
  final TextEditingController _yearController = TextEditingController();
  bool _showFilters = false;

  // Sonuclar
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadMakes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _yearController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMakes() async {
    final makes = await ref.read(vehicleServiceProvider).getDistinctMakes();
    setState(() => _makes = makes);
  }

  Future<void> _loadModels(String make) async {
    final models = await ref.read(vehicleServiceProvider).getModelsByMake(make);
    setState(() {
      _models = models;
      _selectedModel = null;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final keyword = _searchController.text.trim();
    final year = int.tryParse(_yearController.text.trim());

    if (keyword.isEmpty && _selectedMake == null && _selectedModel == null && year == null) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await ref.read(partSearchServiceProvider).search(
        keyword: keyword.isEmpty ? null : keyword,
        make: _selectedMake,
        model: _selectedModel,
        year: year,
      );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.error(context, t('common.error'));
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedMake = null;
      _selectedModel = null;
      _models = [];
      _yearController.clear();
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return ListScreenTemplate<Map<String, dynamic>>(
      title: t('autoparts.part_search_title'),
      items: _results,
      isLoading: _isLoading,
      onRefresh: _hasSearched ? _performSearch : null,
      searchSlot: _buildSearchSlot(),
      filterSlot: _showFilters ? _buildFilterSlot() : null,
      statsSlot: _hasSearched ? _buildStatsSlot() : null,
      emptyState: !_hasSearched ? _buildWelcomeState() : _buildEmptyState(),
      itemBuilder: (context, item, index) => _buildResultCard(item),
    );
  }

  Widget _buildSearchSlot() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: t('common.search'), // TODO: i18n part_search hint key
          prefixIcon: const Icon(Icons.search, size: 24),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                ),
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: _showFilters ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _showFilters = !_showFilters),
              ),
            ],
          ),
          filled: true,
          fillColor: AppColors.bgLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterSlot() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Arac Filtresi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                if (_selectedMake != null || _selectedModel != null || _yearController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, size: 14),
                    label: const Text('Temizle', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMake,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Marka',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    items: _makes.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedMake = val);
                      if (val != null) _loadModels(val);
                      _performSearch();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedModel,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedModel = val);
                      _performSearch();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Yil',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (_) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), _performSearch);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSlot() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${_results.length} sonuc bulundu',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Parca Arama', // TODO: i18n part_search key
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text(
            'OEM numarasi, capraz referans, parca adi\nveya barkod ile arama yapabilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'Arac filtresi ile aramayi daraltabilirsiniz',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(t('common.no_data'), style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)), // TODO: i18n no_results key
          const SizedBox(height: 8),
          const Text('Farkli anahtar kelime deneyin', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final oemNumbers = (result['oemNumbers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final crossRefs = (result['crossReferences'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final vehicles = (result['compatibleVehicles'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baslik
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result['productName'] ?? result['variantName'] ?? 'Isimsiz',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SKU: ${result['variantSku'] ?? '-'}',
                              style: const TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (result['brand'] != null) ...[
                            const SizedBox(width: 8),
                            Text(result['brand'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Fiyat
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (result['salePrice'] != null)
                      Text(
                        '${result['salePrice']} TL',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    if (result['shelfLocationCode'] != null && result['shelfLocationCode'].toString().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text(
                              result['shelfLocationCode'],
                              style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // OEM numaralari
            if (oemNumbers.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('OEM:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: oemNumbers.map((oem) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${oem['oemNumber']}${oem['manufacturer'] != null ? ' (${oem['manufacturer']})' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                )).toList(),
              ),
            ],

            // Capraz referanslar
            if (crossRefs.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Capraz Ref:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: crossRefs.map((cr) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgDanger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${cr['crossRefNumber']}${cr['crossRefBrand'] != null ? ' (${cr['crossRefBrand']})' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.bgDanger, fontWeight: FontWeight.w500),
                  ),
                )).toList(),
              ),
            ],

            // Uyumlu araclar
            if (vehicles.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Uyumlu Araclar:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: vehicles.take(5).map((v) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${v['make']} ${v['model']} ${v['yearStart'] != null ? '(${v['yearStart']}-${v['yearEnd']})' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  ),
                )).toList(),
              ),
              if (vehicles.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+${vehicles.length - 5} daha', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
