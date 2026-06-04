import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/friendship_provider.dart';
import '../../domain/models/admin_friendship.dart';

// ============================================================
// FRIENDSHIPS PAGE
// ============================================================

class FriendshipsPage extends ConsumerStatefulWidget {
  const FriendshipsPage({super.key});

  @override
  ConsumerState<FriendshipsPage> createState() => _FriendshipsPageState();
}

class _FriendshipsPageState extends ConsumerState<FriendshipsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendshipsAsync = ref.watch(friendshipsStreamProvider);
    final statusFilter = ref.watch(friendshipStatusFilterProvider);

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Friendship Management', style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          friendshipsAsync.when(
            data: (items) =>
                Text('${items.length} records', style: AppTextStyles.bodySmall),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // Search + filter
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchCtrl,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Search by user ID or name...',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.textMuted),
                  ),
                  onChanged: (v) => ref
                      .read(friendshipSearchQueryProvider.notifier)
                      .state = v,
                ),
              ),
              const SizedBox(width: 12),
              _StatusDropdown(
                value: statusFilter,
                onChanged: (v) =>
                    ref.read(friendshipStatusFilterProvider.notifier).state = v,
              ),
            ],
          ),
          const SizedBox(height: 16),

          SectionCard(
            child: friendshipsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: AppLoadingWidget(message: 'Loading friendships...'),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: AppErrorWidget(message: e.toString()),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: AppEmptyWidget(
                      title: 'No friendships found',
                      subtitle: 'Try adjusting your filter',
                      icon: Icons.group_outlined,
                    ),
                  );
                }
                return _FriendshipTable(items: items);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendshipTable extends ConsumerWidget {
  final List<AdminFriendship> items;
  const _FriendshipTable({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(friendshipActionNotifierProvider.notifier);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FixedColumnWidth(100),
          3: FixedColumnWidth(110),
          4: FixedColumnWidth(130),
          5: FixedColumnWidth(80),
        },
        children: [
          TableRow(
            decoration:
                const BoxDecoration(color: AppColors.surfaceVariant),
            children: [
              _th('Sender ID'),
              _th('Addressee'),
              _th('Status'),
              _th('Source'),
              _th('Created'),
              _th('Actions'),
            ],
          ),
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            return TableRow(
              decoration: BoxDecoration(
                color: i.isEven
                    ? AppColors.surface
                    : AppColors.surfaceVariant.withOpacity(0.3),
              ),
              children: [
                _td(SelectableText(item.senderId,
                    style: AppTextStyles.bodySmall)),
                _td(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.addresseeName != null)
                      Text(item.addresseeName!,
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    SelectableText(item.addresseeId,
                        style: AppTextStyles.caption),
                  ],
                )),
                _td(StatusBadge.fromString(item.status)),
                _td(Text(item.sourceType, style: AppTextStyles.caption)),
                _td(Text(item.createdAt.dateOnly,
                    style: AppTextStyles.caption)),
                _td(Tooltip(
                  message: 'Delete relationship',
                  child: IconButton(
                    onPressed: () async {
                      final ok = await ConfirmDialog.show(
                        context,
                        title: 'Delete Friendship',
                        message:
                            'Remove this friendship record permanently?',
                        confirmLabel: 'Delete',
                        isDanger: true,
                      );
                      if (ok == true) {
                        await notifier.delete(item.id);
                        if (context.mounted) {
                          context.showSnackBar('Friendship removed',
                              isSuccess: true);
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                  ),
                )),
              ],
            );
          }),
        ],
      ),
    );
  }

  static Widget _th(String label) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(label, style: AppTextStyles.labelMedium),
        ),
      );

  static Widget _td(Widget child) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      );
}

class _StatusDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          onChanged: onChanged,
          style: AppTextStyles.bodyMedium,
          dropdownColor: AppColors.surfaceElevated,
          items: const [
            DropdownMenuItem(value: null, child: Text('All Status')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
            DropdownMenuItem(value: 'declined', child: Text('Declined')),
            DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
          ],
        ),
      ),
    );
  }
}
