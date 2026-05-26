import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/friends/services/friend_service.dart';

/// Widget thanh tìm kiếm người dùng (chỉ là input).
///
/// Không chứa dropdown kết quả. Kết quả được quản lý bởi parent widget
/// thông qua [GlobalSearchFieldController].
class GlobalSearchField extends StatefulWidget {
  final GlobalSearchFieldController controller;
  final String? hintText;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? hintColor;
  final double height;
  final bool autofocus;

  const GlobalSearchField({
    super.key,
    required this.controller,
    this.hintText,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.hintColor,
    this.height = 40,
    this.autofocus = false,
  });

  @override
  State<GlobalSearchField> createState() => _GlobalSearchFieldState();
}

class _GlobalSearchFieldState extends State<GlobalSearchField> {
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    widget.controller._detach();
    super.dispose();
  }

  void _onTextChanged(String query) {
    widget.controller._onQueryChanged(query);
  }

  void clear() {
    _debounce?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return _buildSearchBar(isDark);
      },
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final bgColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5));
    final textColor =
        widget.textColor ?? AppColors.getTextPrimary(isDark);
    final hintColor = widget.hintColor ??
        AppColors.getTextSecondary(isDark);
    final iconColor = widget.iconColor ??
        AppColors.getTextSecondary(isDark);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(width: widget.height == 40 ? 14 : 12),
          Icon(Icons.search, color: iconColor, size: 20),
          SizedBox(width: widget.height == 40 ? 12 : 10),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              style: TextStyle(color: textColor, fontSize: 14),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Tìm kiếm',
                hintStyle: TextStyle(color: hintColor, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _onTextChanged,
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                widget.controller.clear();
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close, size: 18, color: iconColor),
              ),
            )
          else
            SizedBox(width: widget.height == 40 ? 14 : 12),
        ],
      ),
    );
  }
}

/// Controller để parent widget quản lý trạng thái tìm kiếm.
///
/// Dùng chung cho cả [GlobalSearchField] và [GlobalSearchResults].
/// Parent tạo controller, truyền vào GlobalSearchField để nhận input,
/// và dùng results từ controller để render [GlobalSearchResults].
class GlobalSearchFieldController extends ChangeNotifier {
  _GlobalSearchFieldState? _state;

  String _query = '';
  List<UserSearchModel> _results = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasSearched = false;
  Timer? _debounce;

  String get text => _query;
  List<UserSearchModel> get results => _results;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get hasSearched => _hasSearched;
  bool get hasResults => _results.isNotEmpty;

  /// Số mili-giây debounce. Mặc định 500.
  int debounceMs = 500;

  void _attach(_GlobalSearchFieldState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
    _debounce?.cancel();
  }

  void _onQueryChanged(String query) {
    _query = query;
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      _debounce?.cancel();
      _results = [];
      _isLoading = false;
      _hasSearched = false;
      _hasError = false;
      notifyListeners();
      return;
    }

    _debounce = Timer(Duration(milliseconds: debounceMs), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _results = await FriendService.searchUsers(query);
      _hasSearched = true;
    } catch (_) {
      _results = [];
      _hasError = true;
      _hasSearched = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _debounce?.cancel();
    _query = '';
    _results = [];
    _isLoading = false;
    _hasError = false;
    _hasSearched = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// Widget hiển thị kết quả tìm kiếm.
///
/// Đặt bên dưới [GlobalSearchField]. Kết quả được ghim ở đây,
///
/// không bị ẩn khi focus ra ngoài thanh tìm kiếm.
class GlobalSearchResults extends StatelessWidget {
  final GlobalSearchFieldController controller;
  final void Function(UserSearchModel user) onResultTap;
  final Color? backgroundColor;
  final double maxHeight;

  const GlobalSearchResults({
    super.key,
    required this.controller,
    required this.onResultTap,
    this.backgroundColor,
    this.maxHeight = 320,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (!controller.hasSearched && controller.text.isEmpty) {
              return const SizedBox.shrink();
            }

            final surfaceColor =
                backgroundColor ?? (isDark ? const Color(0xFF2D2D44) : Colors.white);
            final dividerColor = isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200;

            return Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildContent(isDark, dividerColor),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(bool isDark, Color dividerColor) {
    if (controller.isLoading) {
      return _StateWidget(
        icon: Icons.search,
        message: 'Đang tìm kiếm...',
        isDark: isDark,
      );
    }

    if (controller.hasError) {
      return _StateWidget(
        icon: Icons.wifi_off_rounded,
        message: 'Không thể kết nối',
        isDark: isDark,
      );
    }

    if (controller.hasSearched && controller.results.isEmpty) {
      return _StateWidget(
        icon: Icons.search_off_rounded,
        message: 'Không tìm thấy người dùng',
        isDark: isDark,
      );
    }

    if (controller.results.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: controller.results.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: dividerColor),
      itemBuilder: (context, index) {
        final user = controller.results[index];
        return _ResultTile(
          user: user,
          onTap: () => onResultTap(user),
          isDark: isDark,
        );
      },
    );
  }
}

class _StateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;

  const _StateWidget({
    required this.icon,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white54 : Colors.grey.shade400;
    final textColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon == Icons.search) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryBlue,
              ),
            ),
          ] else
            Icon(icon, size: 36, color: iconColor),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 13, color: textColor)),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final UserSearchModel user;
  final VoidCallback onTap;
  final bool isDark;

  const _ResultTile({
    required this.user,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isDark ? const Color(0xFF2D2D44) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _avatarColor(user.fullName),
              backgroundImage:
                  user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
              child: user.avatar.isEmpty
                  ? Text(
                      _initials(user.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : user.email,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.email.isNotEmpty && user.fullName.isNotEmpty)
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 12, color: subColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (user.status)
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}
