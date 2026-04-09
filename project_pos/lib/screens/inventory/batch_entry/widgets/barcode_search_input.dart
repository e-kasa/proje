import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/batch_entry_provider.dart';

class BarcodeSearchInput extends ConsumerStatefulWidget {
  const BarcodeSearchInput({super.key});

  @override
  ConsumerState<BarcodeSearchInput> createState() => _BarcodeSearchInputState();
}

class _BarcodeSearchInputState extends ConsumerState<BarcodeSearchInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSubmitted(String value) async {
    if (value.trim().isEmpty) return;
    setState(() => _isSearching = true);

    final notifier = ref.read(batchEntryProvider.notifier);
    final result = await notifier.addByBarcode(value.trim());

    if (!mounted) return;
    setState(() => _isSearching = false);
    _controller.clear();
    _focusNode.requestFocus();

    if (result != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(result), duration: const Duration(seconds: 2)),
        );
    }
  }

  Future<void> _openScanner() async {
    final barcode = await context.push<String>('/scanner');
    if (barcode != null && barcode.isNotEmpty && mounted) {
      _controller.text = barcode;
      await _onSubmitted(barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final notifier = ref.read(batchEntryProvider.notifier);

    final textField = TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      decoration: InputDecoration(
        hintText: t('batch.barcode_search_hint'),
        prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                tooltip: t('batch.scan_with_camera'),
                onPressed: _openScanner,
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: t('batch.clear'),
                  onPressed: () {
                    _controller.clear();
                    _focusNode.requestFocus();
                  },
                ),
            ],
          ],
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onSubmitted: _onSubmitted,
      textInputAction: TextInputAction.search,
    );

    final manualButton = OutlinedButton.icon(
      onPressed: () => notifier.addManualRow(),
      icon: const Icon(Icons.add),
      label: Text(t('batch.add_manual')),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: textField),
          const SizedBox(width: 12),
          manualButton,
        ],
      );
    }

    return Column(
      children: [
        textField,
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: manualButton),
      ],
    );
  }
}
