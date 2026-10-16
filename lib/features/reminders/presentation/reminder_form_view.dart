import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_text_field.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../domain/reminder_model.dart';

class ReminderFormView extends ConsumerStatefulWidget {
  final String? reminderId;

  const ReminderFormView({super.key, this.reminderId});

  @override
  ConsumerState<ReminderFormView> createState() => _ReminderFormViewState();
}

class _ReminderFormViewState extends ConsumerState<ReminderFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String? _selectedLinkedItemId;
  String _repeatOption = 'Tidak Berulang';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 30));

    if (widget.reminderId != null) {
      final list = ref.read(reminderListProvider);
      final existing = list.firstWhere(
        (r) => r.id == widget.reminderId,
        orElse: () => ReminderItem(id: '', title: '', dueDate: DateTime.now()),
      );
      _titleController = TextEditingController(text: existing.title);
      _notesController = TextEditingController(text: existing.notes ?? '');
      _selectedDate = existing.dueDate;
      _selectedTime = TimeOfDay(
        hour: existing.dueDate.hour,
        minute: existing.dueDate.minute,
      );
      _selectedLinkedItemId = existing.linkedItemId;
    } else {
      _titleController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final combinedDueDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final isEdit = widget.reminderId != null;
    final item = ReminderItem(
      id: isEdit ? widget.reminderId! : const Uuid().v4(),
      title: _titleController.text.trim(),
      dueDate: combinedDueDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      linkedItemId: _selectedLinkedItemId,
    );

    if (isEdit) {
      await ref.read(reminderListProvider.notifier).updateReminder(item);
    } else {
      await ref.read(reminderListProvider.notifier).addReminder(item);
    }

    if (mounted) {
      CardlyToast.showSuccess(
        context,
        isEdit ? 'Pengingat berhasil diperbarui' : 'Pengingat berhasil dibuat',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardListProvider);
    final documents = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reminderId != null ? 'Edit Pengingat' : 'Buat Pengingat',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardlyTextField(
                controller: _titleController,
                label: 'Judul Pengingat',
                hint: 'cth. Perpanjangan Masa Berlaku SIM A',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul pengingat wajib diisi'
                    : null,
              ),

              const SizedBox(height: AppSpacing.md),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime(2050),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(AppRadius.input),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal Jatuh Tempo',
                              style: AppTypography.caption(context)
                                  .copyWith(color: AppColors.mutedText),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CardlyFormatters.formatDate(_selectedDate),
                              style: AppTypography.bodyMedium(context)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Time Picker
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
                borderRadius: BorderRadius.circular(AppRadius.input),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        size: 20,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waktu Notifikasi',
                              style: AppTypography.caption(context)
                                  .copyWith(color: AppColors.mutedText),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} WIB',
                              style: AppTypography.bodyMedium(context)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Tautkan ke Dokumen / Kartu
              DropdownButtonFormField<String>(
                initialValue: _selectedLinkedItemId,
                decoration: const InputDecoration(
                  labelText: 'Tautkan ke Kartu atau Dokumen (Opsional)',
                ),
                hint: const Text('Pilih item terkait'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tanpa Tautan'),
                  ),
                  ...cards.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('💳 Kartu: ${c.title}'),
                    ),
                  ),
                  ...documents.map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: Text('📄 Dokumen: ${d.title}'),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _selectedLinkedItemId = val);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Repeat
              DropdownButtonFormField<String>(
                initialValue: _repeatOption,
                decoration: const InputDecoration(
                  labelText: 'Pengulangan Notifikasi',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Tidak Berulang',
                    child: Text('Tidak Berulang'),
                  ),
                  DropdownMenuItem(
                    value: 'Setiap Bulan',
                    child: Text('Setiap Bulan'),
                  ),
                  DropdownMenuItem(
                    value: 'Setiap Tahun',
                    child: Text('Setiap Tahun'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _repeatOption = val);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Notes
              CardlyTextField(
                controller: _notesController,
                label: 'Catatan Tambahan (Opsional)',
                hint: 'cth. Membawa fotokopi KTP dan surat kesehatan',
                maxLines: 3,
              ),

              const SizedBox(height: AppSpacing.xl),

              CardlyButton(
                text: widget.reminderId != null
                    ? 'Simpan Perubahan'
                    : 'Buat Pengingat',
                onPressed: _saveReminder,
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
