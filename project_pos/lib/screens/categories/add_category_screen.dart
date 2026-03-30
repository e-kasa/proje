import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_locator.dart';

/// Yeni kategori ekleme / mevcut kategori düzenleme ekranı.
/// Backend API ile çalışır (SQLite yok).
/// 3 seviyeli hiyerarşi: level 0 (kök) → level 1 (alt) → level 2 (torun)
class AddCategoryScreen extends ConsumerStatefulWidget {
  /// Düzenleme modunda mevcut kategori verisi (Map from API).
  /// null ise oluşturma modu.
  final Map<String, dynamic>? category;

  const AddCategoryScreen({super.key, this.category});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _sortOrderController;

  String _selectedIcon = 'category';
  bool _isActive = true;
  String? _parentId; // UUID String veya null
  bool _isLoading = false;
  bool _loadingParents = true;

  List<Map<String, dynamic>> _parentCandidates = [];

  // Sabit ikon listesi
  final List<_CategoryIcon> _availableIcons = [
    _CategoryIcon('category', Icons.category, 'Genel'),
    _CategoryIcon('devices', Icons.devices, 'Elektronik'),
    _CategoryIcon('checkroom', Icons.checkroom, 'Giyim'),
    _CategoryIcon('sports_tennis', Icons.sports_tennis, 'Ayakkabı'),
    _CategoryIcon('shopping_bag', Icons.shopping_bag, 'Aksesuar'),
    _CategoryIcon('home', Icons.home, 'Ev & Yaşam'),
    _CategoryIcon('fitness_center', Icons.fitness_center, 'Spor'),
    _CategoryIcon('restaurant', Icons.restaurant, 'Gıda'),
    _CategoryIcon('toys', Icons.toys, 'Oyuncak'),
    _CategoryIcon('local_florist', Icons.local_florist, 'Kozmetik'),
    _CategoryIcon('inventory_2', Icons.inventory_2, 'Depo'),
    _CategoryIcon('storefront', Icons.storefront, 'Mağaza'),
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?['name'] ?? '');
    _descriptionController =
        TextEditingController(text: cat?['description'] ?? '');
    _sortOrderController =
        TextEditingController(text: (cat?['sortOrder'] ?? 0).toString());

    if (cat != null) {
      _selectedIcon = cat['icon'] ?? 'category';
      _isActive = (cat['status'] == 'ACTIVE');
      _parentId = cat['parentId']?.toString();
    }

    _loadParentCandidates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  /// Üst kategori olabilecek kategorileri yükle.
  /// Kural: sadece level 0 ve level 1 kategoriler üst olabilir
  /// (level 2 zaten 3. seviye = maksimum derinlik).
  Future<void> _loadParentCandidates() async {
    setState(() => _loadingParents = true);
    try {
      final cats =
          await ref.read(categoryServiceProvider).getCategories();

      final editId = widget.category?['id']?.toString();

      setState(() {
        _parentCandidates = cats.where((c) {
          final level = (c['level'] as int?) ?? 0;
          final id = c['id']?.toString() ?? '';
          // Sadece level 0 ve 1 ebeveyn olabilir; kendini hariç tut
          return level < 2 && id != editId;
        }).toList();
        _loadingParents = false;
      });
    } catch (e) {
      setState(() => _loadingParents = false);
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'parentId': (_parentId?.isNotEmpty == true) ? _parentId : null,
      'status': _isActive ? 'ACTIVE' : 'INACTIVE',
      'sortOrder': int.tryParse(_sortOrderController.text) ?? 0,
      'icon': _selectedIcon,
    };

    try {
      final service = ref.read(categoryServiceProvider);
      final editId = widget.category?['id']?.toString();

      if (editId != null && editId.isNotEmpty) {
        await service.updateCategory(editId, payload);
      } else {
        await service.createCategory(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(editId != null
                ? '✅ Kategori güncellendi'
                : '✅ Kategori oluşturuldu'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Üst kategori dropdown için görüntü metni (girinti ile hiyerarşi)
  String _parentLabel(Map<String, dynamic> cat) {
    final level = (cat['level'] as int?) ?? 0;
    final prefix = level == 0 ? '📁' : '   └─';
    return '$prefix ${cat['name']}';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(isEdit ? 'Kategori Düzenle' : 'Yeni Kategori'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Temel Bilgiler ──────────────────────────────────────
            _buildCard(
              title: 'Temel Bilgiler',
              icon: Icons.info_outline,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Adı *',
                    hintText: 'Örn: Elektronik, Giyim',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Kategori adı zorunludur' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (Opsiyonel)',
                    hintText: 'Kategori açıklaması',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── İkon Seçimi ──────────────────────────────────────────
            _buildCard(
              title: 'İkon Seçimi',
              icon: Icons.widgets_outlined,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableIcons.map((iconData) {
                    final sel = _selectedIcon == iconData.name;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = iconData.name),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? AppColors.primary : Colors.grey.shade300,
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              iconData.icon,
                              color: sel ? AppColors.primary : Colors.grey.shade600,
                              size: 26,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              iconData.label,
                              style: TextStyle(
                                fontSize: 9,
                                color: sel ? AppColors.primary : Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Gelişmiş Ayarlar ─────────────────────────────────────
            _buildCard(
              title: 'Gelişmiş Ayarlar',
              icon: Icons.settings_outlined,
              children: [
                // Üst Kategori seçimi
                _loadingParents
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : DropdownButtonFormField<String?>(
                        value: _parentId,
                        decoration: const InputDecoration(
                          labelText: 'Üst Kategori (Opsiyonel)',
                          hintText: 'Seçin — boş bırakırsanız kök kategori olur',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('─ Ana Kategori (Kök)'),
                          ),
                          ..._parentCandidates.map((cat) {
                            return DropdownMenuItem<String?>(
                              value: cat['id']?.toString(),
                              child: Text(
                                _parentLabel(cat),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _parentId = v),
                      ),

                const SizedBox(height: 16),

                // Sıra numarası
                TextFormField(
                  controller: _sortOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Sıra Numarası',
                    hintText: '0',
                    border: OutlineInputBorder(),
                    helperText: 'Düşük numara önce gösterilir',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Durum toggle
                SwitchListTile(
                  title: const Text('Kategori Durumu'),
                  subtitle: Text(
                    _isActive ? 'Aktif — Ürün aramalarında görünür' : 'Pasif — Gizli',
                    style: TextStyle(
                      color: _isActive ? AppColors.success : AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: AppColors.success,
                ),
              ],
            ),

            // Seviye bilgisi (edit modunda)
            if (isEdit) ...[
              const SizedBox(height: 12),
              _buildLevelBadge(widget.category!),
            ],

            const SizedBox(height: 24),

            // Kaydet butonu
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEdit ? 'Güncelle' : 'Oluştur',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Edit modunda mevcut seviyeyi gösteren bilgi etiketi
  Widget _buildLevelBadge(Map<String, dynamic> cat) {
    final level = (cat['level'] as int?) ?? 0;
    const labels = ['Kök Kategori (Seviye 0)', 'Alt Kategori (Seviye 1)', 'İkinci Alt Kategori (Seviye 2)'];
    const colors = [Colors.blue, Colors.orange, Colors.purple];
    final label = level < labels.length ? labels[level] : 'Seviye $level';
    final color = level < colors.length ? colors[level] : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          if (level >= 2)
            Text(
              '(Maksimum derinlik — alt kategori eklenemez)',
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon {
  final String name;
  final IconData icon;
  final String label;
  const _CategoryIcon(this.name, this.icon, this.label);
}
