part of 'wizard_state.dart';

// ─── Extensions for WizardState: Category Tree, Payload, Submit, Import, Helpers

extension WizardCategoryTree on WizardState {
  List<Map<String, dynamic>> flattenCategoryTree(
    List<Map<String, dynamic>> tree, {
    String? parentId,
  }) {
    final result = <Map<String, dynamic>>[];
    for (final item in tree) {
      final flatItem = Map<String, dynamic>.from(item);
      if (flatItem['parentId'] == null && parentId != null) {
        flatItem['parentId'] = parentId;
      }
      result.add(flatItem);
      final children = item['children'];
      if (children is List && children.isNotEmpty) {
        result.addAll(flattenCategoryTree(
          children.cast<Map<String, dynamic>>(),
          parentId: item['id']?.toString(),
        ));
      }
    }
    return result;
  }

  List<Map<String, dynamic>> buildCategoryTree(List<Map<String, dynamic>> raw) {
    if (raw.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
    final roots = raw
        .where((c) => c['parentId'] == null || c['parentId'].toString().isEmpty)
        .toList()
      ..sort((a, b) => ((a['sortOrder'] as int?) ?? 0).compareTo((b['sortOrder'] as int?) ?? 0));
    final level1 = raw
        .where((c) =>
            c['parentId'] != null &&
            c['parentId'].toString().isNotEmpty &&
            roots.any((r) => r['id']?.toString() == c['parentId']?.toString()))
        .toList()
      ..sort((a, b) => ((a['sortOrder'] as int?) ?? 0).compareTo((b['sortOrder'] as int?) ?? 0));
    final level2 = raw
        .where((c) =>
            c['parentId'] != null &&
            c['parentId'].toString().isNotEmpty &&
            level1.any((l) => l['id']?.toString() == c['parentId']?.toString()))
        .toList()
      ..sort((a, b) => ((a['sortOrder'] as int?) ?? 0).compareTo((b['sortOrder'] as int?) ?? 0));
    for (final root in roots) {
      final rootId = root['id']?.toString() ?? '';
      result.add({'value': rootId, 'label': '\ud83d\udcc1 ${root['name']}'});
      for (final child in level1.where((c) => c['parentId']?.toString() == rootId)) {
        final childId = child['id']?.toString() ?? '';
        result.add({'value': childId, 'label': '   \u2514\u2500 ${child['name']}'});
        for (final grand in level2.where((c) => c['parentId']?.toString() == childId)) {
          result.add({'value': grand['id']?.toString() ?? '', 'label': '      \u2514\u2500 ${grand['name']}'});
        }
      }
    }
    if (result.isEmpty) {
      return raw.map((c) => {'value': c['id']?.toString() ?? '', 'label': c['name']?.toString() ?? ''}).toList();
    }
    return result;
  }
}

extension WizardPayload on WizardState {
  /// Sektöre özel metadata oluşturur
  Map<String, dynamic>? _buildSectorMetadata() {
    switch (sector) {
      case 'giyim':
        final meta = <String, dynamic>{};
        if (fabricController.text.isNotEmpty) meta['fabric'] = fabricController.text;
        if (seasonController.text.isNotEmpty) meta['season'] = seasonController.text;
        return meta.isEmpty ? null : meta;
      case 'parcaci':
        final meta = <String, dynamic>{};
        if (shelfNumberController.text.isNotEmpty) meta['shelfLocation'] = shelfNumberController.text;
        if (oemNumbers.isNotEmpty) meta['oemCount'] = oemNumbers.length;
        if (crossReferences.isNotEmpty) meta['crossRefCount'] = crossReferences.length;
        return meta.isEmpty ? null : meta;
      default:
        return null;
    }
  }

