import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/feedback_provider.dart';

// ============================================================
// FEEDBACK DETAIL PAGE
// ============================================================

class FeedbackDetailPage extends ConsumerStatefulWidget {
  final String feedbackId;
  const FeedbackDetailPage({super.key, required this.feedbackId});

  @override
  ConsumerState<FeedbackDetailPage> createState() =>
      _FeedbackDetailPageState();
}

class _FeedbackDetailPageState extends ConsumerState<FeedbackDetailPage> {
  final _replyCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(feedbackActionNotifierProvider.notifier)
          .reply(
            widget.feedbackId,
            reply: _replyCtrl.text.trim(),
            repliedBy: 'Admin',
          );
      if (mounted) {
        _replyCtrl.clear();
        context.showSnackBar('Reply sent & feedback resolved',
            isSuccess: true);
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackAsync =
        ref.watch(feedbackDetailProvider(widget.feedbackId));

    return PageContainer(
      child: feedbackAsync.when(
        loading: () =>
            const AppLoadingWidget(message: 'Loading feedback...'),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (feedback) {
          if (feedback == null) {
            return const AppEmptyWidget(
              title: 'Feedback not found',
              subtitle: 'This feedback may have been deleted.',
              icon: Icons.feedback_outlined,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + Title
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/feedbacks'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Feedback Detail',
                        style: AppTextStyles.displayMedium),
                  ),
                  StatusBadge.fromString(feedback.status),
                ],
              ),
              const SizedBox(height: 20),

              // User Info Card
              SectionCard(
                title: 'User',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage: feedback.userAvatar.isNotEmpty
                            ? NetworkImage(feedback.userAvatar)
                            : null,
                        child: feedback.userAvatar.isEmpty
                            ? Text(
                                feedback.userDisplayName.isNotEmpty
                                    ? feedback.userDisplayName[0]
                                        .toUpperCase()
                                    : '?',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: AppColors.primary),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(feedback.userDisplayName,
                              style: AppTextStyles.labelLarge),
                          Text(feedback.createdAt.timeAgo,
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Feedback Content
              SectionCard(
                title: feedback.subject,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Text(feedback.message,
                      style: AppTextStyles.bodyMedium),
                ),
              ),
              const SizedBox(height: 16),

              // Existing reply
              if (feedback.hasReply) ...[
                SectionCard(
                  title: 'Admin Reply',
                  trailing: Text(
                    'by ${feedback.repliedBy ?? 'Admin'} · ${feedback.repliedAt?.dateOnly ?? ''}',
                    style: AppTextStyles.caption,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Text(feedback.adminReply!,
                          style: AppTextStyles.bodyMedium),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Reply / Action area (only if open)
              if (feedback.isOpen) ...[
                SectionCard(
                  title: 'Reply to User',
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _replyCtrl,
                          maxLines: 4,
                          style: AppTextStyles.bodyMedium,
                          decoration: const InputDecoration(
                            hintText:
                                'Write your reply here... (sending will auto-resolve this feedback)',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'Mark Resolved',
                                  message:
                                      'Mark this feedback as resolved without replying?',
                                  confirmLabel: 'Resolve',
                                  isDanger: false,
                                );
                                if (confirmed == true && mounted) {
                                  await ref
                                      .read(feedbackActionNotifierProvider
                                          .notifier)
                                      .markResolved(widget.feedbackId);
                                  if (context.mounted) {
                                    context.showSnackBar('Marked as resolved',
                                        isSuccess: true);
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 16),
                              label: const Text('Mark Resolved'),
                            ),
                            FilledButton.icon(
                              onPressed: _isSubmitting ? null : _submitReply,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(Icons.send_rounded, size: 16),
                              label: const Text('Send Reply'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Reopen option
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(feedbackActionNotifierProvider.notifier)
                          .reopen(widget.feedbackId);
                      if (context.mounted) {
                        context.showSnackBar('Feedback reopened',
                            isSuccess: true);
                      }
                    },
                    icon:
                        const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reopen Feedback'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
