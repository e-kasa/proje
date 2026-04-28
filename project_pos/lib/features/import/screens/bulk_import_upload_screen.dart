import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/config/sector_config.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/providers/sector_provider.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

/// Profesyonel Toplu Ürün Yükleme Ekranı
/// Sektör bazlı şablon desteği + Gerçek dosya yükleme
class BulkImportUploadScreen extends ConsumerStatefulWidget {
  const BulkImportUploadScreen({super.key});

  @override
  ConsumerState<BulkImportUploadScreen> createState() => _BulkImportUploadScreenState();
}

class _BulkImportUploadScreenState extends ConsumerState<BulkImportUploadScreen>
    with SingleTickerProviderStateMixin {
  String Function(String) get t => i18nOf(ref);

  // ── State ──
  bool _isUploading = false;
  bool _uploadSuccess = false;
  double _uploadProgress = 0.0;
  String _currentStep = '';
  String? _fileName;
  String? _errorMessage;
  bool _isDragging = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // ── Sector (kullanıcıdan otomatik) ──
  SectorType get _sectorType => ref.watch(sectorTypeProvider);

  String get _selectedSector => switch (_sectorType) {
    SectorType.autoParts  => 'parcaci',
    SectorType.footwear   => 'giyim',
    SectorType.technology => 'genel',
    SectorType.general    => 'genel',
  };

  String get _sectorLabel => _sectorType.displayName;

  // ── Sector configs ──
  static const _sectors = [
    {
      'key': 'parcaci',
      'label': 'Oto Parça',
      'icon': Icons.build_circle_outlined,
      'color': AppColors.orange,
      'desc': 'OEM, çapraz referans, araç uyumluluğu',
    },
    {
      'key': 'giyim',
      'label': 'Giyim',
      'icon': Icons.checkroom,
      'color': AppColors.purple,
      'desc': 'Beden, renk, kumaş, sezon',
    },
    {
      'key': 'genel',
      'label': 'Genel',
      'icon': Icons.inventory_2_outlined,
      'color': AppColors.info,
      'desc': 'Standart ürün yükleme',
    },
  ];

  // ── Sector-specific template columns ──
  static const _templateColumns = {
    'parcaci': [
      'SKU', 'Barkod', 'Ürün Adı', 'Marka', 'Kategori',
      'Alış Fiyatı', 'Satış Fiyatı', 'Stok', 'Birim',
      'OEM No', 'OEM Üretici', 'Çapraz Ref No', 'Çapraz Ref Marka',
      'Raf Kodu', 'Araç Grubu',
    ],
    'giyim': [
      'SKU', 'Barkod', 'Ürün Adı', 'Marka', 'Kategori',
      'Alış Fiyatı', 'Satış Fiyatı', 'Stok', 'Birim',
      'Renk', 'Beden', 'Kumaş', 'Sezon',
    ],
    'genel': [
      'SKU', 'Barkod', 'Ürün Adı', 'Marka', 'Kategori',
      'Alış Fiyatı', 'Satış Fiyatı', 'Stok', 'Birim',
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // FILE PICK & UPLOAD
  // ═══════════════════════════════════════════════════════════

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf'],
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      if (pickedFile.path == null) return;

      setState(() {
        _fileName = pickedFile.name;
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadSuccess = false;
        _errorMessage = null;
        _currentStep = t('bulk_import.step_preparing'); // TODO: i18n
      });

      // ── Step 1: Upload file ──
      setState(() {
        _uploadProgress = 0.15;
        _currentStep = t('bulk_import.step_uploading'); // TODO: i18n
      });

      final service = ref.read(bulkImportServiceProvider);
      final file = File(pickedFile.path!);

      // Upload with sector info
      final importId = await service.uploadFile(file, sector: _selectedSector);

      setState(() {
        _uploadProgress = 0.45;
        _currentStep = t('bulk_import.step_analyzing'); // TODO: i18n
      });

      // ── Step 2: Wait for analysis ──
      await service.waitForAnalysis(importId: importId);

      setState(() {
        _uploadProgress = 0.85;
        _currentStep = t('bulk_import.step_processing'); // TODO: i18n
      });

      await Future.delayed(const Duration(milliseconds: 400));

      setState(() {
        _uploadProgress = 1.0;
        _currentStep = t('bulk_import.step_done'); // TODO: i18n
        _uploadSuccess = true;
        _isUploading = false;
      });

      // Navigate to review screen
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        context.go('/bulk-import/review', extra: {
          'importId': importId,
          'sector': _selectedSector,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _currentStep = '';
        });
      }
    }
  }

  void _resetUpload() {
    setState(() {
      _isUploading = false;
      _uploadSuccess = false;
      _uploadProgress = 0.0;
      _currentStep = '';
      _fileName = null;
      _errorMessage = null;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppAppBar.standard(
        title: t('bulk_import.upload'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step Indicator
                  _buildStepIndicator(),
                  const SizedBox(height: 28),

                  // Sector Info Banner (otomatik)
                  _buildSectorBanner(),
                  const SizedBox(height: 24),

                  // Upload Zone / Progress / Success / Error
                  _buildMainContent(),
                  const SizedBox(height: 28),

                  // Template Section (sector-aware)
                  _buildTemplateSection(),
                  const SizedBox(height: 20),

                  // Column Preview
                  _buildColumnPreview(),
                  const SizedBox(height: 20),

                  // Supported Formats
                  _buildSupportedFormats(),
                  const SizedBox(height: 20),

                  // Tips
                  _buildTipsSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STEP INDICATOR
  // ═══════════════════════════════════════════════════════════

  Widget _buildStepIndicator() {
    final steps = [
      {'num': 1, 'label': t('bulk_import.upload'), 'active': true, 'done': _uploadSuccess}, // TODO: i18n
      {'num': 2, 'label': t('bulk_import.review'), 'active': false, 'done': false}, // TODO: i18n
      {'num': 3, 'label': t('common.save'), 'active': false, 'done': false},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _buildStepItem(
              steps[i]['num'] as int,
              steps[i]['label'] as String,
              steps[i]['active'] as bool,
              steps[i]['done'] as bool,
            ),
            if (i < steps.length - 1)
              Container(
                width: 48,
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: (steps[i]['done'] as bool) ? AppColors.success : AppColors.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String label, bool isActive, bool isDone) {
    final color = isDone
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : AppColors.textMuted;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.success
                : isActive
                    ? AppColors.primary
                    : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTOR BANNER (otomatik — kullanıcı sektörüne göre)
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectorBanner() {
    final sector = _sectors.firstWhere(
      (s) => s['key'] == _selectedSector,
      orElse: () => _sectors.last,
    );
    final color = sector['color'] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(sector['icon'] as IconData, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sectorLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sector['desc'] as String,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Otomatik',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MAIN CONTENT (Upload / Progress / Success / Error)
  // ═══════════════════════════════════════════════════════════

  Widget _buildMainContent() {
    if (_errorMessage != null) return _buildErrorState();
    if (_uploadSuccess) return _buildSuccessState();
    if (_isUploading) return _buildUploadProgress();
    return _buildUploadZone();
  }

  Widget _buildUploadZone() {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isDragging = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isDragging = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
          decoration: BoxDecoration(
            color: _isDragging ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragging ? AppColors.primary : AppColors.border,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            boxShadow: [
              BoxShadow(
                color: _isDragging
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isDragging ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isDragging ? t('bulk_import.drop_file_here') : t('bulk_import.drag_or_select'), // TODO: i18n
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t('bulk_import.supported_formats'), // TODO: i18n
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              _buildSectorBadge(),
              const SizedBox(height: 20),
              AppButton.primary(
                text: t('bulk_import.select_file'), // TODO: i18n
                icon: Icons.folder_open,
                onPressed: _pickAndUpload,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectorBadge() {
    final sector = _sectors.firstWhere((s) => s['key'] == _selectedSector);
    final color = sector['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sector['icon'] as IconData, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            t('bulk_import.sector_template_label'), // TODO: i18n
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // File name
          if (_fileName != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insert_drive_file, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _fileName!,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Circular progress
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 5,
                  backgroundColor: AppColors.bgLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                Text(
                  '${(_uploadProgress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _currentStep,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),

          // Linear progress
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppColors.bgLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),

          // Step checklist
          _buildProgressSteps(),

          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _resetUpload,
            icon: const Icon(Icons.close, size: 16),
            label: Text(t('common.cancel')),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      {'title': t('bulk_import.step_file_upload'), 'done': _uploadProgress >= 0.3}, // TODO: i18n
      {'title': t('bulk_import.step_backend_analysis'), 'done': _uploadProgress >= 0.6}, // TODO: i18n
      {'title': t('bulk_import.step_product_processing'), 'done': _uploadProgress >= 0.9}, // TODO: i18n
    ];

    return Column(
      children: steps.map((step) {
        final isDone = step['done'] as bool;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDone ? AppColors.success : AppColors.border,
                size: 18,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDone ? AppColors.textPrimary : AppColors.textMuted,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuccessState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.success.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, size: 52, color: AppColors.success),
          ),
          const SizedBox(height: 20),
          Text(
            t('bulk_import.upload_success'), // TODO: i18n
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            t('bulk_import.redirecting_review'), // TODO: i18n
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppColors.success)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 44, color: AppColors.danger),
          ),
          const SizedBox(height: 16),
          Text(
            t('bulk_import.upload_failed'), // TODO: i18n
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDanger,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage ?? t('common.error'), // TODO: i18n
                    style: const TextStyle(fontSize: 13, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _resetUpload,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(t('bulk_import.retry')), // TODO: i18n
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TEMPLATE SECTION (Sector-aware)
  // ═══════════════════════════════════════════════════════════

  Widget _buildTemplateSection() {
    final sector = _sectors.firstWhere((s) => s['key'] == _selectedSector);
    final color = sector['color'] as Color;
    final label = sector['label'] as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.download_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('bulk_import.excel_template'), // TODO: i18n
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  t('bulk_import.download_template_desc'), // TODO: i18n
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _downloadTemplate(),
            icon: const Icon(Icons.file_download, size: 18),
            label: Text(t('common.import')), // TODO: i18n download
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadTemplate() {
    final sector = _sectors.firstWhere((s) => s['key'] == _selectedSector);
    AppToast.success(context, t('bulk_import.template_downloading')); // TODO: i18n
    // TODO: Call backend to download sector-specific template
    // ref.read(bulkImportServiceProvider).downloadTemplate(_selectedSector);
  }

  // ═══════════════════════════════════════════════════════════
  // COLUMN PREVIEW
  // ═══════════════════════════════════════════════════════════

  Widget _buildColumnPreview() {
    final columns = _templateColumns[_selectedSector] ?? _templateColumns['genel']!;
    final baseColumns = _templateColumns['genel']!;
    final sectorColumns = columns.where((c) => !baseColumns.contains(c)).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_column_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                t('bulk_import.template_columns'), // TODO: i18n
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${columns.length} kolon',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: columns.map((col) {
              final isSectorSpecific = sectorColumns.contains(col);
              final sector = _sectors.firstWhere((s) => s['key'] == _selectedSector);
              final sectorColor = sector['color'] as Color;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSectorSpecific ? sectorColor.withValues(alpha: 0.1) : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSectorSpecific ? sectorColor.withValues(alpha: 0.3) : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSectorSpecific) ...[
                      Icon(Icons.star, size: 12, color: sectorColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      col,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSectorSpecific ? FontWeight.w600 : FontWeight.w500,
                        color: isSectorSpecific ? sectorColor : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (sectorColumns.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.star, size: 12, color: (_sectors.firstWhere((s) => s['key'] == _selectedSector)['color'] as Color)),
                const SizedBox(width: 4),
                Text(
                  t('bulk_import.sector_specific_columns'), // TODO: i18n
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SUPPORTED FORMATS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSupportedFormats() {
    final formats = [
      {'icon': Icons.table_chart, 'name': 'Excel', 'ext': '.xlsx, .xls', 'color': Colors.green},
      {'icon': Icons.description, 'name': 'CSV', 'ext': '.csv', 'color': Colors.blue},
      {'icon': Icons.picture_as_pdf, 'name': 'PDF', 'ext': '.pdf', 'color': Colors.red},
    ];

    return Row(
      children: formats.map((f) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(f['icon'] as IconData, size: 28, color: f['color'] as Color),
                const SizedBox(height: 6),
                Text(
                  f['name'] as String,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  f['ext'] as String,
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TIPS SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildTipsSection() {
    final tips = _getTipsForSector();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 22),
              const SizedBox(width: 10),
              Text(
                t('bulk_import.tips'), // TODO: i18n
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tip['icon'] as IconData, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        tip['desc'] as String,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getTipsForSector() {
    final baseTips = <Map<String, dynamic>>[
      {'icon': Icons.check_circle_outline, 'title': 'Zorunlu Alanlar', 'desc': 'SKU, Ürün Adı ve en az bir fiyat alanı zorunludur'},
      {'icon': Icons.speed, 'title': 'Hızlı İşlem', 'desc': 'Backend 1000+ ürünü saniyeler içinde işler'},
      {'icon': Icons.link, 'title': 'Otomatik Eşleştirme', 'desc': 'Mevcut ürünler SKU/barkod ile otomatik tespit edilir'},
    ];

    switch (_selectedSector) {
      case 'parcaci':
        baseTips.addAll([
          {'icon': Icons.build_outlined, 'title': 'OEM Numarası', 'desc': 'Her satıra birden fazla OEM numarası yazabilirsiniz (virgülle ayırın)'},
          {'icon': Icons.swap_horiz, 'title': 'Çapraz Referans', 'desc': 'Muadil markaları "Çapraz Ref" kolonunda belirtin'},
          {'icon': Icons.shelves, 'title': 'Raf Kodu', 'desc': 'Raf kodu ile parçanın fiziksel konumunu belirleyin'},
        ]);
        break;
      case 'giyim':
        baseTips.addAll([
          {'icon': Icons.palette_outlined, 'title': 'Renk & Beden', 'desc': 'Her renk-beden kombinasyonu ayrı satır olmalıdır'},
          {'icon': Icons.checkroom_outlined, 'title': 'Kumaş Bilgisi', 'desc': 'Kumaş türü varyantlar arası ortaktır, ürün seviyesinde girilir'},
        ]);
        break;
      default:
        baseTips.add(
          {'icon': Icons.edit_outlined, 'title': 'Düzenleme', 'desc': 'Yüklenen ürünleri inceleyip düzenleyebilirsiniz'},
        );
    }

    return baseTips;
  }

  // ═══════════════════════════════════════════════════════════
  // HELP DIALOG
  // ═══════════════════════════════════════════════════════════

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: AppColors.info),
            const SizedBox(width: 12),
            Text(t('bulk_import.how_it_works'), style: const TextStyle(fontSize: 18)), // TODO: i18n
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _helpStep('1', 'Sektör Seçin', 'Ürün tipinize uygun sektörü seçin. Bu, şablon kolonlarını ve analiz kurallarını belirler.'),
              _helpStep('2', 'Dosya Yükleyin', 'Excel, CSV veya PDF dosyanızı yükleyin. Sektör şablonunu indirip doldurmanız önerilir.'),
              _helpStep('3', 'İnceleme', 'Backend dosyayı analiz eder. Yeni ürünler, çakışmalar ve eşleşmeler tespit edilir.'),
              _helpStep('4', 'Karar & Kayıt', 'Her ürün için karar verin: oluştur, güncelle, eşleştir veya atla. Onayladıklarınız kaydedilir.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('bulk_import.got_it')), // TODO: i18n
          ),
        ],
      ),
    );
  }

  Widget _helpStep(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}