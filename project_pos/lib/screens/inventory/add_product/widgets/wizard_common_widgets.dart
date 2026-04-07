import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Wizard genelinde kullanilan ortak widget'lar.
// Tum fonksiyonlar mevcut API imzalariyla geriye uyumludur.
// ---------------------------------------------------------------------------

/// Form alani olusturucu - etiket, zorunluluk isareti ve opsiyonel ikon destegi.
Widget buildFormField({
  required String label,
  bool required = false,
  required Widget child,
  IconData? icon,
  Color? iconColor,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 14,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          if (required)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.5 + (value * 0.5),
                    child: child,
                  ),
                );
              },
              child: const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

/// Standart input dekorasyonu - tum adimlar genelinde kullanilir.
/// [isDense] ile kompakt gorunum, hata border'i otomatik olarak eklenir.
InputDecoration inputDecoration(String hint, {bool isDense = false}) {
  final radius = BorderRadius.circular(8);

  return InputDecoration(
    hintText: hint,
    filled: true,
    isDense: isDense,
    fillColor: AppColors.bgLight,
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: AppColors.primary.withOpacity(0.8),
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.danger, width: 2),
    ),
    errorStyle: const TextStyle(
      color: AppColors.danger,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: isDense ? 8 : 12,
    ),
    hintStyle: TextStyle(
      fontSize: 13,
      color: AppColors.textMuted.withOpacity(0.7),
    ),
  );
}

/// Istatistik karti - Adim 3'te kullanilir.
/// [icon] parametresi ile temiz ikon tasarimi, arka planda dusuk opaklikli
/// watermark ikon gosterir.
Widget buildStatCard(
  String label,
  String value,
  Color color, {
  required bool isMobile,
  IconData? icon,
}) {
  // Eski emoji parsing kaldirildi - label temiz metin olarak kullanilir
  final cleanLabel = label.replaceAll('\n', ' ').trim();

  return Container(
    padding: EdgeInsets.all(isMobile ? 4 : 6),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withOpacity(0.10), color.withOpacity(0.03)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
      border: Border.all(color: color.withOpacity(0.25), width: 1),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: isMobile ? 3 : 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Stack(
      children: [
        // Arka plan watermark ikonu
        if (icon != null)
          Positioned(
            right: isMobile ? -6 : -8,
            bottom: isMobile ? -6 : -8,
            child: Icon(
              icon,
              size: isMobile ? 28 : 36,
              color: color.withOpacity(0.07),
            ),
          ),
        // Icerik
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: isMobile ? 12 : 16,
                  color: color.withOpacity(0.7),
                ),
                SizedBox(height: isMobile ? 1 : 2),
              ],
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 1 : 2),
              Text(
                cleanLabel,
                style: TextStyle(
                  fontSize: isMobile ? 7 : 8,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Responsive istatistik grid'i - Adim 3'te kullanilir.
Widget buildResponsiveStatGrid(
  List<Map<String, dynamic>> statCards, {
  required bool isMobile,
}) {
  final crossAxisCount = isMobile ? 3 : 6;

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: isMobile ? 1.2 : 1.6,
      crossAxisSpacing: isMobile ? 4 : 6,
      mainAxisSpacing: isMobile ? 4 : 6,
    ),
    itemCount: statCards.length,
    itemBuilder: (context, index) {
      final card = statCards[index];
      return buildStatCard(
        card['label'] as String,
        card['value'] as String,
        card['color'] as Color,
        isMobile: isMobile,
        icon: card['icon'] as IconData?,
      );
    },
  );
}

/// Ozet karti - Adim 5 onizlemede kullanilir.
/// Gradient arka plan, watermark ikon destegi.
Widget buildSummaryCard(
  String value,
  String label,
  Color color, {
  required bool isMobile,
  IconData? icon,
}) {
  return Container(
    padding: EdgeInsets.all(isMobile ? 4 : 6),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color, color.withOpacity(0.75)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: isMobile ? 4 : 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Stack(
      children: [
        // Watermark ikon - arka planda dusuk opaklikli
        if (icon != null)
          Positioned(
            right: isMobile ? -6 : -8,
            bottom: isMobile ? -6 : -8,
            child: Icon(
              icon,
              size: isMobile ? 28 : 36,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
        // Icerik
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: isMobile ? 10 : 14,
                  color: Colors.white.withOpacity(0.85),
                ),
                SizedBox(height: isMobile ? 1 : 2),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 11 : 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 1 : 2),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMobile ? 7 : 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Responsive ozet grid'i - Adim 5'te kullanilir.
Widget buildResponsiveSummaryGrid(
  List<Map<String, dynamic>> summaryCards, {
  required bool isMobile,
}) {
  final crossAxisCount = isMobile ? 3 : 6;

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: isMobile ? 1.2 : 1.6,
      crossAxisSpacing: isMobile ? 4 : 6,
      mainAxisSpacing: isMobile ? 4 : 6,
    ),
    itemCount: summaryCards.length,
    itemBuilder: (context, index) {
      final card = summaryCards[index];
      return buildSummaryCard(
        card['value'] as String,
        card['label'] as String,
        card['color'] as Color,
        isMobile: isMobile,
        icon: card['icon'] as IconData?,
      );
    },
  );
}

/// Bilgi karti - Adim 5 onizlemede kullanilir.
/// [accentColor] ile sol kenar aksan rengi eklenebilir.
Widget buildInfoCard(
  String title,
  List<Widget> children, {
  required bool isMobile,
  Color? accentColor,
}) {
  return Container(
    padding: EdgeInsets.all(isMobile ? 12 : 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      border: accentColor != null
          ? Border(
              left: BorderSide(
                color: accentColor,
                width: 3,
              ),
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: isMobile ? 6 : 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (accentColor != null) ...[
              Container(
                width: 4,
                height: isMobile ? 16 : 20,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),
        ...children,
      ],
    ),
  );
}

/// Bilgi satiri - bilgi kartlari icerisinde kullanilir.
/// [valueColor] ile deger rengi, [copyable] ile kopyalama destegi.
Widget buildInfoRow(
  String label,
  String value, {
  Color? valueColor,
  bool copyable = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: copyable
              ? _CopyableValue(value: value, valueColor: valueColor)
              : Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Dahili yardimci widget'lar
// ---------------------------------------------------------------------------

/// Kopyalanabilir deger widget'i - tiklayinca panoya kopyalar.
class _CopyableValue extends StatefulWidget {
  final String value;
  final Color? valueColor;

  const _CopyableValue({required this.value, this.valueColor});

  @override
  State<_CopyableValue> createState() => _CopyableValueState();
}

class _CopyableValueState extends State<_CopyableValue> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copyToClipboard,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              widget.value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: widget.valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _copied ? Icons.check_circle_outline : Icons.copy_outlined,
              key: ValueKey(_copied),
              size: 14,
              color: _copied
                  ? AppColors.success
                  : AppColors.textMuted.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
