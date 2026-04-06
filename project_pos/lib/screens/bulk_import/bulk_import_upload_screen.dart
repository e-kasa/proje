import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';

/// Profesyonel Toplu Ürün Yükleme Ekranı - Adım 1: Dosya Yükleme
class BulkImportUploadScreen extends StatefulWidget {
  const BulkImportUploadScreen({super.key});

  @override
  State<BulkImportUploadScreen> createState() => _BulkImportUploadScreenState();
}

class _BulkImportUploadScreenState extends State<BulkImportUploadScreen> with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  bool _uploadSuccess = false;
  double _uploadProgress = 0.0;
  String _currentStep = '';
  bool _isDragging = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadSuccess = false;
      _currentStep = 'Dosya yükleniyor...';
    });

    // Simulate file upload with backend steps
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _uploadProgress = i / 100;
          if (i < 30) {
            _currentStep = 'Dosya yükleniyor... ${i}%';
          } else if (i < 60) {
            _currentStep = 'Backend analiz ediyor...';
          } else if (i < 90) {
            _currentStep = 'Ürünler işleniyor...';
          } else {
            _currentStep = 'Tamamlanıyor...';
          }
        });
      }
    }

    // Success animation
    if (mounted) {
      setState(() {
        _uploadSuccess = true;
        _currentStep = 'Başarıyla tamamlandı!';
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        // Use addPostFrameCallback to navigate after build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/bulk-import/review');
          }
        });
      }
    }
  }

  void _onDragEnter() {
    setState(() => _isDragging = true);
    _animationController.forward();
  }

  void _onDragExit() {
    setState(() => _isDragging = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppAppBar.standard(
        title: 'Toplu Ürün Yükleme',
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Step Indicator
            _buildStepIndicator(),

            const SizedBox(height: 32),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Hero Section
                  _buildHeroSection(),

                  const SizedBox(height: 32),

                  // Upload Zone
                  if (!_isUploading && !_uploadSuccess)
                    _buildUploadZone()
                  else if (_isUploading)
                    _buildUploadProgress()
                  else if (_uploadSuccess)
                    _buildSuccessState(),

                  const SizedBox(height: 32),

                  // Supported Formats
                  _buildSupportedFormats(),

                  const SizedBox(height: 24),

                  // Template Download
                  _buildTemplateSection(),

                  const SizedBox(height: 24),

                  // Tips & Guidelines
                  _buildTipsSection(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem(1, 'Dosya Yükle', true),
          _buildStepConnector(false),
          _buildStepItem(2, 'İncele & Düzenle', false),
          _buildStepConnector(false),
          _buildStepItem(3, 'Kaydet', false),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.bgLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isCompleted ? AppColors.primary : AppColors.border,
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 64,
          color: AppColors.primary.withOpacity(0.8),
        ),
        const SizedBox(height: 16),
        const Text(
          'Toplu Ürün İçe Aktarma',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'PDF, Excel veya CSV dosyanızı yükleyin.\nBackend otomatik olarak ürünleri işleyecek ve size sunacak.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadZone() {
    return MouseRegion(
      onEnter: (_) => _onDragEnter(),
      onExit: (_) => _onDragExit(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: _isDragging
                ? AppColors.primary.withOpacity(0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragging ? AppColors.primary : AppColors.border,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            boxShadow: _isDragging
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.upload_file,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isDragging
                    ? 'Dosyayı buraya bırakın'
                    : 'Dosyayı sürükleyin veya seçin',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PDF, Excel (.xlsx, .xls) veya CSV formatı desteklenir',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                text: 'Dosya Seç',
                icon: Icons.folder_open,
                onPressed: _pickFile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: _uploadProgress,
              strokeWidth: 6,
              backgroundColor: AppColors.bgLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _currentStep,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: AppColors.bgLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressSteps(),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      {'title': 'Dosya Yükleme', 'progress': _uploadProgress >= 0.3},
      {'title': 'Backend Analizi', 'progress': _uploadProgress >= 0.6},
      {'title': 'Ürün İşleme', 'progress': _uploadProgress >= 0.9},
    ];

    return Column(
      children: steps.map((step) {
        final isCompleted = step['progress'] as bool;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? AppColors.success : AppColors.border,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                step['title'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: isCompleted ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
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
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Yükleme Başarılı!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ürünler başarıyla işlendi. İnceleme ekranına yönlendiriliyorsunuz...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedFormats() {
    final formats = [
      {'icon': Icons.picture_as_pdf, 'name': 'PDF', 'color': Colors.red},
      {'icon': Icons.table_chart, 'name': 'Excel', 'color': Colors.green},
      {'icon': Icons.description, 'name': 'CSV', 'color': Colors.blue},
    ];

    return Column(
      children: [
        const Text(
          'Desteklenen Formatlar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: formats.map((format) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    format['icon'] as IconData,
                    size: 32,
                    color: format['color'] as Color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    format['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTemplateSection() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.download,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Excel Şablonu İndir',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Örnek Excel şablonunu indirerek kolayca ürünlerinizi ekleyin',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AppButton.success(
            text: 'İndir',
            icon: Icons.file_download,
            size: ButtonSize.small,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Şablon indiriliyor...'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = [
      {
        'icon': Icons.check_circle_outline,
        'title': 'Doğru Format',
        'desc': 'SKU, Barkod, İsim, Fiyat alanları zorunludur',
      },
      {
        'icon': Icons.speed,
        'title': 'Hızlı İşlem',
        'desc': 'Backend 1000+ ürünü saniyeler içinde işler',
      },
      {
        'icon': Icons.edit,
        'title': 'Düzenleme',
        'desc': 'Yüklenen ürünleri inceleyip düzenleyebilirsiniz',
      },
      {
        'icon': Icons.link,
        'title': 'Otomatik Eşleştirme',
        'desc': 'Mevcut ürünler otomatik tespit edilir',
      },
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.all(24),
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
              Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 24),
              const SizedBox(width: 12),
              const Text(
                'İpuçları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    tip['icon'] as IconData,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tip['desc'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.info),
            SizedBox(width: 12),
            Text('Nasıl Çalışır?'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Dosya Yükleme',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('PDF, Excel veya CSV dosyanızı yükleyin.'),
              SizedBox(height: 16),
              Text(
                '2. Backend İşleme',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Sistemimiz dosyayı analiz eder ve ürün bilgilerini çıkarır.'),
              SizedBox(height: 16),
              Text(
                '3. İnceleme & Düzenleme',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Çıkarılan ürünleri inceleyin, hataları düzeltin, çakışmaları çözümleyin.'),
              SizedBox(height: 16),
              Text(
                '4. Kaydetme',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Onayladığınız ürünler sisteme kaydedilir.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}
