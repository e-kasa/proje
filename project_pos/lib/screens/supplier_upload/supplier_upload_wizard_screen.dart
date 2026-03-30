import 'package:flutter/material.dart';
import '../../models/supplier_upload_models.dart';

/// Basitleştirilmiş Wizard - Her ürün için 3 seçenek
class SupplierUploadWizardScreen extends StatefulWidget {
  final SupplierUploadResponse uploadResponse;

  const SupplierUploadWizardScreen({
    Key? key,
    required this.uploadResponse,
  }) : super(key: key);

  @override
  State<SupplierUploadWizardScreen> createState() =>
      _SupplierUploadWizardScreenState();
}

class _SupplierUploadWizardScreenState
    extends State<SupplierUploadWizardScreen> {
  int currentProductIndex = 0;
  Map<int, ProductDecision> decisions = {};
  bool showSummary = false;

  ReadProductItem get currentProduct =>
      widget.uploadResponse.products[currentProductIndex];

  bool get isLastProduct =>
      currentProductIndex == widget.uploadResponse.products.length - 1;

  bool get isFirstProduct => currentProductIndex == 0;

  int get totalProducts => widget.uploadResponse.products.length;

  int get decidedCount => decisions.length;

  @override
  Widget build(BuildContext context) {
    if (showSummary) {
      return _buildSummaryScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tedarikçi Dosyası - Ürün Kararları'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildProgressIndicator(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildProductDecisionCard(),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ürün ${currentProductIndex + 1} / $totalProducts',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$decidedCount karar verildi',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (currentProductIndex + 1) / totalProducts,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDecisionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductHeader(),
            const Divider(height: 32),
            _buildThreeOptions(),
            const SizedBox(height: 24),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2, size: 32, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentProduct.readProductName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentProduct.readStock} adet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeOptions() {
    final decision = decisions[currentProductIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bu ürün için ne yapmak istersiniz?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Option 1: Yeni Ürün Oluştur
        _buildOptionCard(
          title: 'YENI ÜRÜN OLUŞTUR',
          subtitle: 'Sistemde hiç olmayan yeni bir ürün ekle',
          icon: Icons.add_circle_outline,
          color: Colors.green,
          isSelected: decision?.action == DecisionAction.createNew,
          onTap: () => _selectAction(DecisionAction.createNew),
          expandedContent:
              decision?.action == DecisionAction.createNew
                  ? _NewProductForm(
                      product: currentProduct,
                      onSave: (data) => _saveDecision(
                        DecisionAction.createNew,
                        data,
                      ),
                    )
                  : null,
        ),

        const SizedBox(height: 12),

        // Option 2: Mevcut Ürüne Eşle
        _buildOptionCard(
          title: 'MEVCUT ÜRÜNE EŞLE',
          subtitle: currentProduct.similarProducts.isEmpty
              ? 'Benzer ürün bulunamadı'
              : '${currentProduct.similarProducts.length} benzer ürün bulundu',
          icon: Icons.link,
          color: Colors.blue,
          isSelected: decision?.action == DecisionAction.matchExisting,
          isEnabled: currentProduct.similarProducts.isNotEmpty,
          onTap: currentProduct.similarProducts.isNotEmpty
              ? () => _selectAction(DecisionAction.matchExisting)
              : null,
          expandedContent: decision?.action == DecisionAction.matchExisting
              ? _MatchExistingForm(
                  product: currentProduct,
                  onSave: (data) => _saveDecision(
                    DecisionAction.matchExisting,
                    data,
                  ),
                )
              : null,
        ),

        const SizedBox(height: 12),

        // Option 3: Mevcut Ürüne Yeni Varyant Ekle
        _buildOptionCard(
          title: 'MEVCUT ÜRÜNE YENİ VARYANT EKLE',
          subtitle: currentProduct.similarProducts.isEmpty
              ? 'Benzer ürün bulunamadı'
              : 'Var olan bir ürüne yeni varyant ekle',
          icon: Icons.playlist_add,
          color: Colors.orange,
          isSelected: decision?.action == DecisionAction.addVariant,
          isEnabled: currentProduct.similarProducts.isNotEmpty,
          onTap: currentProduct.similarProducts.isNotEmpty
              ? () => _selectAction(DecisionAction.addVariant)
              : null,
          expandedContent: decision?.action == DecisionAction.addVariant
              ? _AddVariantForm(
                  product: currentProduct,
                  onSave: (data) => _saveDecision(
                    DecisionAction.addVariant,
                    data,
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    bool isEnabled = true,
    VoidCallback? onTap,
    Widget? expandedContent,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: isSelected,
                    onChanged: isEnabled
                        ? (value) => onTap?.call()
                        : null,
                    activeColor: color,
                  ),
                  Icon(icon, color: isEnabled ? color : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isEnabled ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isEnabled ? Colors.grey[700] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (expandedContent != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: expandedContent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectAction(DecisionAction action) {
    setState(() {
      decisions[currentProductIndex] = ProductDecision(
        productIndex: currentProductIndex,
        action: action,
        data: {},
      );
    });
  }

  void _saveDecision(DecisionAction action, Map<String, dynamic> data) {
    setState(() {
      decisions[currentProductIndex] = ProductDecision(
        productIndex: currentProductIndex,
        action: action,
        data: data,
      );
    });
  }

  Widget _buildNavigationButtons() {
    final hasDecision = decisions.containsKey(currentProductIndex);

    return Row(
      children: [
        // Geri butonu
        if (!isFirstProduct)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  currentProductIndex--;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri'),
            ),
          ),
        if (!isFirstProduct) const SizedBox(width: 8),

        // Atla butonu
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              if (isLastProduct) {
                setState(() {
                  showSummary = true;
                });
              } else {
                setState(() {
                  currentProductIndex++;
                });
              }
            },
            child: const Text('Atla'),
          ),
        ),
        const SizedBox(width: 8),

        // Kaydet ve Devam butonu
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: hasDecision
                ? () {
                    if (isLastProduct) {
                      setState(() {
                        showSummary = true;
                      });
                    } else {
                      setState(() {
                        currentProductIndex++;
                      });
                    }
                  }
                : null,
            icon: Icon(isLastProduct ? Icons.check : Icons.arrow_forward),
            label: Text(isLastProduct ? 'Tamamla' : 'Kaydet ve Devam'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Özet - Kararlarınızı Gözden Geçirin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              showSummary = false;
            });
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.uploadResponse.products.length,
              itemBuilder: (context, index) {
                final product = widget.uploadResponse.products[index];
                final decision = decisions[index];

                return _buildSummaryCard(product, decision, index);
              },
            ),
          ),
          _buildSummaryFooter(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ReadProductItem product,
    ProductDecision? decision,
    int index,
  ) {
    IconData icon;
    Color color;
    String actionText;

    if (decision == null) {
      icon = Icons.warning_amber;
      color = Colors.orange;
      actionText = 'ATLANDI';
    } else {
      switch (decision.action) {
        case DecisionAction.createNew:
          icon = Icons.add_circle;
          color = Colors.green;
          actionText = 'YENİ ÜRÜN';
          break;
        case DecisionAction.matchExisting:
          icon = Icons.link;
          color = Colors.blue;
          actionText = 'MEVCUT ÜRÜNE EŞLE';
          break;
        case DecisionAction.addVariant:
          icon = Icons.playlist_add;
          color = Colors.orange;
          actionText = 'YENİ VARYANT';
          break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          product.readProductName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${product.readStock} adet'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                actionText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            setState(() {
              currentProductIndex = index;
              showSummary = false;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSummaryFooter() {
    final newProductCount = decisions.values
        .where((d) => d.action == DecisionAction.createNew)
        .length;
    final matchCount = decisions.values
        .where((d) => d.action == DecisionAction.matchExisting)
        .length;
    final variantCount = decisions.values
        .where((d) => d.action == DecisionAction.addVariant)
        .length;
    final skippedCount = totalProducts - decisions.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İşlem Özeti',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat('Yeni Ürün', newProductCount, Colors.green),
              _buildSummaryStat('Eşleşme', matchCount, Colors.blue),
              _buildSummaryStat('Yeni Varyant', variantCount, Colors.orange),
              _buildSummaryStat('Atlanan', skippedCount, Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: decisions.isNotEmpty ? _saveAllDecisions : null,
              icon: const Icon(Icons.save),
              label: const Text('KAYDET VE TAMAMLA'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  void _saveAllDecisions() {
    // TODO: Backend'e gönder
    // API call: POST /api/supplier-upload/save-decisions
    // Body: { decisions: [...] }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const _SuccessScreen(),
      ),
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

class _NewProductForm extends StatefulWidget {
  final ReadProductItem product;
  final Function(Map<String, dynamic>) onSave;

  const _NewProductForm({
    required this.product,
    required this.onSave,
  });

  @override
  State<_NewProductForm> createState() => _NewProductFormState();
}

class _NewProductFormState extends State<_NewProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product.readProductName;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ürün Adı',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Gerekli' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _brandController,
            decoration: const InputDecoration(
              labelText: 'Marka',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSave({
                  'name': _nameController.text,
                  'brand': _brandController.text,
                  'category': _categoryController.text,
                  'stock': widget.product.readStock,
                });
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}

class _MatchExistingForm extends StatefulWidget {
  final ReadProductItem product;
  final Function(Map<String, dynamic>) onSave;

  const _MatchExistingForm({
    required this.product,
    required this.onSave,
  });

  @override
  State<_MatchExistingForm> createState() => _MatchExistingFormState();
}

class _MatchExistingFormState extends State<_MatchExistingForm> {
  SimilarProduct? selectedProduct;
  ProductVariant? selectedVariant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Benzer Ürünler:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...widget.product.similarProducts.map((product) {
          return RadioListTile<SimilarProduct>(
            title: Text(product.name),
            subtitle: Text('${product.sku} - ${product.brand}'),
            value: product,
            groupValue: selectedProduct,
            onChanged: (value) {
              setState(() {
                selectedProduct = value;
                selectedVariant = null;
              });
            },
          );
        }),
        if (selectedProduct != null) ...[
          const SizedBox(height: 16),
          const Text(
            'Varyant Seçin:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...selectedProduct!.variants.map((variant) {
            return RadioListTile<ProductVariant>(
              title: Text(variant.name),
              subtitle: Text(variant.attributesText),
              value: variant,
              groupValue: selectedVariant,
              onChanged: (value) {
                setState(() {
                  selectedVariant = value;
                });
              },
            );
          }),
        ],
        if (selectedVariant != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.onSave({
                'productSku': selectedProduct!.sku,
                'variantSku': selectedVariant!.sku,
                'stockToAdd': widget.product.readStock,
              });
            },
            child: const Text('Kaydet'),
          ),
        ],
      ],
    );
  }
}

class _AddVariantForm extends StatefulWidget {
  final ReadProductItem product;
  final Function(Map<String, dynamic>) onSave;

  const _AddVariantForm({
    required this.product,
    required this.onSave,
  });

  @override
  State<_AddVariantForm> createState() => _AddVariantFormState();
}

class _AddVariantFormState extends State<_AddVariantForm> {
  SimilarProduct? selectedProduct;
  final _variantNameController = TextEditingController();
  final Map<String, String> attributes = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ürün Seçin:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...widget.product.similarProducts.map((product) {
          return RadioListTile<SimilarProduct>(
            title: Text(product.name),
            subtitle: Text('${product.sku} - ${product.brand}'),
            value: product,
            groupValue: selectedProduct,
            onChanged: (value) {
              setState(() {
                selectedProduct = value;
              });
            },
          );
        }),
        if (selectedProduct != null) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _variantNameController,
            decoration: const InputDecoration(
              labelText: 'Yeni Varyant Adı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Varyant Özellikleri:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Renk',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => attributes['renk'] = v,
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Beden',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => attributes['beden'] = v,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_variantNameController.text.isNotEmpty) {
                widget.onSave({
                  'productSku': selectedProduct!.sku,
                  'variantName': _variantNameController.text,
                  'attributes': attributes,
                  'stock': widget.product.readStock,
                });
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _variantNameController.dispose();
    super.dispose();
  }
}

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 24),
            const Text(
              'Başarıyla Kaydedildi!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tedarikçi dosyası işlendi.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

enum DecisionAction {
  createNew,
  matchExisting,
  addVariant,
}

class ProductDecision {
  final int productIndex;
  final DecisionAction action;
  final Map<String, dynamic> data;

  ProductDecision({
    required this.productIndex,
    required this.action,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'productIndex': productIndex,
      'action': action.toString().split('.').last,
      'data': data,
    };
  }
}
