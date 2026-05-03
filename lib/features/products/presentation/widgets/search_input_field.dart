import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class SearchInputField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onScannerTap;
  final String hintText;

  const SearchInputField({
    super.key,
    required this.onChanged,
    this.onScannerTap,
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
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.grey),
        prefixIcon: const Icon(
          LucideIcons.search,
          color: AppColors.grey,
          size: 18,
        ),
        suffixIcon: widget.onScannerTap == null
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.scanLine, size: 18),
                onPressed: widget.onScannerTap,
                color: AppColors.secondary,
              ),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: AppSpacing.md,
        ),
      ),
    );
  }
}
