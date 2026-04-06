import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'models/wizard_state.dart';
import 'steps/basic_info_step.dart';
import 'steps/variants_step.dart';
import 'steps/stock_barcode_step.dart';
import 'steps/images_step.dart';
import 'steps/preview_step.dart';

class AddProductWizardScreen extends ConsumerStatefulWidget {
  final bool fromBulkImport;
  final Map<String, dynamic>? importData;
  final String? tempId;

  const AddProductWizardScreen({
    super.key,
    this.fromBulkImport = false,
    this.importData,
    this.tempId,
  });

  @override
  ConsumerState<AddProductWizardScreen> createState() => _AddProductWizardScreenState();
}

class _AddProductWizardScreenState extends ConsumerState<AddProductWizardScreen> {
  int _currentStep = 0;
  final int _totalSteps = 5;
  late final WizardState _state;
  int _savedCount = 0;

  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _state = WizardState();
    _state.generateSKU();
    _state.initializeDefaultVariant();
    _state.loadDropdowns(ref);

    if (widget.fromBulkImport && widget.importData != null) {
      _state.populateFromImportData(widget.importData!);
    }
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _handleNext() {
    final error = _state.validateStep(_currentStep);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_currentStep == 1 && _state.variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Varyant oluşturulmadı, varsayılan varyant kullanılacak'), backgroundColor: AppColors.warning),
      );
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _handleSaveAndContinue() async {
    final retained = _state.captureRetainedFields();
    final success = await _state.handleSubmit(
      ref: ref,
      context: context,
      fromBulkImport: widget.fromBulkImport,
      tempId: widget.tempId,
      andContinue: true,
    );
    if (success && mounted) {
      setState(() {
        _savedCount++;
        _currentStep = 0;
      });
      _state.resetForNewProduct();
      _state.applyRetainedFields(retained);
    }
  }

  bool _hasUnsavedChanges() {
    return _state.productNameController.text.trim().isNotEmpty ||
        _state.variants.any((v) => v.barcodes.isNotEmpty) ||
        _state.oemNumbers.isNotEmpty;
  }

