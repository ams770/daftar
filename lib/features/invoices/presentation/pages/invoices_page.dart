import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../domain/entities/invoice.dart';
import '../cubits/invoice_cubit.dart';
import 'new_invoice_page.dart';
import 'invoice_details_page.dart';
import '../widgets/invoice_shimmer.dart';
import '../widgets/invoice_empty_state.dart';
import '../widgets/invoice_card.dart';

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: BlocBuilder<InvoiceCubit, InvoiceState>(
        buildWhen: (previous, current) =>
            current is InvoiceInitial ||
            current is InvoiceLoading ||
            current is InvoiceLoaded ||
            current is InvoiceError,
        builder: (context, state) {
          if (state is InvoiceInitial) {
            context.read<InvoiceCubit>().loadInvoices();
            return const InvoiceListShimmer();
          }
          if (state is InvoiceLoading) {
            return const InvoiceListShimmer();
          }
          if (state is InvoiceError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.danger),
              ),
            );
          }
          if (state is InvoiceLoaded) {
            if (state.invoices.isEmpty) {
              return const InvoiceEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.invoices.length,
              itemBuilder: (context, index) {
                return InvoiceCard(invoice: state.invoices[index]);
              },
            );
          }
          return const InvoiceEmptyState();
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
        label: Text(AppStrings.newInvoice),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
    );
  }

}