import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/providers/friend_provider.dart';
import 'package:frontend/services/auth_service.dart';
import '../providers/feed_provider.dart';

class _PickedImage {
  final XFile file;
  final Uint8List bytes;

  _PickedImage({required this.file, required this.bytes});
}

class CreatePostScreen extends StatefulWidget {
  final String currentUserName;
  final String currentUserAvatar;
  final bool shouldUpdateAvatarOnSubmit;
  final String? avatarImagePath;

  const CreatePostScreen({
    super.key,
    required this.currentUserName,
    required this.currentUserAvatar,
    this.preSelectedBytes,
    this.preSelectedPath,
    this.shouldUpdateAvatarOnSubmit = false,
    this.avatarImagePath,
  });

  final Uint8List? preSelectedBytes;
  final String? preSelectedPath;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<_PickedImage> _selectedImages = [];
  XFile? _preSelectedXFile;
  String _visibility = 'public';
  List<String> _selectedFriendIds = [];
  bool _isLoading = false;
  bool _isPickingImages = false;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedBytes != null && widget.preSelectedPath != null) {
      _preSelectedXFile = XFile(widget.preSelectedPath!);
      _selectedImages.add(_PickedImage(
        file: _preSelectedXFile!,
        bytes: widget.preSelectedBytes!,
      ));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final friendProvider = context.read<FriendProvider>();
      if (friendProvider.friends.isEmpty) {
        friendProvider.loadFriends();
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Color get _avatarColor {
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
    if (widget.currentUserName.isEmpty) return colors[0];
    return colors[widget.currentUserName.codeUnitAt(0) % colors.length];
  }

  String get _userInitials {
    if (widget.currentUserName.isEmpty) return '?';
    final parts = widget.currentUserName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return widget.currentUserName[0].toUpperCase();
  }

  Future<void> _pickImages() async {
    if (_isPickingImages) return;

    _isPickingImages = true;
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      var effectiveImages = images;
      if (effectiveImages.isEmpty) {
        final lostData = await _imagePicker.retrieveLostData();
        effectiveImages = lostData.files ?? const <XFile>[];
      }

      if (effectiveImages.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không nhận được ảnh từ thư viện. Hãy thử chọn lại hoặc dùng ảnh đã có sẵn trong Gallery của máy ảo.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final newImages = <_PickedImage>[];
      for (final img in effectiveImages) {
        final bytes = await img.readAsBytes();
        newImages.add(_PickedImage(file: img, bytes: bytes));
      }

      if (!mounted) return;
      setState(() {
        _selectedImages.addAll(newImages);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isPickingImages = false;
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showVisibilitySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => _VisibilitySheet(
        currentVisibility: _visibility,
        selectedFriendIds: _selectedFriendIds,
        onVisibilityChanged: (visibility, friendIds) {
          setState(() {
            _visibility = visibility;
            _selectedFriendIds = friendIds;
          });
        },
      ),
    );
  }

  void _showFriendSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return _FriendSelectorSheet(
            selectedFriendIds: _selectedFriendIds,
            onSelectionChanged: (ids) {
              setState(() {
                _selectedFriendIds = ids;
              });
            },
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung hoặc chọn ảnh'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.shouldUpdateAvatarOnSubmit) {
        final avatarPath = widget.avatarImagePath;
        if (avatarPath == null || avatarPath.isEmpty) {
          throw Exception('Thiếu ảnh để cập nhật avatar');
        }
        await AuthService.updateAvatar(XFile(avatarPath));
      }

      final provider = context.read<FeedProvider>();
      final xfiles = _selectedImages.map((p) => p.file).toList();
      final success = await provider.createPost(
        content: _contentController.text.trim(),
        images: xfiles.isNotEmpty ? xfiles : null,
        visibility: _visibility,
        allowedUserIds: _selectedFriendIds.isNotEmpty ? _selectedFriendIds : null,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.shouldUpdateAvatarOnSubmit
                  ? 'Đổi avatar và đăng bài thành công!'
                  : 'Đăng bài thành công!',
            ),
            backgroundColor: AppColors.primaryBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: ${provider.errorMessage ?? 'Không thể đăng bài'}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Divider(height: 1, color: Colors.grey.shade200),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserRow(),
                  if (widget.shouldUpdateAvatarOnSubmit)
                    _buildAvatarUpdateHint(),
                  _buildVisibilityRow(),
                  _buildContentArea(),
                  if (_selectedImages.isNotEmpty) _buildImagePreview(),
                  _buildPhotoButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = widget.shouldUpdateAvatarOnSubmit
        ? 'Tạo bài viết & cập nhật avatar'
        : 'Tạo bài viết';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Color(0xFF65676B), size: 22),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : const Text(
                    'Đăng',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarUpdateHint() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD89A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Color(0xFFD48806),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ảnh này sẽ được đặt làm avatar khi bạn bấm Đăng. Nếu bạn đóng màn hình này, avatar sẽ không thay đổi.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF8C5A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _avatarColor,
            ),
            child: Center(
              child: widget.currentUserAvatar.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.currentUserAvatar,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          _userInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      _userInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.currentUserName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              GestureDetector(
                onTap: _showVisibilitySheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getVisibilityIcon(),
                        size: 12,
                        color: const Color(0xFF65676B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getVisibilityText(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF65676B),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: Color(0xFF65676B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityRow() {
    if (_visibility != 'selected_friends' || _selectedFriendIds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Consumer<FriendProvider>(
        builder: (context, provider, _) {
          final selected = provider.friends
              .where((f) => _selectedFriendIds.contains(f.friendId))
              .toList();
          if (selected.isEmpty) return const SizedBox.shrink();
          return SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selected.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final friend = selected[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4CAF50),
                        ),
                        child: Center(
                          child: Text(
                            friend.fullName.isNotEmpty
                                ? friend.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        friend.fullName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _contentController,
        maxLines: 8,
        minLines: 4,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Bạn đang nghĩ gì?',
          hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 15),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1A1A1A),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          if (_selectedImages.length == 1)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _selectedImages.first.bytes,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _removeImage(0),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              height: 110,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImages[index].bytes,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 110,
                            height: 110,
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickImages,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chọn ảnh từ thiết bị',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
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

  IconData _getVisibilityIcon() {
    switch (_visibility) {
      case 'public':
        return Icons.public;
      case 'friends':
        return Icons.group;
      case 'selected_friends':
        return Icons.group_add;
      case 'only_me':
        return Icons.lock_outline;
      default:
        return Icons.public;
    }
  }

  String _getVisibilityText() {
    switch (_visibility) {
      case 'public':
        return 'Công khai';
      case 'friends':
        return 'Bạn bè';
      case 'selected_friends':
        return 'Bạn bè từ Zalo';
      case 'only_me':
        return 'Chỉ mình tôi';
      default:
        return 'Công khai';
    }
  }
}

class _VisibilitySheet extends StatefulWidget {
  final String currentVisibility;
  final List<String> selectedFriendIds;
  final Function(String, List<String>) onVisibilityChanged;

  const _VisibilitySheet({
    required this.currentVisibility,
    required this.selectedFriendIds,
    required this.onVisibilityChanged,
  });

  @override
  State<_VisibilitySheet> createState() => _VisibilitySheetState();
}

class _VisibilitySheetState extends State<_VisibilitySheet> {
  late String _visibility;
  late List<String> _selectedFriendIds;

  @override
  void initState() {
    super.initState();
    _visibility = widget.currentVisibility;
    _selectedFriendIds = List.from(widget.selectedFriendIds);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Mọi người có thể nhìn thấy bài viết',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          _buildOption(
            icon: Icons.public,
            title: 'Công khai',
            subtitle: 'Mọi người đều có thể nhìn thấy',
            value: 'public',
          ),
          _buildOption(
            icon: Icons.group,
            title: 'Bạn bè',
            subtitle: 'Chỉ bạn bè có thể nhìn thấy',
            value: 'friends',
          ),
          _buildOption(
            icon: Icons.group_add,
            title: 'Bạn bè từ Zalo',
            subtitle: 'Chỉ những bạn bè được chọn mới thấy',
            value: 'selected_friends',
          ),
          _buildOption(
            icon: Icons.lock_outline,
            title: 'Chỉ mình tôi',
            subtitle: 'Chỉ mình tôi thấy bài viết này',
            value: 'only_me',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _visibility == value;

    return InkWell(
      onTap: () {
        setState(() => _visibility = value);
        widget.onVisibilityChanged(_visibility, _selectedFriendIds);
        if (value == 'selected_friends') {
          Navigator.pop(context);
          _showFriendSelectorSheet(context);
        } else {
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected
            ? AppColors.primaryBlue.withValues(alpha: 0.06)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.primaryBlue
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF65676B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.primaryBlue, size: 20),
          ],
        ),
      ),
    );
  }

  void _showFriendSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) {
          return _FriendSelectorSheet(
            selectedFriendIds: _selectedFriendIds,
            onSelectionChanged: (ids) {
              setState(() => _selectedFriendIds = ids);
              widget.onVisibilityChanged(_visibility, _selectedFriendIds);
            },
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class _FriendSelectorSheet extends StatelessWidget {
  final List<String> selectedFriendIds;
  final Function(List<String>) onSelectionChanged;
  final ScrollController scrollController;

  const _FriendSelectorSheet({
    required this.selectedFriendIds,
    required this.onSelectionChanged,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chọn bạn bè có thể nhìn thấy bài viết',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Xong',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Consumer<FriendProvider>(
              builder: (context, provider, _) {
                final friends = provider.friends;

                if (friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có bạn bè',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final isSelected = selectedFriendIds.contains(
                      friend.friendId,
                    );
                    final color = _avatarColor(friend.fullName);

                    return InkWell(
                      onTap: () {
                        final newList = List<String>.from(selectedFriendIds);
                        if (isSelected) {
                          newList.remove(friend.friendId);
                        } else {
                          newList.add(friend.friendId);
                        }
                        onSelectionChanged(newList);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: friend.avatar.isNotEmpty
                                    ? Image.network(
                                        friend.avatar,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            friend.fullName.isNotEmpty
                                                ? friend.fullName[0]
                                                      .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          friend.fullName.isNotEmpty
                                              ? friend.fullName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend.fullName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  if (friend.friendId.isNotEmpty)
                                    Text(
                                      friend.friendId,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF65676B),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : Colors.grey.shade300,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