  void _handlePrevious() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _jumpToStep(int step) {
    if (step < _currentStep) setState(() => _currentStep = step);
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = ((_currentStep + 1) / _totalSteps) * 100;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasUnsavedChanges()) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Çıkmak istediğinize emin misiniz?'),
              content: Text(
                _savedCount > 0
                    ? '$_savedCount ürün kaydedildi. Mevcut formdaki değişiklikler kaybolacak.'
                    : 'Formdaki değişiklikler kaybolacak.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                  child: const Text('Çık', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          if (shouldPop == true && mounted) Navigator.pop(context, _savedCount > 0);
        } else {
          Navigator.pop(context, _savedCount > 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: _buildModernHeader(),
        body: Column(
          children: [
            _buildProgressBar(progressPercent),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(_isMobile ? 8 : 16),
                child: _buildStepContent(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildNavigationFooter(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return BasicInfoStep(state: _state, onChanged: _rebuild, isMobile: _isMobile);
      case 1:
        return VariantsStep(state: _state, onChanged: _rebuild, isMobile: _isMobile);
      case 2:
        return StockBarcodeStep(state: _state, onChanged: _rebuild, isMobile: _isMobile);
      case 3:
        return ImagesStep(state: _state, onChanged: _rebuild, isMobile: _isMobile);
      case 4:
        return PreviewStep(state: _state, isMobile: _isMobile);
      default:
        return const SizedBox();
    }
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildModernHeader() {
    final stepSubtitles = [
      'Ürün adı, kategori, fiyat',
      'Renk, beden, özellikler',
      'Depo, stok, tedarikçi',
      'Ürün resimleri',
      'Kontrol ve kayıt'
    ];

    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_savedCount > 0 ? 'Ürün Ekle ($_savedCount kaydedildi)' : 'Yeni Ürün Ekle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  'Adım ${_currentStep + 1} / $_totalSteps',
                  style: const TextStyle(color: Color(0xFF667eea), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stepSubtitles[_currentStep],
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // ─── Progress Bar ────────────────────────────────────────────────────────

  Widget _buildProgressBar(double percent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 12,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF764ba2)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '%${percent.round()} Tamamlandı',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step Indicator ──────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    if (_isMobile) return _buildMobileStepIndicator();
    return _buildDesktopStepIndicator();
  }

  Widget _buildMobileStepIndicator() {
    final stepData = [
      {'title': 'Tüm Bilgiler', 'icon': Icons.info, 'color': const Color(0xFF667eea)},
      {'title': 'Varyantlar', 'icon': Icons.layers, 'color': const Color(0xFF764ba2)},
      {'title': 'Barkod', 'icon': Icons.qr_code_2, 'color': const Color(0xFFf093fb)},
      {'title': 'Görseller', 'icon': Icons.image, 'color': const Color(0xFF4facfe)},
      {'title': 'Önizleme', 'icon': Icons.visibility, 'color': const Color(0xFF43e97b)},
    ];

    return Container(
      height: 75,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: stepData.length,
        itemBuilder: (context, index) {
          final step = stepData[index];
          final isCurrent = _currentStep == index;
          final isCompleted = _currentStep > index;
          final color = step['color'] as Color;

          return GestureDetector(
            onTap: () => _jumpToStep(index),
            child: Container(
              width: 68,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: isCurrent
                    ? LinearGradient(colors: [color, color.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: !isCurrent ? (isCompleted ? AppColors.success.withOpacity(0.1) : Colors.grey[100]) : null,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isCurrent ? color : isCompleted ? AppColors.success : Colors.grey[300]!, width: isCurrent ? 2 : 1.5),
                boxShadow: isCurrent ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent ? Colors.white.withOpacity(0.3) : isCompleted ? AppColors.success : Colors.grey[300],
                    ),
                    child: Icon(
                      isCompleted && !isCurrent ? Icons.check_circle : step['icon'] as IconData,
                      color: isCurrent ? Colors.white : isCompleted ? Colors.white : Colors.grey[600],
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      step['title'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isCurrent ? Colors.white : isCompleted ? AppColors.success : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopStepIndicator() {
    final stepData = [
      {'title': 'Temel\nBilgiler', 'icon': Icons.info, 'color': const Color(0xFF667eea)},
      {'title': 'Varyantlar', 'icon': Icons.layers, 'color': const Color(0xFF764ba2)},
      {'title': 'Stok &\nBarkod', 'icon': Icons.inventory_2, 'color': const Color(0xFFf093fb)},
      {'title': 'Görseller', 'icon': Icons.image, 'color': const Color(0xFF4facfe)},
      {'title': 'Önizleme', 'icon': Icons.visibility, 'color': const Color(0xFF43e97b)},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        children: [
          Row(
            children: List.generate(stepData.length, (index) {
              final step = stepData[index];
              final isCurrent = _currentStep == index;
              final isCompleted = _currentStep > index;
              final color = step['color'] as Color;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _jumpToStep(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: isCurrent
                          ? LinearGradient(colors: [color, color.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : null,
                      color: !isCurrent ? (isCompleted ? AppColors.success.withOpacity(0.1) : const Color(0xFFF8F9FA)) : null,
                      border: Border.all(color: isCurrent ? color : isCompleted ? AppColors.success : const Color(0xFFE9ECEF), width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isCurrent
                          ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 3))]
                          : isCompleted
                              ? [BoxShadow(color: AppColors.success.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
                              : [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent ? Colors.white.withOpacity(0.25) : isCompleted ? AppColors.success : const Color(0xFFE9ECEF),
                            border: Border.all(
                              color: isCurrent ? Colors.white.withOpacity(0.5) : isCompleted ? const Color(0xFF20C997) : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isCompleted && !isCurrent
                                ? [BoxShadow(color: AppColors.success.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Icon(
                            isCompleted && !isCurrent ? Icons.check_circle : step['icon'] as IconData,
                            color: isCurrent ? Colors.white : isCompleted ? Colors.white : const Color(0xFF6C757D),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                            color: isCurrent ? Colors.white : isCompleted ? AppColors.success : const Color(0xFF6C757D),
                            shadows: isCurrent ? [const Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))] : null,
                          ),
                          textAlign: TextAlign.center, maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Navigation Footer ───────────────────────────────────────────────────

  Widget _buildNavigationFooter() {
    return Container(
      padding: EdgeInsets.all(_isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFF667eea), width: _isMobile ? 2 : 3)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: _isMobile ? 4 : 8, offset: Offset(0, _isMobile ? -1 : -2))],
      ),
      child: SafeArea(
        child: _isMobile ? _buildMobileNavigation() : _buildDesktopNavigation(),
      ),
    );
  }

  Widget _buildMobileNavigation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(6)),
          child: Text(
            ['Temel Bilgiler', 'Varyantlar', 'Stok & Barkod', 'Görseller', 'Önizleme'][_currentStep],
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: _handlePrevious,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Geri', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 8),
            if (_currentStep < _totalSteps - 1)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _handleNext,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('İleri', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              )
            else ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _state.isSaving ? null : _handleSaveAndContinue,
                  icon: const Icon(Icons.add_circle_outline, size: 14),
                  label: const Text('Yeni Ekle', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _state.isSaving
                      ? null
                      : () => _state.handleSubmit(
                            ref: ref,
                            context: context,
                            fromBulkImport: false,
                          ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Kaydet', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step Info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adım ${_currentStep + 1}/$_totalSteps: ${['Temel Bilgiler', 'Varyantlar', 'Stok & Barkod', 'Görseller', 'Önizleme'][_currentStep]}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Navigation Buttons
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _handlePrevious,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Geri'),
            )
          else
            const SizedBox(width: 96),
          const SizedBox(width: 12),
          if (_currentStep < _totalSteps - 1)
            ElevatedButton.icon(
              onPressed: _handleNext,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('İleri'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            )
          else ...[
            if (_currentStep == _totalSteps - 1)
              OutlinedButton.icon(
                onPressed: _state.isSaving ? null : _handleSaveAndContinue,
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Yeni Ekle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _state.isSaving
                  ? null
                  : () => _state.handleSubmit(
                        ref: ref,
                        context: context,
                        fromBulkImport: false,
                      ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
          ],
        ],
      ),
    );
  }
}