  Map<String, dynamic> buildPayload() {
    final hasPurchase = (selectedSupplier?.isNotEmpty == true) &&
        invoiceNumberController.text.isNotEmpty &&
        purchaseDateController.text.isNotEmpty;
    return {
      'product': {
        'sku': skuController.text,
        'name': productNameController.text,
        'categoryId': selectedCategory ?? '',
        'brand': brandController.text,
        'unit': selectedUnit,
        'description': descriptionController.text,
        'sector': sector,
        'metadata': _buildSectorMetadata(),
      },
      'oemNumbers': oemNumbers
          .where((o) => (o['oemNumber'] ?? '').isNotEmpty)
          .map((o) => {'oemNumber': o['oemNumber'], 'manufacturer': o['manufacturer'], 'isPrimary': o == oemNumbers.first})
          .toList(),
      'crossReferences': crossReferences
          .where((c) => (c['crossRefNumber'] ?? '').isNotEmpty)
          .map((c) => {'crossRefNumber': c['crossRefNumber'], 'crossRefBrand': c['crossRefBrand'], 'notes': c['notes']})
          .toList(),
      'variants': variants.map((v) => {
        'sku': v.sku,
        'name': v.name,
        'shelfLocationCode': shelfNumberController.text.isNotEmpty ? shelfNumberController.text : null,
        'attributes': v.attributes,
        'pricing': {
          'purchasePrice': v.purchasePrice, 'salePrice': v.salePrice,
          'vatRate': selectedVatRate, 'vatIncluded': vatIncluded,
          'specialTaxRate': specialTaxRateController.text.isNotEmpty ? double.tryParse(specialTaxRateController.text) : null,
          'withholdingTaxRate': withholdingTaxRateController.text.isNotEmpty ? double.tryParse(withholdingTaxRateController.text) : null,
          'taxExempt': taxExempt,
        },
        'initialStocks': selectedWarehouses.isNotEmpty
            ? selectedWarehouses.expand((wh) =>
                selectedStores.isNotEmpty
                    ? selectedStores.map((st) => {'storeId': st, 'warehouseId': wh, 'quantity': v.inventory?.physicalQuantity ?? 0})
                    : [{'storeId': null, 'warehouseId': wh, 'quantity': v.inventory?.physicalQuantity ?? 0}]
              ).toList()
            : [{'storeId': selectedStores.isNotEmpty ? selectedStores.first : null, 'warehouseId': v.inventory?.warehouseCode ?? '', 'quantity': v.inventory?.physicalQuantity ?? 0}],
        'barcodes': v.barcodes.map((b) => {'code': b.code, 'type': b.type, 'isPrimary': b.isPrimary}).toList(),
      }).toList(),
      'purchase': hasPurchase
          ? {
              'supplierId': selectedSupplier, 'invoiceNumber': invoiceNumberController.text,
              'deliveryNoteNumber': deliveryNoteController.text.isEmpty ? null : deliveryNoteController.text,
              'purchaseDate': purchaseDateController.text,
              'storeId': selectedStores.isNotEmpty ? selectedStores.first : null,
              'warehouseId': selectedWarehouses.isNotEmpty ? selectedWarehouses.first : null,
              'notes': globalNotesController.text.isEmpty ? null : globalNotesController.text,
            }
          : null,
    };
  }

