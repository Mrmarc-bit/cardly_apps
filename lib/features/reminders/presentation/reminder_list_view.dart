import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cardly_bottom_sheet.dart';
import '../../../core/widgets/cardly_empty_state.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../domain/reminder_model.dart';

class ReminderListView extends ConsumerStatefulWidget {
  const ReminderListView({super.key});

  @override
  ConsumerState<ReminderListView> createState() => _ReminderListViewState();
}

class _ReminderListViewState extends ConsumerState<ReminderListView> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Aktif, 2: Selesai

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(reminderListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredReminders = reminders.where((r) {
      if (_selectedFilterIndex == 1) return !r.isCompleted;
      if (_selectedFilterIndex == 2) return r.isCompleted;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengingat Masa Berlaku')),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenInset,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _buildFilterTab(0, 'Semua (${reminders.length})'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterTab(
                  1,
                  'Aktif (${reminders.where((r) => !r.isCompleted).length})',
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterTab(
                  2,
                  'Selesai (${reminders.where((r) => r.isCompleted).length})',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Reminder List or Empty State
          Expanded(
            child: filteredReminders.isEmpty
                ? CardlyEmptyState(
                    title: 'Tidak ada pengingat',
                    description: 'Atur pengingat sebelum SIM, KTP, atau kartu pembayaran Anda habis masa berlakunya.',
                    icon: Icons.notifications_none_outlined,
                    buttonText: 'Buat Pengingat Baru',
                    onButtonPressed: () => context.push('/reminders/create'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenInset),
                    itemCount: filteredReminders.length,
                    separatorBuilder: (_, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = filteredReminders[index];
                      final isOverdue =
                          !item.isCompleted &&
                          item.dueDate.isBefore(DateTime.now());

                      return InkWell(
                        onTap: () => _showReminderActions(context, ref, item),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(
                              color: isOverdue
                                  ? AppColors.error
                                  : isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox completed toggle
                              IconButton(
                                icon: Icon(
                                  item.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  color: item.isCompleted
                                      ? AppColors.lime
                                      : AppColors.mutedText,
                                ),
                                onPressed: () {
                                  ref
                                      .read(reminderListProvider.notifier)
                                      .toggleCompleted(item.id);
                                },
                              ),
                              const SizedBox(width: AppSpacing.sm),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: AppTypography.titleSmall(context)
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                            decoration: item.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: item.isCompleted
                                                ? AppColors.mutedText
                                                : null,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event_outlined,
                                          size: 14,
                                          color: isOverdue
                                              ? AppColors.error
                                              : AppColors.mutedText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          CardlyFormatters.formatDate(
                                            item.dueDate,
                                          ),
                                          style: AppTypography.caption(context)
                                              .copyWith(
                                                color: isOverdue
                                                    ? AppColors.error
                                                    : AppColors.mutedText,
                                                fontWeight: isOverdue
                                                    ? FontWeight.w700
                                                    : null,
                                              ),
                                        ),
                                        if (isOverdue) ...[
                                          const Text(
                                            ' • ',
                                            style: TextStyle(
                                              color: AppColors.error,
                                            ),
                                          ),
                                          Text(
                                            'Lewat Waktu',
                                            style:
                                                AppTypography.caption(
                                                  context,
                                                ).copyWith(
                                                  color: AppColors.error,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.more_vert,
                                size: 20,
                                color: AppColors.mutedText,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: filteredReminders.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/reminders/create'),
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.ink,
              icon: const Icon(Icons.add),
              label: Text(
                'Tambah',
                style: AppTypography.titleSmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.lime : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? AppColors.lime : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption(context).copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.ink : null,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showReminderActions(
    BuildContext context,
    WidgetRef ref,
    ReminderItem item,
  ) {
    CardlyBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.title,
            style: AppTypography.titleMedium(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: Icon(
              item.isCompleted ? Icons.undo : Icons.check_circle_outline,
            ),
            title: Text(
              item.isCompleted ? 'Tandai Belum Selesai' : 'Tandai Selesai',
            ),
            onTap: () {
              Navigator.pop(context);
              ref.read(reminderListProvider.notifier).toggleCompleted(item.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Pengingat'),
            onTap: () {
              Navigator.pop(context);
              context.push('/reminders/${item.id}/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text(
              'Hapus Pengingat',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(context);
              ref.read(reminderListProvider.notifier).deleteReminder(item.id);
              CardlyToast.showSuccess(context, 'Pengingat berhasil dihapus');
            },
          ),
        ],
      ),
    );
  }
}
