import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/service_locator.dart';
import '../providers/batch_entry_provider.dart';

class BatchHeaderForm extends ConsumerStatefulWidget {
  const BatchHeaderForm({super.key});

  @override
  ConsumerState<BatchHeaderForm> createState() => _BatchHeaderFormState();
}

class _BatchHeaderFormState extends ConsumerState<BatchHeaderForm> {
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _stores = [];
  bool _loading = true;

  final _invoiceController = TextEditingController();
  final _deliveryNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _deliveryNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ref.read(supplierServiceProvider).getSuppliers(status: 'ACTIVE'),
        ref.read(warehouseServiceProvider).getWarehouses(isActive: true),
        ref.read(storeServiceProvider).getStores(isActive: true),
      ]);
      if (mounted) {
        setState(() {
          _suppliers = results[0];
          _warehouses = results[1];
          _stores = results[2];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleCollapse() {
    final state = ref.read(batchEntryProvider);
    ref.read(batchEntryProvider.notifier).updateHeader(
          headerCollapsed: !state.headerCollapsed,
        );
  }

  Future<void> _pickDate() async {
    final state = ref.read(batchEntryProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      ref.read(batchEntryProvider.notifier).updateHeader(purchaseDate: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchEntryProvider);
    final isCollapsed = state.headerCollapsed;
    final isWide = MediaQuery.sizeOf(context).width > 600;
    final dateFmt = DateFormat('dd.MM.yyyy');

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          // Header toggle
          InkWell(
            onTap: _toggleCollapse,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isCollapsed
                        ? Icons.expand_more
                        : Icons.expand_less,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: isCollapsed
                        ? Text(
                            'Tedarikci: ${state.supplierName ?? "-"}'
                            ' | Fatura: ${state.invoiceNumber ?? "-"}'
                            ' | Depo: ${state.warehouseName ?? "-"}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        : const Text(
                            'Fatura Bilgileri',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        // Row 1: Supplier
                        DropdownButtonFormField<String>(
                          initialValue: state.supplierId,
                          decoration: const InputDecoration(
                            labelText: 'Tedarikci',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: _suppliers.map((s) {
                            return DropdownMenuItem<String>(
                              value: s['id']?.toString(),
                              child: Text(
                                s['name']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            final supplier = _suppliers.firstWhere(
                              (s) => s['id']?.toString() == val,
                              orElse: () => {},
                            );
                            ref
                                .read(batchEntryProvider.notifier)
                                .updateHeader(
                                  supplierId: val,
                                  supplierName:
                                      supplier['name']?.toString(),
                                );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Row 2: Invoice + Delivery note
                        _buildRow(
                          isWide: isWide,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _invoiceController,
                                decoration: const InputDecoration(
                                  labelText: 'Fatura No',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) => ref
                                    .read(batchEntryProvider.notifier)
                                    .updateHeader(invoiceNumber: val),
                              ),
                            ),
                            SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
                            Expanded(
                              child: TextField(
                                controller: _deliveryNoteController,
                                decoration: const InputDecoration(
                                  labelText: 'Irsaliye No',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) => ref
                                    .read(batchEntryProvider.notifier)
                                    .updateHeader(deliveryNoteNumber: val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 3: Date + Warehouse + Store
                        _buildRow(
                          isWide: isWide,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Tarih',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    suffixIcon:
                                        Icon(Icons.calendar_today, size: 18),
                                  ),
                                  child: Text(
                                    dateFmt.format(state.purchaseDate),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: state.warehouseId,
                                decoration: const InputDecoration(
                                  labelText: 'Depo',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                isExpanded: true,
                                items: _warehouses.map((w) {
                                  return DropdownMenuItem<String>(
                                    value: w['id']?.toString(),
                                    child: Text(
                                      w['name']?.toString() ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  final wh = _warehouses.firstWhere(
                                    (w) => w['id']?.toString() == val,
                                    orElse: () => {},
                                  );
                                  ref
                                      .read(batchEntryProvider.notifier)
                                      .updateHeader(
                                        warehouseId: val,
                                        warehouseName:
                                            wh['name']?.toString(),
                                      );
                                },
                              ),
                            ),
                            SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: state.storeId,
                                decoration: const InputDecoration(
                                  labelText: 'Magaza',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                isExpanded: true,
                                items: _stores.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s['id']?.toString(),
                                    child: Text(
                                      s['name']?.toString() ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  final st = _stores.firstWhere(
                                    (s) => s['id']?.toString() == val,
                                    orElse: () => {},
                                  );
                                  ref
                                      .read(batchEntryProvider.notifier)
                                      .updateHeader(
                                        storeId: val,
                                        storeName:
                                            st['name']?.toString(),
                                      );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            crossFadeState: isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required bool isWide,
    required List<Widget> children,
  }) {
    if (isWide) {
      return Row(children: children);
    }
    return Column(
      children: children.map((c) {
        if (c is SizedBox) return const SizedBox(height: 12);
        if (c is Expanded) return SizedBox(width: double.infinity, child: c.child);
        return c;
      }).toList(),
    );
  }
}
