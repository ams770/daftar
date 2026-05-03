import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/bento_theme_extension.dart';
import '../../../products/presentation/widgets/search_input_field.dart';
import '../cubits/money_collection_cubit.dart';
import '../../domain/entities/money_collection.dart';

import 'money_collection_details_page.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<MoneyCollectionCubit>().loadCollections();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MoneyCollectionCubit>().loadCollections();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
            title: Text(AppStrings.collections),
          ),
          SliverAppBar.medium(
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: BlocBuilder<MoneyCollectionCubit, MoneyCollectionState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        SearchInputField(
                          hintText: AppStrings.searchByClient,
                          onChanged: (v) => context
                              .read<MoneyCollectionCubit>()
                              .setSearchQuery(v),
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
          BlocBuilder<MoneyCollectionCubit, MoneyCollectionState>(
            builder: (context, state) {
              if (state is MoneyCollectionInitial ||
                  state is MoneyCollectionLoading &&
                      state.collections.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is MoneyCollectionError && state.collections.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(state.message)),
                );
              }

              if (state.collections.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No collections found')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.collections.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MoneyCollectionDetailsPage(
                                collection: state.collections[index],
                              ),
                            ),
                          );
                          if (context.mounted) {
                            context
                                .read<MoneyCollectionCubit>()
                                .loadCollections(refresh: true);
                          }
                        },
                        child: _CollectionCard(
                          collection: state.collections[index],
                        ),
                      );
                    },
                    childCount:
                        state.collections.length + (state.hasMore ? 1 : 0),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context, MoneyCollectionState state) {
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
                context.read<MoneyCollectionCubit>().setDateRange(
                  date,
                  state.endDate,
                );
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
                context.read<MoneyCollectionCubit>().setDateRange(
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

class _CollectionCard extends StatelessWidget {
  final MoneyCollection collection;

  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context) {
    final bento = Theme.of(context).extension<BentoThemeExtension>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: bento.cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.clientName ?? 'Unknown Client',
                    style: AppTypography.h3,
                  ),
                  Text(
                    'Invoice #${collection.invoiceId}',
                    style: AppTypography.bodySm.copyWith(color: AppColors.grey),
                  ),
                ],
              ),
              Text(
                '+${collection.amount.toStringAsFixed(2)}',
                style: AppTypography.h2.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          const Divider(),
          const Gap(AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                collection.formattedDate,
                style: AppTypography.label.copyWith(fontSize: 10),
              ),
              Row(
                children: [
                  _buildMiniLabel('Before', collection.remainingBefore),
                  const Gap(AppSpacing.md),
                  _buildMiniLabel(
                    'After',
                    collection.remainingAfter,
                    isBold: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniLabel(String label, double val, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTypography.label.copyWith(fontSize: 8)),
        Text(
          val.toStringAsFixed(2),
          style: AppTypography.label.copyWith(
            fontSize: 10,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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
