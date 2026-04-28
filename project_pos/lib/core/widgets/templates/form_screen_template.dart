import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../app_app_bar.dart';
import '../app_button.dart';
import '../base_scaffold.dart';

/// Sprint 15 — Form ekranlarının ortak iskelet template'i.
///
/// Add/edit form'larını (add_customer, add_supplier, add_store, add_employee,
/// add_income, add_expense, ...) tutarlı bir yapıya getirir.
///
/// Kullanım:
/// ```dart
/// FormScreenTemplate(
///   title: 'Yeni Müşteri',
///   formKey: _formKey,
///   isSaving: _isSaving,
///   onSave: _handleSave,
///   sections: [
///     FormSection(
///       title: 'Temel Bilgiler',
///       icon: Icons.person_outline,
///       fields: [AppInput(...), AppInput(...)],
///     ),
///     FormSection(
///       title: 'İletişim',
///       icon: Icons.phone_outlined,
///       fields: [AppInput(...)],
///     ),
///   ],
/// )
/// ```
class FormScreenTemplate extends ConsumerWidget {
  final String title;
  final List<Widget>? appBarActions;

  /// Form bölümleri — header + alanlar.
  final List<FormSection> sections;

  /// Form key — null ise wrap etmez.
  final GlobalKey<FormState>? formKey;

  /// Save action.
  final Future<void> Function() onSave;

  /// "Kaydet" buton metni override.
  final String? saveLabel;

  /// Save sırasında loading.
  final bool isSaving;

  /// Save butonu disable edilebilir (validation kontrolü için).
  final bool canSubmit;

  /// "Kaydet" yerine kullanılacak custom alt buton — null ise default save.
  final Widget? customBottomBar;

  /// Üst banner (uyarı / bilgi).
  final Widget? topBanner;

  /// Alt iptal/silme aksiyonları için ek butonlar (save'in üstünde row).
  final List<Widget>? secondaryActions;

  /// Body padding override.
  final EdgeInsets? padding;

  const FormScreenTemplate({
    super.key,
    required this.title,
    required this.sections,
    required this.onSave,
    this.formKey,
    this.appBarActions,
    this.saveLabel,
    this.isSaving = false,
    this.canSubmit = true,
    this.customBottomBar,
    this.topBanner,
    this.secondaryActions,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = Column(
      children: [
        ?topBanner,
        Expanded(
          child: ListView(
            padding: padding ?? const EdgeInsets.all(16),
            children: [
              for (int i = 0; i < sections.length; i++) ...[
                _buildSection(sections[i]),
                if (i < sections.length - 1) const SizedBox(height: 20),
              ],
              const SizedBox(height: 80), // bottom bar için boşluk
            ],
          ),
        ),
      ],
    );

    return BaseScaffold(
      appBar: AppAppBar.standard(title: title, actions: appBarActions),
      body: formKey != null ? Form(key: formKey, child: body) : body,
      bottomNavigationBar: customBottomBar ?? _buildBottomBar(context),
    );
  }

  Widget _buildSection(FormSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) ...[
          Row(
            children: [
              if (section.icon != null) ...[
                Icon(section.icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
              ],
              Text(
                section.title!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 12),
        ],
        ...section.fields,
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (secondaryActions != null) ...secondaryActions!,
          if (secondaryActions != null) const SizedBox(width: 8),
          Expanded(
            child: AppButton.primary(
              text: saveLabel ?? 'Kaydet',
              isLoading: isSaving,
              onPressed: (canSubmit && !isSaving) ? onSave : null,
              icon: Icons.check_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bir form bölümü — header + alanlar.
class FormSection {
  final String? title;
  final IconData? icon;
  final List<Widget> fields;

  const FormSection({
    this.title,
    this.icon,
    required this.fields,
  });
}
