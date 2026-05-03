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
import 'package:products_printer/features/invoices/presentation/cubits/invoice_state.dart';
import 'package:products_printer/features/invoices/presentation/pages/new_invoice_page.dart';
import 'package:products_printer/features/invoices/presentation/widgets/invoice_shimmer.dart';
import 'package:products_printer/features/invoices/presentation/widgets/invoice_empty_state.dart';
import 'package:products_printer/features/invoices/presentation/widgets/invoice_card.dart';
import 'package:products_printer/core/widgets/bento_app_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BentoAppBar(title: AppStrings.invoices, showShadow: false),
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(
            child: BlocBuilder<InvoiceCubit, InvoiceState>(
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
                  );
                }
                if (state is InvoiceLoaded) {
                  if (state.invoices.isEmpty) {
                    return const InvoiceEmptyState();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: state.invoices.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
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
                  );
                }
                return const InvoiceEmptyState();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewInvoicePage()),
          ).then((_) {
            if (context.mounted) {
              // Refresh invoices when coming back from creation
              context.read<InvoiceCubit>().loadInvoices(refresh: true);
            }
          });
        },
        icon: const Icon(LucideIcons.plus),
        label: Text(AppStrings.newInvoice),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        final dateFormat = DateFormat('MMM dd, yyyy');

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          color: AppColors.secondary,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppStrings.searchByClient,
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () {
                            _searchController.clear();
                            context.read<InvoiceCubit>().setSearchQuery(null);
                          },
                        )
                      : null,
                ),
                onChanged: (v) =>
                    context.read<InvoiceCubit>().setSearchQuery(v),
              ),
              const Gap(AppSpacing.md),
              InkWell(
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
                    context.read<InvoiceCubit>().setDateRange(
                      range.start,
                      range.end,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.greyLight),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 18,
                        color: AppColors.grey,
                      ),
                      const Gap(AppSpacing.sm),
                      Text(
                        '${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}',
                        style: AppTypography.bodySm,
                      ),
                      const Spacer(),
                      const Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: AppColors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
