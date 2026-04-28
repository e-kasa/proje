import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/templates/list_screen_template.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

const String _kTypeCountable = 'Sayılabilir';
const String _kTypeWeighable = 'Tartılabilir';
const String _kTypeMeasurable = 'Ölçülebilir';

class UnitsScreen extends ConsumerStatefulWidget {
  const UnitsScreen({super.key});

  @override
  ConsumerState<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends ConsumerState<UnitsScreen> {
  String Function(String) get t => i18nOf(ref);
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _filteredUnits = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(unitServiceProvider);
      final units = await service.getAllUnits();
      setState(() {
        _units = units.map<Map<String, dynamic>>((u) => {
              'id': u['id'],
              'name': u['name'] ?? '',
              'code': u['code'] ?? '',
              'symbol': u['symbol'] ?? '',
              'type': (u['type'] ?? _kTypeCountable) as String,
              'active': u['isActive'] == true,
            }).toList();
        _filteredUnits = List.from(_units);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _units = [];
        _filteredUnits = [];
        _isLoading = false;
      });
      if (mounted) {
        AppToast.error(context, '${t('inventory.unit_load_error')}: $e');
      }
    }
  }

  void _filterUnits(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUnits = List.from(_units);
      } else {
        final searchLower = query.toLowerCase();
        _filteredUnits = _units.where((unit) {
          final name = unit['name'].toString().toLowerCase();
          final code = unit['code'].toString().toLowerCase();
          final symbol = unit['symbol'].toString().toLowerCase();
          return name.contains(searchLower) ||
              code.contains(searchLower) ||
              symbol.contains(searchLower);
        }).toList();
      }
    });
  }

  String _typeLabel(String type) {
    switch (type) {
      case _kTypeCountable:
        return t('inventory.unit_type_countable');
      case _kTypeWeighable:
        return t('inventory.unit_type_weighable');
      case _kTypeMeasurable:
        return t('inventory.unit_type_measurable');
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case _kTypeCountable:
        return AppColors.primary;
      case _kTypeWeighable:
        return AppColors.success;
      case _kTypeMeasurable:
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case _kTypeCountable:
        return Icons.numbers;
      case _kTypeWeighable:
        return Icons.balance;
      case _kTypeMeasurable:
        return Icons.square_foot;
      default:
        return Icons.category;
    }
  }

  void _showAddUnitDialog() => _showUnitDialog(null);

  void _showEditUnitDialog(Map<String, dynamic> unit) => _showUnitDialog(unit);

  void _showUnitDialog(Map<String, dynamic>? unit) {
    final isEdit = unit != null;
    final nameController = TextEditingController(text: unit?['name'] ?? '');
    final codeController = TextEditingController(text: unit?['code'] ?? '');
    final symbolController = TextEditingController(text: unit?['symbol'] ?? '');
    String selectedType = (unit?['type'] as String?) ?? _kTypeCountable;
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMedium,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isEdit ? AppColors.info : AppColors.primary)
                                .withValues(alpha: 0.12),
                            borderRadius: AppConstants.borderRadiusSmall,
                          ),
                          child: Icon(
                            isEdit ? Icons.edit : Icons.straighten,
                            color: isEdit ? AppColors.info : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEdit
                                ? t('inventory.edit_unit')
                                : t('inventory.new_unit'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    AppInput(
                      controller: nameController,
                      label: '${t('inventory.unit_name')} *',
                      hint: t('inventory.unit_name_hint'),
                      prefixIcon: Icons.label,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? t('inventory.unit_name')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      controller: codeController,
                      label: '${t('inventory.unit_code')} *',
                      hint: t('inventory.unit_code_hint'),
                      prefixIcon: Icons.code,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? t('inventory.unit_code')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      controller: symbolController,
                      label: t('inventory.unit_symbol'),
                      hint: t('inventory.unit_symbol_hint'),
                      prefixIcon: Icons.shortcut,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: t('inventory.unit_type'),
                        prefixIcon: const Icon(Icons.category, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: AppConstants.borderRadiusMedium,
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppConstants.borderRadiusMedium,
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppConstants.borderRadiusMedium,
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      items: const [
                        _kTypeCountable,
                        _kTypeWeighable,
                        _kTypeMeasurable,
                      ].map<DropdownMenuItem<String>>((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                _getTypeIcon(type),
                                size: 16,
                                color: _getTypeColor(type),
                              ),
                              const SizedBox(width: 8),
                              Text(_typeLabel(type)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton.outline(
                          text: t('common.cancel'),
                          onPressed: submitting ? null : () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        AppButton.primary(
                          text: isEdit ? t('common.update') : t('common.save'),
                          isLoading: submitting,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => submitting = true);
                            final name = nameController.text.trim();
                            final code = codeController.text.trim();
                            final symbol = symbolController.text.trim();
                            final payload = {
                              'name': name,
                              'code': code,
                              'symbol': symbol,
                              'type': selectedType,
                              'isActive': isEdit ? unit['active'] : true,
                            };
                            final navigator = Navigator.of(context);
                            try {
                              final service = ref.read(unitServiceProvider);
                              if (isEdit) {
                                await service.updateUnit(unit['id'], payload);
                              } else {
                                await service.createUnit(payload);
                              }
                              navigator.pop();
                              if (!mounted) return;
                              AppToast.success(
                                this.context,
                                isEdit
                                    ? t('inventory.unit_updated')
                                    : '$name ${t('inventory.unit_added')}',
                              );
                              _loadUnits();
                            } catch (e) {
                              if (!mounted) return;
                              AppToast.error(
                                this.context,
                                '${t('inventory.unit_save_error')}: $e',
                              );
                              setDialogState(() => submitting = false);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(Map<String, dynamic> unit) async {
    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: t('inventory.delete_unit'),
      message: '${unit['name']} (${unit['code']}) ${t('inventory.unit_delete_confirm')}',
      itemName: unit['name'] ?? '',
    );

    if (!confirmed) return;

    try {
      await ref.read(unitServiceProvider).deleteUnit(unit['id']);
      if (mounted) {
        AppToast.success(
          context,
          '${unit['name']} ${t('inventory.unit_deleted')}',
        );
      }
      _loadUnits();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> unit) async {
    try {
      await ref.read(unitServiceProvider).toggleStatus(unit['id']);
      if (mounted) {
        AppToast.success(
          context,
          unit['active']
              ? '${unit['name']} ${t('inventory.unit_deactivated_msg')}'
              : '${unit['name']} ${t('inventory.unit_activated_msg')}',
        );
      }
      _loadUnits();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sprint 16-B: ListScreenTemplate migration (brands_screen ile aynı pattern).
    return ListScreenTemplate<Map<String, dynamic>>(
      title: t('menu.units'),
      items: _filteredUnits,
      isLoading: _isLoading,
      onRefresh: _loadUnits,
      emptyState: _buildEmptyState(),
      searchSlot: Container(
        color: Colors.white,
        padding: AppConstants.pagePadding,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppSearchInput(
                    controller: _searchController,
                    hint: '${t('common.search')}...',
                    onChanged: _filterUnits,
                    onClear: () {
                      _searchController.clear();
                      _filterUnits('');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                AppButton.primary(
                  text: t('inventory.new_unit'),
                  icon: Icons.add,
                  onPressed: _showAddUnitDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppConstants.borderRadiusSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    t('common.total'),
                    '${_units.length}',
                    Icons.straighten,
                  ),
                  Container(width: 1, height: 30, color: AppColors.border),
                  _buildStatItem(
                    t('inventory.unit_type_countable'),
                    '${_units.where((u) => u['type'] == _kTypeCountable).length}',
                    Icons.numbers,
                  ),
                  Container(width: 1, height: 30, color: AppColors.border),
                  _buildStatItem(
                    t('inventory.unit_type_weighable'),
                    '${_units.where((u) => u['type'] == _kTypeWeighable).length}',
                    Icons.balance,
                  ),
                  Container(width: 1, height: 30, color: AppColors.border),
                  _buildStatItem(
                    t('inventory.unit_type_measurable'),
                    '${_units.where((u) => u['type'] == _kTypeMeasurable).length}',
                    Icons.square_foot,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context, unit, index) => _buildUnitCard(unit),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.straighten_outlined,
      title: t('inventory.no_units'),
      description: t('inventory.add_unit_hint'),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final type = (unit['type'] as String?) ?? _kTypeCountable;
    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);
    final isActive = unit['active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppConstants.borderRadiusMedium,
          onTap: () => _showEditUnitDialog(unit),
          child: Padding(
            padding: AppConstants.pagePadding,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: AppConstants.borderRadiusMedium,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 28),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              unit['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.bgLight,
                              borderRadius: AppConstants.borderRadiusSmall,
                            ),
                            child: Text(
                              unit['code'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.textMuted.withValues(alpha: 0.1),
                              borderRadius: AppConstants.borderRadiusSmall,
                            ),
                            child: Text(
                              isActive
                                  ? t('common.active')
                                  : t('common.passive'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: AppConstants.borderRadiusSmall,
                            ),
                            child: Text(
                              _typeLabel(type),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ),
                          if ((unit['symbol'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.shortcut,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              unit['symbol'].toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppConstants.borderRadiusSmall),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditUnitDialog(unit);
                    } else if (value == 'toggle') {
                      _toggleStatus(unit);
                    } else if (value == 'delete') {
                      _showDeleteDialog(unit);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18, color: AppColors.info),
                          const SizedBox(width: 12),
                          Text(t('common.edit')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.toggle_off : Icons.toggle_on,
                            size: 18,
                            color: isActive
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          Text(isActive
                              ? t('inventory.deactivate')
                              : t('inventory.activate')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete,
                              size: 18, color: AppColors.danger),
                          const SizedBox(width: 12),
                          Text(t('common.delete')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
