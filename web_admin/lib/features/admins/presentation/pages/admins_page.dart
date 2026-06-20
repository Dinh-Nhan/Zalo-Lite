import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/extensions/datetime_extension.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../providers/admin_provider.dart';
import '../../domain/models/admin_account.dart';

// ============================================================
// ADMINS PAGE - Admin Management
// ============================================================

class AdminsPage extends ConsumerWidget {
  const AdminsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(adminsStreamProvider);

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Management', style: AppTextStyles.displayMedium),
                  adminsAsync.when(
                    data: (list) => Text('${list.length} admins',
                        style: AppTextStyles.bodySmall),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _showAdminFormDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Admin'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Table
          SectionCard(
            child: adminsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: AppLoadingWidget(message: 'Loading admins...'),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: AppErrorWidget(message: e.toString()),
              ),
              data: (admins) {
                if (admins.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: AppEmptyWidget(
                      title: 'No admins found',
                      subtitle: 'Click "Add Admin" to create the first admin.',
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                  );
                }
                return _AdminTable(admins: admins);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminFormDialog(BuildContext context, WidgetRef ref,
      {AdminAccount? existing}) {
    showDialog(
      context: context,
      builder: (_) => _AdminFormDialog(existing: existing),
    );
  }
}

// ─── Admin Table ─────────────────────────────────────────────

class _AdminTable extends ConsumerWidget {
  final List<AdminAccount> admins;
  const _AdminTable({required this.admins});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2.5),
          2: FixedColumnWidth(120),
          3: FixedColumnWidth(100),
          4: FixedColumnWidth(140),
          5: FixedColumnWidth(160),
        },
        children: [
          TableRow(
            decoration:
                const BoxDecoration(color: AppColors.surfaceVariant),
            children: [
              _th('Name'),
              _th('Email'),
              _th('Role'),
              _th('Status'),
              _th('Created'),
              _th('Actions'),
            ],
          ),
          ...admins.asMap().entries.map((entry) {
            final i = entry.key;
            final admin = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: i.isEven
                    ? AppColors.surface
                    : AppColors.surfaceVariant.withOpacity(0.3),
              ),
              children: [
                _td(Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: admin.isAdmin
                          ? AppColors.primaryContainer
                          : AppColors.infoContainer,
                      child: Text(
                        admin.displayName.isNotEmpty
                            ? admin.displayName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.caption.copyWith(
                          color: admin.isAdmin
                              ? AppColors.primary
                              : AppColors.info,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        admin.displayName,
                        style: AppTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )),
                _td(Text(admin.email,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
                _td(_RoleBadge(role: admin.role)),
                _td(StatusBadge.fromString(
                    admin.isActive ? 'active' : 'inactive')),
                _td(Text(admin.createdAt.dateOnly,
                    style: AppTextStyles.caption)),
                _td(_AdminActions(admin: admin)),
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

// ─── Role Badge ───────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.primaryContainer : AppColors.infoContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: isAdmin ? AppColors.primary : AppColors.info,
        ),
      ),
    );
  }
}

// ─── Admin Actions ────────────────────────────────────────────

class _AdminActions extends ConsumerWidget {
  final AdminAccount admin;
  const _AdminActions({required this.admin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(adminActionNotifierProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit
        Tooltip(
          message: 'Edit admin',
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _AdminFormDialog(existing: admin),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        // Toggle Active
        Tooltip(
          message: admin.isActive ? 'Deactivate' : 'Activate',
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: admin.isActive ? 'Deactivate Admin' : 'Activate Admin',
                message: admin.isActive
                    ? 'Deactivate ${admin.displayName}?'
                    : 'Activate ${admin.displayName}?',
                confirmLabel: admin.isActive ? 'Deactivate' : 'Activate',
                isDanger: admin.isActive,
              );
              if (confirmed == true) {
                await notifier.updateAdmin(admin.id,
                    isActive: !admin.isActive);
                if (context.mounted) {
                  context.showSnackBar(
                    admin.isActive ? 'Admin deactivated' : 'Admin activated',
                    isSuccess: true,
                  );
                }
              }
            },
            icon: Icon(
              admin.isActive
                  ? Icons.block_rounded
                  : Icons.check_circle_outline,
              size: 18,
            ),
            color: admin.isActive ? AppColors.warning : AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        // Delete
        Tooltip(
          message: 'Delete admin',
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'Delete Admin',
                message:
                    'Delete ${admin.displayName}? This action cannot be undone.',
                confirmLabel: 'Delete',
                isDanger: true,
              );
              if (confirmed == true) {
                await notifier.deleteAdmin(admin.id);
                if (context.mounted) {
                  context.showSnackBar('Admin deleted', isSuccess: true);
                }
              }
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

// ─── Admin Form Dialog ────────────────────────────────────────

class _AdminFormDialog extends ConsumerStatefulWidget {
  final AdminAccount? existing;
  const _AdminFormDialog({this.existing});

  @override
  ConsumerState<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends ConsumerState<_AdminFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _nameCtrl;
  late String _role;
  bool _isLoading = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController(text: widget.existing?.id ?? '');
    _emailCtrl =
        TextEditingController(text: widget.existing?.email ?? '');
    _nameCtrl =
        TextEditingController(text: widget.existing?.displayName ?? '');
    _role = widget.existing?.role ?? 'moderator';
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final notifier = ref.read(adminActionNotifierProvider.notifier);
    try {
      if (isEditing) {
        await notifier.updateAdmin(
          widget.existing!.id,
          displayName: _nameCtrl.text.trim(),
          role: _role,
        );
      } else {
        await notifier.createAdmin(
          id: _idCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          displayName: _nameCtrl.text.trim(),
          role: _role,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        context.showSnackBar(
          isEditing ? 'Admin updated' : 'Admin created',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Icon(
                      isEditing
                          ? Icons.edit_outlined
                          : Icons.admin_panel_settings_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? 'Edit Admin' : 'Add New Admin',
                      style: AppTextStyles.h3,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (!isEditing)
                  Text(
                    'The Firebase Auth user must already exist for this UID.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.warning),
                  ),
                const SizedBox(height: 24),

                // UID (only for create)
                if (!isEditing) ...[
                  Text('Firebase UID', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _idCtrl,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                        hintText: 'Firebase Auth UID'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'UID is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Email', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                        hintText: 'admin@example.com'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Display Name
                Text('Display Name', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  style: AppTextStyles.bodyMedium,
                  decoration:
                      const InputDecoration(hintText: 'John Doe'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Role
                Text('Role', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _role,
                      isExpanded: true,
                      onChanged: (v) =>
                          setState(() => _role = v ?? 'moderator'),
                      style: AppTextStyles.bodyMedium,
                      dropdownColor: AppColors.surfaceElevated,
                      items: const [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin — Full access'),
                        ),
                        DropdownMenuItem(
                          value: 'moderator',
                          child: Text('Moderator — Limited access'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(isEditing ? 'Update' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
