import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../domain/entities/invoice.dart';
import '../cubits/invoice_cubit.dart';
import 'new_invoice_page.dart';
import 'invoice_details_page.dart';

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
      ),
      body: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, state) {
          if (state is InvoiceInitial) {
            context.read<InvoiceCubit>().loadInvoices();
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InvoiceError) {
            return Center(child: Text(state.message, style: const TextStyle(color: AppColors.danger)));
          }
          if (state is InvoiceLoaded) {
            if (state.invoices.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildInvoiceList(context, state.invoices);
          }
          return _buildEmptyState(context);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewInvoicePage()),
          );
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('NEW INVOICE'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileX2, size: 64, color: AppColors.grey.withValues(alpha: 0.5)),
          const Gap(AppSpacing.lg),
          Text(
            'No invoices found.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.grey),
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Tap + to create your first invoice.',
            style: AppTypography.bodySm.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList(BuildContext context, List<Invoice> invoices) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return _InvoiceCard(invoice: invoice);
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: bento.cardDecoration,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailsPage(invoice: invoice),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(LucideIcons.receipt, color: AppColors.secondary),
              ),
              const Gap(AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice #${invoice.id.toString().padLeft(4, '0')}',
                      style: AppTypography.h2.copyWith(fontSize: 16),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      dateFormat.format(invoice.createdAt),
                      style: AppTypography.bodySm.copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${invoice.total.toStringAsFixed(2)} ${invoice.currency}',
                    style: AppTypography.h2.copyWith(color: AppColors.secondary),
                  ),
                  const Gap(AppSpacing.xs),
                  Text(
                    '${invoice.items.length} items',
                    style: AppTypography.bodySm.copyWith(color: AppColors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
