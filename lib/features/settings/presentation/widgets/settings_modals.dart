import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/logo_helper.dart';
import '../cubits/settings_cubit.dart';

class BrandEditModal extends StatefulWidget {
  final AppSettings settings;
  const BrandEditModal({super.key, required this.settings});

  @override
  State<BrandEditModal> createState() => _BrandEditModalState();
}

class _BrandEditModalState extends State<BrandEditModal> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _logoPath; // Full path for display
  String? _logoFileName; // Filename for storage

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.settings.brandName);
    _phoneController = TextEditingController(text: widget.settings.phone);
    _addressController = TextEditingController(text: widget.settings.address);
    _logoFileName = widget.settings.logoPath;
    if (_logoFileName != null) {
      LogoHelper.getFullPath(_logoFileName!).then((path) {
        if (mounted) setState(() => _logoPath = path);
      });
    }
  }

  Future<void> _pickLogo() async {
    final String? fileName = await LogoHelper.pickAndSaveLogo();
    if (fileName != null) {
      final fullPath = await LogoHelper.getFullPath(fileName);
      setState(() {
        _logoFileName = fileName;
        _logoPath = fullPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        top: AppSpacing.xl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.brandDetails, style: AppTypography.h2),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      image: _logoPath != null && File(_logoPath!).existsSync()
                          ? DecorationImage(
                              image: FileImage(File(_logoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _logoPath == null
                        ? const Icon(
                            LucideIcons.imagePlus,
                            color: AppColors.secondary,
                            size: 32,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.pencil,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(AppSpacing.xl),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppStrings.brandName,
              prefixIcon: const Icon(LucideIcons.building2),
            ),
          ),
          const Gap(AppSpacing.lg),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: AppStrings.phoneNumber,
              prefixIcon: const Icon(LucideIcons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const Gap(AppSpacing.lg),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: AppStrings.address,
              prefixIcon: const Icon(LucideIcons.mapPin),
            ),
            maxLines: 2,
          ),
          const Gap(AppSpacing.xl),
          ElevatedButton(
            onPressed: () {
              final updated = widget.settings.copyWith(
                brandName: _nameController.text,
                phone: _phoneController.text,
                address: _addressController.text,
                logoPath: _logoFileName,
              );
              context.read<SettingsCubit>().saveSettings(updated);
              Navigator.pop(context);
            },
            child: Text(AppStrings.saveChanges),
          ),
        ],
      ),
    );
  }
}

class SimpleEditModal extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;
  final IconData icon;
  final Function(String) onSave;
  final TextInputType keyboardType;

  const SimpleEditModal({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
    required this.icon,
    required this.onSave,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<SimpleEditModal> createState() => _SimpleEditModalState();
}

class _SimpleEditModalState extends State<SimpleEditModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        top: AppSpacing.xl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: AppTypography.h2),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: Icon(widget.icon),
            ),
            keyboardType: widget.keyboardType,
            autofocus: true,
          ),
          const Gap(AppSpacing.xl),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_controller.text);
              Navigator.pop(context);
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
