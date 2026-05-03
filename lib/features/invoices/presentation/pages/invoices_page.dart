import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:products_printer/core/constants/app_strings.dart';
import 'package:products_printer/core/theme/app_colors.dart';
import 'package:products_printer/core/theme/app_spacing.dart';
import 'package:products_printer/core/theme/app_typography.dart';
import 'package:products_printer/features/invoices/presentation/cubits/invoice_cubit.dart';
import 'package:products_printer/features/invoices/presentation/pages/new_invoice_page.dart';
import 'package:products_printer/features/invoices/presentation/widgets/invoice_shimmer.dart';
import 'package:products_printer/features/invoices/presentation/widgets/invoice_empty_state.dart';
import 'package:products_printer/features/invoices/presentation/widgets/invoice_card.dart';

import '../../../products/presentation/widgets/search_input_field.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InvoiceCubit>().loadMoreInvoices();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToNewInvoice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewInvoicePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.secondary,
            title: Text(AppStrings.invoices),
            actions: [
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.secondary,
                ),
                icon: const Icon(LucideIcons.plus),
                onPressed: () => _navigateToNewInvoice(context),
                tooltip: AppStrings.newInvoice,
              ),
              const Gap(AppSpacing.md),
            ],
          ),
          SliverAppBar.medium(
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: BlocBuilder<InvoiceCubit, InvoiceState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        SearchInputField(
                          hintText: AppStrings.searchByClient,
                          onChanged: (v) =>
                              context.read<InvoiceCubit>().setSearchQuery(v),
                        ),
                        const Gap(AppSpacing.md),
                        _buildDateFilter(context, state),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          BlocBuilder<InvoiceCubit, InvoiceState>(
            builder: (context, state) {
              if (state is InvoiceInitial || state is InvoiceLoading) {
                // If it's the initial state, ensure we've triggered the load
                if (state is InvoiceInitial) {
                  context.read<InvoiceCubit>().loadInvoices();
                }
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: InvoiceListShimmer(),
                  ),
                );
              }

              if (state is InvoiceError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.circleAlert,
                          color: AppColors.danger,
                          size: 48,
                        ),
                        const Gap(AppSpacing.md),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd,
                        ),
                        const Gap(AppSpacing.md),
                        ElevatedButton(
                          onPressed: () => context
                              .read<InvoiceCubit>()
                              .loadInvoices(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is InvoiceLoaded) {
                if (state.invoices.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: InvoiceEmptyState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= state.invoices.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return InvoiceCard(invoice: state.invoices[index]);
                      },
                      childCount:
                          state.invoices.length + (state.hasMore ? 1 : 0),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context, InvoiceState state) {
    return Row(
      children: [
        Expanded(
          child: _DateSelector(
            label: 'From',
            date: state.startDate,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: state.startDate,
                firstDate: DateTime(2020),
                lastDate: state.endDate,
              );
              if (date != null && context.mounted) {
                context.read<InvoiceCubit>().setDateRange(date, state.endDate);
              }
            },
          ),
        ),
        const Gap(AppSpacing.md),
        Expanded(
          child: _DateSelector(
            label: 'To',
            date: state.endDate,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: state.endDate,
                firstDate: state.startDate,
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && context.mounted) {
                context.read<InvoiceCubit>().setDateRange(
                  state.startDate,
                  date,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  dateFormat.format(date),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(LucideIcons.calendar, size: 14, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
