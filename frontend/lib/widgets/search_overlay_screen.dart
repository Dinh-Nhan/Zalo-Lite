import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/dark_mode_config.dart';
import 'package:frontend/features/friends/services/friend_service.dart';

/// Callback khi chọn một người dùng.
typedef OnUserSelected = void Function({
  required String userId,
  required String name,
  required String? avatar,
});

/// Màn hình tìm kiếm overlay.
///
/// Hiển thị danh sách liên hệ gần đây (avatar + tên) ở dạng cuộn ngang.
/// Khi gõ, danh sách kết quả tìm kiếm xổ xuống bên dưới sau debounce 0.5s.
/// Nút quay lại gọi [onBack], cho phép parent quyết định hành động
/// (ví dụ: Navigator.pop hoặc chuyển tab).
class SearchOverlayScreen extends StatefulWidget {
  /// Callback khi nhấn nút quay lại.
  final VoidCallback onBack;

  /// Callback khi chọn một người dùng từ kết quả tìm kiếm.
  final OnUserSelected? onSearchResultTap;

  /// Danh sách liên hệ gần đây (avatar + tên).
  final List<Map<String, dynamic>> recentContacts;

  /// Callback khi chọn một liên hệ gần đây.
  final void Function(Map<String, dynamic> contact)? onRecentContactTap;

  const SearchOverlayScreen({
    super.key,
    required this.onBack,
    this.onSearchResultTap,
    this.recentContacts = const [],
    this.onRecentContactTap,
  });

  @override
  State<SearchOverlayScreen> createState() => _SearchOverlayScreenState();
}

class _SearchOverlayScreenState extends State<SearchOverlayScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<UserSearchModel> _results = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      _debounce?.cancel();
      setState(() {
        _results = [];
        _isLoading = false;
        _hasSearched = false;
        _hasError = false;
      });
      return;
    }

    setState(() {});

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await FriendService.searchUsers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _hasSearched = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
          _hasError = true;
          _hasSearched = true;
        });
      }
    }
  }

  void _onRecentContactTap(Map<String, dynamic> contact) {
    widget.onRecentContactTap?.call(contact);
  }

  void _onSearchResultTap(UserSearchModel user) {
    widget.onSearchResultTap?.call(
      userId: user.id,
      name: user.fullName.isNotEmpty ? user.fullName : user.email,
      avatar: user.avatar.isNotEmpty ? user.avatar : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        final bg = AppColors.getBackground(isDark);
        final surface = AppColors.getSurface(isDark);
        final headerBg = isDark ? const Color(0xFF1A1A1A) : AppColors.primaryBlue;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              children: [
                // Header: back + search field
                _buildHeader(headerBg, isDark),
                // Nội dung
                Expanded(
                  child: _buildBody(isDark, surface),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color headerBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      color: headerBg,
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          // Search field
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Tìm tin nhắn, người trong Zalo',
                        hintStyle: TextStyle(color: Colors.white70, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _results = [];
                          _isLoading = false;
                          _hasSearched = false;
                          _hasError = false;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close, color: Colors.white70, size: 18),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          // Cancel button
          TextButton(
            onPressed: widget.onBack,
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark, Color surface) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    if (hasQuery) {
      return _buildSearchResults(isDark);
    }

    return _buildRecentContacts(isDark, surface);
  }

  Widget _buildRecentContacts(bool isDark, Color surface) {
    if (widget.recentContacts.isEmpty) {
      return Center(
        child: Text(
          'Chưa có liên hệ gần đây',
          style: TextStyle(
            color: AppColors.getTextSecondary(isDark),
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            'Tin nhắn trực tiếp',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.recentContacts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final contact = widget.recentContacts[index];
              return _RecentContactChip(
                contact: contact,
                isDark: isDark,
                onTap: () => _onRecentContactTap(contact),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Text(
              'Tìm kiếm người trong danh bạ Zalo',
              style: TextStyle(
                color: AppColors.getTextSecondary(isDark),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 12),
            Text('Đang tìm kiếm...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Không thể kết nối',
              style: TextStyle(
                color: AppColors.getTextSecondary(isDark),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasSearched && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy người dùng',
              style: TextStyle(
                color: AppColors.getTextSecondary(isDark),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: AppColors.getDivider(isDark)),
      itemBuilder: (context, index) {
        final user = _results[index];
        return _SearchResultTile(
          user: user,
          isDark: isDark,
          onTap: () => _onSearchResultTap(user),
        );
      },
    );
  }
}

/// Chip liên hệ gần đây: avatar tròn + tên bên dưới.
class _RecentContactChip extends StatelessWidget {
  final Map<String, dynamic> contact;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentContactChip({
    required this.contact,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = contact['name'] ?? '';
    final avatarColor = contact['avatarColor'] ?? const Color(0xFF4CAF50);
    final avatar = contact['avatar'];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: avatarColor,
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 64,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextPrimary(isDark),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
}

/// Dòng kết quả tìm kiếm.
class _SearchResultTile extends StatelessWidget {
  final UserSearchModel user;
  final bool isDark;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.user,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.getTextPrimary(isDark);
    final subColor = AppColors.getTextSecondary(isDark);
    final bg = AppColors.getSurface(isDark);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _avatarColor(user.fullName),
              backgroundImage:
                  user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
              child: user.avatar.isEmpty
                  ? Text(
                      _initials(user.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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
                      fontSize: 15,
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
                width: 10,
                height: 10,
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
