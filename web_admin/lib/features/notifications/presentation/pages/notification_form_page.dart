import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/notification_provider.dart';

// ============================================================
// NOTIFICATION FORM PAGE (New Notification)
// ============================================================

class NotificationFormPage extends ConsumerStatefulWidget {
  const NotificationFormPage({super.key});

  @override
  ConsumerState<NotificationFormPage> createState() =>
      _NotificationFormPageState();
}

class _NotificationFormPageState
    extends ConsumerState<NotificationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController();

  String _targetAudience = 'all';
  bool _isScheduled = false;
  DateTime? _scheduledAt;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _userIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _sendNow() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(notificationActionNotifierProvider.notifier).sendNow(
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            targetAudience: _targetAudience,
            targetUserId: _targetAudience == 'specific'
                ? _userIdCtrl.text.trim()
                : null,
          );
      if (mounted) {
        context.showSnackBar('Notification sent!', isSuccess: true);
        context.go('/notifications');
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _schedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledAt == null) {
      context.showSnackBar('Please pick a schedule time', isSuccess: false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(notificationActionNotifierProvider.notifier).schedule(
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            targetAudience: _targetAudience,
            targetUserId: _targetAudience == 'specific'
                ? _userIdCtrl.text.trim()
                : null,
            scheduledAt: _scheduledAt!,
          );
      if (mounted) {
        context.showSnackBar('Notification scheduled!', isSuccess: true);
        context.go('/notifications');
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    if (_titleCtrl.text.trim().isEmpty) {
      context.showSnackBar('Title required to save draft', isSuccess: false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(notificationActionNotifierProvider.notifier).saveDraft(
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            targetAudience: _targetAudience,
            targetUserId: _targetAudience == 'specific'
                ? _userIdCtrl.text.trim()
                : null,
          );
      if (mounted) {
        context.showSnackBar('Draft saved', isSuccess: true);
        context.go('/notifications');
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Title
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/notifications'),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text('New Notification', style: AppTextStyles.displayMedium),
            ],
          ),
          const SizedBox(height: 20),

          // Info Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sending a notification writes to Firestore. '
                    'A Cloud Function will dispatch FCM push notifications automatically.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Form card
          SectionCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text('Title', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleCtrl,
                      style: AppTextStyles.bodyMedium,
                      decoration: const InputDecoration(
                          hintText: 'Notification title'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Body
                    Text('Body', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bodyCtrl,
                      maxLines: 3,
                      style: AppTextStyles.bodyMedium,
                      decoration: const InputDecoration(
                          hintText: 'Notification message body'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Body is required'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Target Audience
                    Text('Target Audience', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _RadioOption(
                          label: 'All Users',
                          value: 'all',
                          groupValue: _targetAudience,
                          onChanged: (v) =>
                              setState(() => _targetAudience = v!),
                        ),
                        const SizedBox(width: 24),
                        _RadioOption(
                          label: 'Specific User',
                          value: 'specific',
                          groupValue: _targetAudience,
                          onChanged: (v) =>
                              setState(() => _targetAudience = v!),
                        ),
                      ],
                    ),
                    if (_targetAudience == 'specific') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _userIdCtrl,
                        style: AppTextStyles.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'Target User ID (Firestore UID)',
                          prefixIcon: Icon(Icons.person_outline, size: 18),
                        ),
                        validator: (v) =>
                            _targetAudience == 'specific' &&
                                    (v == null || v.trim().isEmpty)
                                ? 'User ID required for specific target'
                                : null,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Schedule toggle
                    Row(
                      children: [
                        Switch(
                          value: _isScheduled,
                          onChanged: (v) => setState(() {
                            _isScheduled = v;
                            if (!v) _scheduledAt = null;
                          }),
                          activeColor: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text('Schedule for later',
                            style: AppTextStyles.labelMedium),
                      ],
                    ),
                    if (_isScheduled) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickScheduleDateTime,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                _scheduledAt != null
                                    ? DateFormat('dd/MM/yyyy HH:mm')
                                        .format(_scheduledAt!)
                                    : 'Pick date & time',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _scheduledAt != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _saveDraft,
                          icon: const Icon(Icons.save_outlined, size: 16),
                          label: const Text('Save Draft'),
                        ),
                        Row(
                          children: [
                            if (_isScheduled)
                              FilledButton.icon(
                                onPressed: _isLoading ? null : _schedule,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.schedule_send_rounded,
                                        size: 16),
                                label: const Text('Schedule'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.info,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              )
                            else
                              FilledButton.icon(
                                onPressed: _isLoading ? null : _sendNow,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.send_rounded,
                                        size: 16),
                                label: const Text('Send Now'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        Text(label, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}
