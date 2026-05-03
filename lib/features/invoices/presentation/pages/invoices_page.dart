import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:products_printer/core/constants/app_strings.dart';
import 'package:products_printer/core/theme/app_colors.dart';
import 'package:products_printer/core/theme/app_spacing.dart';
import 'package:products_printer/core/theme/app_typography.dart';
import 'package:products_printer/features/invoices/presentation/cubits/invoice_cubit.dart';
import 'package:products_printer/features/invoices/presentation/pages/new_invoice_page.dart';
import 'package:products_printer/features/invoices/presentation/widgets/invoice_shimmer.dart';
import 'package:products_printer/features/invoices/presentation/widgets/invoice_empty_state.dart';
import 'package:products_printer/features/invoices/presentation/widgets/invoice_card.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InvoiceCubit>().loadMoreInvoices();
    }
  }

  void _navigateToNewInvoice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewInvoicePage()),
    ).then((_) {
      if (context.mounted) {
        context.read<InvoiceCubit>().loadInvoices(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          BlocBuilder<InvoiceCubit, InvoiceState>(
            builder: (context, state) {
              return SliverAppBar(
                pinned: true,
                expandedHeight: 180,
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

                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: AppStrings.searchByClient,
                            fillColor: AppColors.white,
                            filled: true,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 8,
                            ),
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(LucideIcons.x, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      context
                                          .read<InvoiceCubit>()
                                          .setSearchQuery(null);
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (v) =>
                              context.read<InvoiceCubit>().setSearchQuery(v),
                        ),
                        const Gap(AppSpacing.sm),
                        _buildDateFilter(context, state),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          BlocBuilder<InvoiceCubit, InvoiceState>(
            builder: (context, state) {
              if (state is InvoiceInitial) {
                context.read<InvoiceCubit>().loadInvoices();
                return const SliverToBoxAdapter(child: InvoiceListShimmer());
              }
              if (state is InvoiceLoading) {
                return const SliverToBoxAdapter(child: InvoiceListShimmer());
              }
              if (state is InvoiceError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          style: const TextStyle(color: AppColors.danger),
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
                  return const SliverToBoxAdapter(child: InvoiceEmptyState());
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == state.invoices.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: CircularProgressIndicator(),
                            ),
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
              return const SliverToBoxAdapter(child: InvoiceEmptyState());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context, InvoiceState state) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return InkWell(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          initialDateRange: DateTimeRange(
            start: state.startDate,
            end: state.endDate,
          ),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (range != null && context.mounted) {
          context.read<InvoiceCubit>().setDateRange(range.start, range.end);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.calendar, size: 14, color: AppColors.white),
            const Gap(AppSpacing.sm),
            Text(
              '${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.white,
                fontSize: 12,
              ),
            ),
            Spacer(),
            const Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
