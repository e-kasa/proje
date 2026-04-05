import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/wizard_state.dart';
import '../widgets/wizard_common_widgets.dart';
import '../widgets/category_picker.dart';

class BasicInfoStep extends StatelessWidget {
  final WizardState state;
  final VoidCallback onChanged;
  final bool isMobile;

  const BasicInfoStep({
    super.key,
    required this.state,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: isMobile ? 6 : 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.white, size: isMobile ? 20 : 22),
                SizedBox(width: isMobile ? 8 : 10),
                Text(
                  'Temel \u00dcr\u00fcn Bilgileri',
                  style: TextStyle(color: Colors.white, fontSize: isMobile ? 15 : 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 16 : 18),

          // Product Name
          buildFormField(
            label: '\u00dcr\u00fcn Ad\u0131',
            required: true,
            child: TextField(
              controller: state.productNameController,
              decoration: inputDecoration('\u00d6rn: iPhone 15 Pro Max'),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 14),

          // SKU & Category Row
          Row(
            children: [
              Expanded(
                child: buildFormField(
                  label: 'SKU',
                  required: true,
                  child: TextField(
                    controller: state.skuController,
                    decoration: inputDecoration('Stok Kodu').copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        onPressed: () {
                          state.generateSKU();
                          onChanged();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Kategori',
                  required: true,
                  child: CategoryPickerButton(state: state, onChanged: onChanged),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Brand & Unit Row
          Row(
            children: [
              Expanded(
                child: buildFormField(
                  label: 'Marka',
                  child: Autocomplete<String>(
                    initialValue: TextEditingValue(text: state.brandController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.toLowerCase();
                      if (query.isEmpty) {
                        return state.brands.map((b) => b['name']?.toString() ?? '');
                      }
                      return state.brands
                          .map((b) => b['name']?.toString() ?? '')
                          .where((name) => name.toLowerCase().contains(query));
                    },
                    onSelected: (String selection) {
                      state.brandController.text = selection;
                      onChanged();
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: inputDecoration('Marka ara... (\u00f6rn: Nike)').copyWith(
                          prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 18),
                        ),
                        onChanged: (val) => state.brandController.text = val,
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final name = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.label_outline, size: 16, color: AppColors.primary),
                                  title: Text(name),
                                  onTap: () => onSelected(name),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Birim',
                  child: DropdownButtonFormField<String>(
                    value: state.selectedUnit,
                    decoration: inputDecoration('Birim se\u00e7in'),
                    items: state.units.map<DropdownMenuItem<String>>((unit) {
                      return DropdownMenuItem<String>(
                        value: unit['value'],
                        child: Text(unit['label'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      state.selectedUnit = val ?? 'pcs';
                      onChanged();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Purchase & Sale Price Row
          Row(
            children: [
              Expanded(
                child: buildFormField(
                  label: 'Al\u0131\u015f Fiyat\u0131',
                  child: TextField(
                    controller: state.basePurchasePriceController,
                    keyboardType: TextInputType.number,
                    decoration: inputDecoration('0.00').copyWith(
                      prefixText: '\u20ba ',
                      prefixStyle: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Sat\u0131\u015f Fiyat\u0131',
                  required: true,
                  child: TextField(
                    controller: state.basePriceController,
                    keyboardType: TextInputType.number,
                    decoration: inputDecoration('0.00').copyWith(
                      prefixText: '\u20ba ',
                      prefixStyle: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tax section
          _buildTaxSection(context),
          const SizedBox(height: 16),

          // Description
          buildFormField(
            label: 'A\u00e7\u0131klama',
            child: TextField(
              controller: state.descriptionController,
              maxLines: 3,
              decoration: inputDecoration('\u00dcr\u00fcn hakk\u0131nda detayl\u0131 bilgi...'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFFF57F17), size: 18),
              SizedBox(width: 8),
              Text('Vergi Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF57F17))),
            ],
          ),
          const SizedBox(height: 12),

          // KDV + OTV + Stopaj
          Row(
            children: [
              Expanded(
                flex: 2,
                child: buildFormField(
                  label: 'KDV Oran\u0131',
                  child: DropdownButtonFormField<double>(
                    value: state.selectedVatRate,
                    decoration: inputDecoration('KDV %').copyWith(
                      prefixIcon: const Icon(Icons.percent, size: 16, color: Color(0xFFF57F17)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0.0, child: Text('% 0  \u2014 Muaf')),
                      DropdownMenuItem(value: 1.0, child: Text('% 1')),
                      DropdownMenuItem(value: 8.0, child: Text('% 8')),
                      DropdownMenuItem(value: 10.0, child: Text('% 10')),
                      DropdownMenuItem(value: 18.0, child: Text('% 18')),
                      DropdownMenuItem(value: 20.0, child: Text('% 20')),
                    ],
                    onChanged: (val) {
                      state.selectedVatRate = val ?? 20.0;
                      onChanged();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: buildFormField(
                  label: '\u00d6TV Oran\u0131 (opsiyonel)',
                  child: TextField(
                    controller: state.specialTaxRateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: inputDecoration('\u00d6rn: 15.5').copyWith(
                      suffixText: '%',
                      prefixIcon: const Icon(Icons.local_gas_station, size: 16, color: Color(0xFFF57F17)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: buildFormField(
                  label: 'Stopaj (opsiyonel)',
                  child: TextField(
                    controller: state.withholdingTaxRateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: inputDecoration('\u00d6rn: 10').copyWith(
                      suffixText: '%',
                      prefixIcon: const Icon(Icons.account_balance, size: 16, color: Color(0xFFF57F17)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Toggle row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    state.vatIncluded = !state.vatIncluded;
                    onChanged();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: state.vatIncluded ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: state.vatIncluded ? const Color(0xFF4CAF50) : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(state.vatIncluded ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: state.vatIncluded ? const Color(0xFF4CAF50) : Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        const Text('Fiyat KDV Dahil', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    state.taxExempt = !state.taxExempt;
                    onChanged();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: state.taxExempt ? const Color(0xFF9C27B0).withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: state.taxExempt ? const Color(0xFF9C27B0) : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(state.taxExempt ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: state.taxExempt ? const Color(0xFF9C27B0) : Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        const Text('Vergiden Muaf', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
