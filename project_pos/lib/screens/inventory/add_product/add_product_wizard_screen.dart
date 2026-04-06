import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import '../../../providers/sector_provider.dart';
import 'models/wizard_state.dart';
import 'steps/basic_info_step.dart';
import 'steps/variants_stock_step.dart';
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
  ConsumerState<AddProductWizardScreen> createState() =>
      _AddProductWizardScreenState();
}

class _AddProductWizardScreenState
    extends ConsumerState<AddProductWizardScreen> {
  int _currentStep = 0;
  static const _totalSteps = 3;
  late final WizardState _state;
  int _savedCount = 0;

  final _stepTitles = const ['Ürün Bilgileri', 'Varyant & Stok', 'Önizleme'];
  final _stepIcons = const [
    Icons.inventory_2_rounded,
    Icons.layers_rounded,
    Icons.preview_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _state = WizardState();

    // Sektörü kullanıcı bilgisinden otomatik al
    _state.sectorType = ref.read(sectorTypeProvider);

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

  void _next() {
    final error = _state.validateStep(_currentStep);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_currentStep == 1 &&
        _state.productType == 'variant' &&
        _state.variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Varyant oluşturulmadı, varsayılan varyant kullanılacak'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _saveAndContinue() async {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

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
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  child: const Text('Çık'),
                ),
              ],
            ),
          );
          if (shouldPop == true && mounted) {
            Navigator.pop(context, _savedCount > 0);
          }
        } else {
          Navigator.pop(context, _savedCount > 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _savedCount > 0
                    ? 'Ürün Ekle ($_savedCount kaydedildi)'
                    : 'Yeni Ürün Ekle',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '${_stepTitles[_currentStep]} — Adım ${_currentStep + 1}/$_totalSteps',
                style: TextStyle(
                    fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: _buildStepBar(theme),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: SingleChildScrollView(
            key: ValueKey(_currentStep),
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: _buildStep(isMobile),
          ),
        ),
        bottomNavigationBar: _buildFooter(theme, isMobile),
      ),
    );
  }

  Widget _buildStepBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepBefore = i ~/ 2;
            final isDone = _currentStep > stepBefore;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone
                    ? AppColors.primary
                    : theme.colorScheme.outlineVariant,
              ),
            );
          }
          final step = i ~/ 2;
          final isCurrent = step == _currentStep;
          final isDone = step < _currentStep;
          return GestureDetector(
            onTap: step < _currentStep ? () => setState(() => _currentStep = step) : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? AppColors.primary
                    : isDone
                        ? AppColors.success
                        : theme.colorScheme.surfaceContainerHighest,
                border: isCurrent
                    ? Border.all(color: AppColors.primaryLight, width: 2)
                    : null,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : _stepIcons[step],
                size: 18,
                color: (isCurrent || isDone)
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep(bool isMobile) {
    switch (_currentStep) {
      case 0:
        return BasicInfoStep(
            state: _state, onChanged: _rebuild, isMobile: isMobile);
      case 1:
        return VariantsStockStep(
            state: _state, onChanged: _rebuild, isMobile: isMobile);
      case 2:
        return PreviewStep(state: _state, isMobile: isMobile);
      default:
        return const SizedBox();
    }
  }

  Widget _buildFooter(ThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            if (_currentStep > 0)
              OutlinedButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(isMobile ? 'Geri' : 'Önceki Adım'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 20, vertical: 12),
                ),
              ),
            const Spacer(),
            // Forward / Save buttons
            if (_currentStep < _totalSteps - 1)
              FilledButton.icon(
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(isMobile ? 'İleri' : 'Sonraki Adım'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24, vertical: 12),
                ),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: _state.isSaving ? null : _saveAndContinue,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(isMobile ? 'Yeni' : 'Kaydet & Yeni Ekle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _state.isSaving
                    ? null
                    : () => _state.handleSubmit(
                          ref: ref,
                          context: context,
                          fromBulkImport: false,
                        ),
                icon: _state.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(_state.isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}