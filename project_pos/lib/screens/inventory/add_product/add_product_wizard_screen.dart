import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/config/sector_config.dart';
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
    extends ConsumerState<AddProductWizardScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  static const _totalSteps = 3;
  late final WizardState _state;
  int _savedCount = 0;

  String Function(String) get _t => i18nOf(ref);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  List<String> _stepTitles = const ['', '', ''];
  final _stepIcons = const [
    Icons.inventory_2_rounded,
    Icons.layers_rounded,
    Icons.preview_rounded,
  ];

  Color get _accentColor => switch (_state.sectorType) {
    SectorType.autoParts => AppColors.orange,
    SectorType.footwear => AppColors.pink,
    SectorType.technology => AppColors.info,
    SectorType.general => AppColors.primary,
  };

  IconData get _sectorIcon => switch (_state.sectorType) {
    SectorType.autoParts => Icons.build_circle_rounded,
    SectorType.footwear => Icons.checkroom_rounded,
    SectorType.technology => Icons.devices_rounded,
    SectorType.general => Icons.store_rounded,
  };

  @override
  void initState() {
    super.initState();
    _state = WizardState();

    // Sektoru kullanici bilgisinden otomatik al
    _state.sectorType = ref.read(sectorTypeProvider);

    _state.generateSKU();
    _state.initializeDefaultVariant();
    _state.loadDropdowns(ref);

    if (widget.fromBulkImport && widget.importData != null) {
      _state.populateFromImportData(widget.importData!);
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _state.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _next() {
    final error = _state.validateStep(_currentStep);
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    if (_currentStep == 1 &&
        _state.productType == 'variant' &&
        _state.variants.isEmpty) {
      AppToast.warning(context, _t('wizard.no_variant_created_default_used'));
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
    final sectorConfig = ref.watch(sectorConfigProvider);
    _stepTitles = [_t('wizard.product_info'), _t('wizard.variant_stock'), _t('wizard.preview')];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasUnsavedChanges()) {
          final shouldPop = await AppConfirmationDialog.showWarning(
            context: context,
            title: _t('common.are_you_sure'),
            message: _savedCount > 0
                ? '$_savedCount ${_t('wizard.products_saved_changes_lost')}'
                : _t('wizard.changes_will_be_lost'),
          );
          if (shouldPop && mounted) {
            Navigator.pop(context, _savedCount > 0);
          }
        } else {
          Navigator.pop(context, _savedCount > 0);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _savedCount > 0
                          ? '${_t('product.add_product')} ($_savedCount ${_t('wizard.saved')})'
                          : _t('product.add_new_product'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      '${_stepTitles[_currentStep]} — ${_t('wizard.step')} ${_currentStep + 1}/$_totalSteps',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              _buildSectorBadge(sectorConfig),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(78),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStepBar(theme),
                Container(height: 2, color: _accentColor),
              ],
            ),
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

  Widget _buildSectorBadge(SectorConfig sectorConfig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_sectorIcon, size: 14, color: _accentColor),
          const SizedBox(width: 5),
          Text(
            _state.sectorType.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepBefore = i ~/ 2;
            final isDone = _currentStep > stepBefore;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  gradient: isDone
                      ? LinearGradient(
                          colors: [_accentColor, _accentColor.withOpacity(0.6)])
                      : null,
                  color: isDone ? null : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final step = i ~/ 2;
          final isCurrent = step == _currentStep;
          final isDone = step < _currentStep;
          return GestureDetector(
            onTap: step < _currentStep
                ? () => setState(() => _currentStep = step)
                : null,
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isDone
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.success,
                                AppColors.success.withOpacity(0.8),
                              ],
                            )
                          : null,
                      color: isCurrent
                          ? _accentColor
                          : isDone
                              ? null
                              : theme.colorScheme.surfaceContainerHighest,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: _accentColor.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                      border: isCurrent
                          ? Border.all(
                              color: _accentColor.withOpacity(0.3), width: 2.5)
                          : null,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white)
                          : isCurrent
                              ? Icon(_stepIcons[step],
                                  size: 17, color: Colors.white)
                              : Text(
                                  '${step + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stepTitles[step],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? _accentColor
                          : isDone
                              ? AppColors.success
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border:
            Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            if (_currentStep > 0)
              OutlinedButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(isMobile ? _t('common.back') : _t('wizard.previous_step')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(
                      color: theme.colorScheme.outlineVariant),
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            const Spacer(),
            // Saved count badge
            if (_savedCount > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.bgSuccess,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '$_savedCount ${_t('product.product')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            // Forward / Save buttons
            if (!isLastStep)
              FilledButton.icon(
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(isMobile ? _t('common.next') : _t('wizard.next_step')),
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: _state.isSaving ? null : _saveAndContinue,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(isMobile ? _t('common.new') : _t('wizard.save_and_add_new')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accentColor,
                  side: BorderSide(color: _accentColor),
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ScaleTransition(
                scale: _pulseAnimation,
                child: FilledButton.icon(
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
                  label:
                      Text(_state.isSaving ? _t('common.saving') : _t('common.save')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
