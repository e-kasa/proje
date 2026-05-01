import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

import '../models/integration.dart';
import '../providers/integrations_provider.dart';

/// Sprint 23 — Cihazlar & Entegrasyonlar hub ekranı.
///
/// Tüm donanım cihazları + bildirim servisleri tek listede:
/// - Master switch (her satır kendi tutarlı state'inden okur)
/// - Status badge (yeşil/turuncu/gri/kırmızı health)
/// - "Ayarla" → ilgili detay ekran (config route varsa)
class IntegrationsHubScreen extends ConsumerWidget {
  const IntegrationsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final all = ref.watch(integrationsCatalogProvider);

    // Kategorilere göre grupla
    final grouped = <IntegrationCategory, List<IntegrationDef>>{};
    for (final def in all) {
      grouped.putIfAbsent(def.category, () => []).add(def);
    }

    return BaseScaffold(
      appBar: AppAppBar.standard(
        title: t('integrations.title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: t('integrations.help'),
            onPressed: () => _showHelpSheet(context, t),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(context, ref),
          const SizedBox(height: 16),
          for (final category in IntegrationCategory.values)
            if (grouped.containsKey(category))
              _buildCategorySection(
                context,
                ref,
                category,
                grouped[category]!,
              ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final all = ref.watch(integrationsCatalogProvider);
    int active = 0;
    int warning = 0;
    int total = all.length;
    for (final def in all) {
      final status = ref.watch(integrationStatusProvider(def.id));
      if (status.health == IntegrationHealth.healthy) active++;
      if (status.health == IntegrationHealth.warning) warning++;
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_customize,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('integrations.overall_status'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _statPill(
                      t('integrations.active_count').replaceAll('{0}', '$active'),
                      AppColors.success,
                    ),
                    if (warning > 0) ...[
                      const SizedBox(width: 6),
                      _statPill(
                        t('integrations.warning_count').replaceAll('{0}', '$warning'),
                        AppColors.warning,
                      ),
                    ],
                    const SizedBox(width: 6),
                    _statPill(
                      t('integrations.disabled_count')
                          .replaceAll('{0}', '${total - active - warning}'),
                      AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    WidgetRef ref,
    IntegrationCategory category,
    List<IntegrationDef> defs,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Row(
              children: [
                Icon(category.icon, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  category.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < defs.length; i++) ...[
                  _IntegrationTile(def: defs[i]),
                  if (i < defs.length - 1)
                    const Divider(height: 1, indent: 60),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpSheet(BuildContext context, String Function(String) t) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  t('integrations.help_title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              t('integrations.help_body'),
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('common.close')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntegrationTile extends ConsumerWidget {
  final IntegrationDef def;
  const _IntegrationTile({required this.def});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(integrationStatusProvider(def.id));
    final toggle = ref.read(integrationToggleProvider);
    final unsupportedOnWeb = def.requiresDesktop && kIsWeb;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Opacity(
        opacity: unsupportedOnWeb ? 0.55 : 1.0,
        child: Row(
          children: [
            // İkon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: def.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(def.icon, color: def.iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          def.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (unsupportedOnWeb)
                        Tooltip(
                          message:
                              'Yalnız masaüstü uygulamasında kullanılır',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.textMuted
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.desktop_windows,
                                    size: 10, color: AppColors.textMuted),
                                SizedBox(width: 4),
                                Text(
                                  'Masaüstü',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        _healthBadge(status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    def.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!unsupportedOnWeb && status.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      status.subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: _healthColor(status.health),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Master switch / chevron
            if (def.hasMasterSwitch)
              Switch(
                value: status.isEnabled,
                onChanged: unsupportedOnWeb
                    ? null
                    : (v) => toggle.toggle(def.id, v),
              )
            else
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );

    final t = i18nOf(ref);
    return InkWell(
      onTap: unsupportedOnWeb
          ? () => AppToast.info(
                context,
                t('integrations.desktop_only').replaceAll('{0}', def.name),
              )
          : (def.configRoute != null
              ? () => context.push(def.configRoute!)
              : () => AppToast.info(
                    context,
                    t('integrations.config_coming_soon'),
                  )),
      child: tile,
    );
  }

  Widget _healthBadge(IntegrationStatus status) {
    final color = _healthColor(status.health);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.statusText,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _healthColor(IntegrationHealth health) {
    switch (health) {
      case IntegrationHealth.healthy:
        return AppColors.success;
      case IntegrationHealth.warning:
        return AppColors.warning;
      case IntegrationHealth.error:
        return AppColors.danger;
      case IntegrationHealth.disabled:
        return AppColors.textMuted;
    }
  }
}