  String buildJsonPreview() {
    try {
      return const JsonEncoder.withIndent('  ').convert(buildPayload());
    } catch (e) {
      return '{\n  "error": "JSON olu\u015fturulamad\u0131: $e"\n}';
    }
  }
}

extension WizardSubmit on WizardState {
  Future<bool> handleSubmit({
    required WidgetRef ref,
    required BuildContext context,
    required bool fromBulkImport,
    String? tempId,
    bool andContinue = false,
  }) async {
    isSaving = true;
    notify();
    try {
      final payload = buildPayload();
      final savedName = productNameController.text;
      final savedVariantCount = variants.length;
      await ref.read(productServiceProvider).createProduct(payload);
      isSaving = false;
      notify();

      if (!context.mounted) return false;

      if (andContinue) {
        AppToast.success(context, '$savedName kaydedildi ($savedVariantCount varyant). Yeni \u00fcr\u00fcn ekleyebilirsiniz.');
        return true; // signal success — caller handles reset
      } else {
        AppToast.success(context, '$savedName ba\u015far\u0131yla kaydedildi! $savedVariantCount varyant olu\u015fturuldu.');
        if (fromBulkImport && tempId != null) {
          Navigator.pop(context, UserDecision.create(tempId: tempId, product: payload));
        } else {
          Navigator.pop(context, true);
        }
        return true;
      }
    } catch (error) {
      debugPrint('\u274c HATA: $error');
      String msg = '\u00dcr\u00fcn kaydedilemedi';
      if (error is DioException) {
        final data = error.response?.data;
        if (data is Map) {
          msg = data['message']?.toString() ??
              ((data['errors'] as List?)?.map((e) => (e is Map ? e['message'] : e)?.toString() ?? '').where((s) => s.isNotEmpty).join('\n') ?? msg);
        }
      } else {
        msg = '$msg: $error';
      }
      isSaving = false;
      notify();
      if (context.mounted) {
        AppToast.error(context, msg);
      }
      return false;
    }
  }
}

extension WizardImportData on WizardState {
  void populateFromImportData(Map<String, dynamic> data) {
    if (data['name'] != null) productNameController.text = data['name'].toString();
    if (data['sku'] != null) skuController.text = data['sku'].toString();
    if (data['barcode'] != null) {
      final barcode = data['barcode'].toString();
      if (variants.isNotEmpty && barcode.isNotEmpty) {
        variants[0].barcodes = [BarcodeInfo(code: barcode, type: 'EAN13', isPrimary: true)];
      }
    }
    if (data['buyPrice'] != null) {
      basePurchasePriceController.text = data['buyPrice'].toString();
      if (variants.isNotEmpty) variants[0].purchasePrice = double.tryParse(data['buyPrice'].toString()) ?? 0;
    }
    if (data['sellPrice'] != null) {
      basePriceController.text = data['sellPrice'].toString();
      if (variants.isNotEmpty) variants[0].salePrice = double.tryParse(data['sellPrice'].toString()) ?? 0;
    }
    if (data['stock'] != null) {
      final stock = int.tryParse(data['stock'].toString()) ?? 0;
      if (variants.isNotEmpty && variants[0].inventory != null) variants[0].inventory!.physicalQuantity = stock;
    }
    if (data['categoryId'] != null) selectedCategory = data['categoryId'].toString();
    if (data['brandId'] != null) brandController.text = data['brandId'].toString();
    if (data['unit'] != null) selectedUnit = data['unit'].toString();
    notify();
  }
}

extension WizardImageHelpers on WizardState {
  List<int> getFilteredVariants() {
    if (variantSearchQuery.isEmpty) return List.generate(variants.length, (i) => i);
    final query = variantSearchQuery.toLowerCase();
    return List.generate(variants.length, (i) => i).where((i) {
      final v = variants[i];
      return v.name.toLowerCase().contains(query) || v.sku.toLowerCase().contains(query) || v.attributes.values.any((a) => a.toLowerCase().contains(query));
    }).toList();
  }

  List<String> getAvailableAttributes() {
    final attrs = <String>{};
    for (final v in variants) attrs.addAll(v.attributes.keys);
    return attrs.toList()..sort();
  }

  bool hasColorAttribute() => variants.any((v) => v.attributes.containsKey(groupingAttribute));

  Map<String, List<int>> groupVariantsByColor() {
    final groups = <String, List<int>>{};
    for (final index in getFilteredVariants()) {
      final value = variants[index].attributes[groupingAttribute] ?? 'Di\u011fer';
      groups.putIfAbsent(value, () => []).add(index);
    }
    return groups;
  }

  IconData getIconForAttribute(String attribute) {
    switch (attribute.toLowerCase()) {
      case 'renk': case 'color': return Icons.palette;
      case 'beden': case 'size': return Icons.straighten;
      case 'kapasite': case 'capacity': return Icons.storage;
      case 'ram': return Icons.memory;
      case 'depolama': case 'storage': return Icons.sd_storage;
      case 'model': return Icons.category;
      default: return Icons.label;
    }
  }
}                                                                                                                                                                                                                                                                                                                                                                                                                                         