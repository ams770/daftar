import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../../core/models/app_settings.dart';
import '../cubits/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsInitial) {
            context.read<SettingsCubit>().loadSettings();
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SettingsLoaded) {
            final settings = state.settings;
            return _buildContent(context, settings);
          }
          if (state is SettingsError) {
            return Center(child: Text(state.message, style: const TextStyle(color: AppColors.danger)));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppSettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsSection(
            title: 'Brand Details',
            onTap: () => _showBrandEditModal(context, settings),
            child: Row(
              children: [
                _buildLogoPreview(settings.logoPath),
                const Gap(AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(settings.brandName, style: AppTypography.h2),
                      if (settings.phone.isNotEmpty) ...[
                        const Gap(AppSpacing.xs),
                        Text(settings.phone, style: AppTypography.bodySm.copyWith(color: AppColors.grey)),
                      ],
                      if (settings.address.isNotEmpty) ...[
                        const Gap(AppSpacing.xs),
                        Text(settings.address, style: AppTypography.bodySm.copyWith(color: AppColors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppColors.grey, size: 20),
              ],
            ),
          ),
          const Gap(AppSpacing.xl),
          _SettingsSection(
            title: 'Taxation',
            onTap: () => _showValueEditModal(
              context,
              title: 'Edit VAT',
              label: 'VAT Percentage (%)',
              initialValue: settings.vatPercent.toString(),
              icon: LucideIcons.percent,
              keyboardType: TextInputType.number,
              onSave: (val) {
                final newSettings = settings.copyWith(vatPercent: int.tryParse(val) ?? 15);
                context.read<SettingsCubit>().saveSettings(newSettings);
              },
            ),
            child: _buildSimpleRow(LucideIcons.percent, 'VAT Rate', '${settings.vatPercent}%'),
          ),
          const Gap(AppSpacing.xl),
          _SettingsSection(
            title: 'Currency',
            onTap: () => _showValueEditModal(
              context,
              title: 'Edit Currency',
              label: 'Currency Code',
              initialValue: settings.currency,
              icon: LucideIcons.banknote,
              onSave: (val) {
                final newSettings = settings.copyWith(currency: val);
                context.read<SettingsCubit>().saveSettings(newSettings);
              },
            ),
            child: _buildSimpleRow(LucideIcons.banknote, 'Default Currency', settings.currency),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPreview(String? path) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        image: path != null ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover) : null,
      ),
      child: path == null ? const Icon(LucideIcons.image, color: AppColors.secondary, size: 24) : null,
    );
  }

  Widget _buildSimpleRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 18),
        ),
        const Gap(AppSpacing.md),
        Expanded(child: Text(label, style: AppTypography.bodyMd)),
        Text(value, style: AppTypography.h2.copyWith(fontSize: 16, color: AppColors.secondary)),
        const Gap(AppSpacing.md),
        const Icon(LucideIcons.chevronRight, color: AppColors.grey, size: 18),
      ],
    );
  }

  void _showBrandEditModal(BuildContext context, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsCubit>(),
        child: _BrandEditModal(settings: settings),
      ),
    );
  }

  void _showValueEditModal(
    BuildContext context, {
    required String title,
    required String label,
    required String initialValue,
    required IconData icon,
    required Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SimpleEditModal(
        title: title,
        label: label,
        initialValue: initialValue,
        icon: icon,
        onSave: onSave,
        keyboardType: keyboardType,
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onTap;

  const _SettingsSection({
    required this.title,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.label.copyWith(color: AppColors.grey, letterSpacing: 1.2),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: bento.cardDecoration,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _BrandEditModal extends StatefulWidget {
  final AppSettings settings;
  const _BrandEditModal({required this.settings});

  @override
  State<_BrandEditModal> createState() => _BrandEditModalState();
}

class _BrandEditModalState extends State<_BrandEditModal> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.settings.brandName);
    _phoneController = TextEditingController(text: widget.settings.phone);
    _addressController = TextEditingController(text: widget.settings.address);
    _logoPath = widget.settings.logoPath;
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _logoPath = image.path);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Brand Details', style: AppTypography.h2),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
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
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      image: _logoPath != null ? DecorationImage(image: FileImage(File(_logoPath!)), fit: BoxFit.cover) : null,
                    ),
                    child: _logoPath == null ? const Icon(LucideIcons.imagePlus, color: AppColors.secondary, size: 32) : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.pencil, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(AppSpacing.xl),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Brand Name', prefixIcon: Icon(LucideIcons.building2)),
          ),
          const Gap(AppSpacing.lg),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(LucideIcons.phone)),
            keyboardType: TextInputType.phone,
          ),
          const Gap(AppSpacing.lg),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(LucideIcons.mapPin)),
            maxLines: 2,
          ),
          const Gap(AppSpacing.xl),
          ElevatedButton(
            onPressed: () {
              final updated = widget.settings.copyWith(
                brandName: _nameController.text,
                phone: _phoneController.text,
                address: _addressController.text,
                logoPath: _logoPath,
              );
              context.read<SettingsCubit>().saveSettings(updated);
              Navigator.pop(context);
            },
            child: const Text('SAVE CHANGES'),
          ),
        ],
      ),
    );
  }
}

class _SimpleEditModal extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;
  final IconData icon;
  final Function(String) onSave;
  final TextInputType keyboardType;

  const _SimpleEditModal({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.icon,
    required this.onSave,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_SimpleEditModal> createState() => _SimpleEditModalState();
}

class _SimpleEditModalState extends State<_SimpleEditModal> {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: AppTypography.h2),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
            ],
          ),
          const Gap(AppSpacing.lg),
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(labelText: widget.label, prefixIcon: Icon(widget.icon)),
            keyboardType: widget.keyboardType,
            autofocus: true,
          ),
          const Gap(AppSpacing.xl),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_controller.text);
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
