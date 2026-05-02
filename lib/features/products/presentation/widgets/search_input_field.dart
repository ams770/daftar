import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class SearchInputField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onScannerTap;
  final String hintText;

  const SearchInputField({
    super.key,
    required this.onChanged,
    required this.onScannerTap,
    this.hintText = 'Search by name or code...',
  });

  @override
  State<SearchInputField> createState() => _SearchInputFieldState();
}

class _SearchInputFieldState extends State<SearchInputField> {
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.grey),
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.grey, size: 20),
                filled: true,
                fillColor: AppColors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.greyLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
          const Gap(AppSpacing.md),
          Material(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: InkWell(
              onTap: widget.onScannerTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Icon(LucideIcons.scanBarcode, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
