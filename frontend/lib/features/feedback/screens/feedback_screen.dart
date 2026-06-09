import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/feedback/services/feedback_service.dart';
class FeedbackFlowModal extends StatefulWidget {
  const FeedbackFlowModal({super.key});

  @override
  State<FeedbackFlowModal> createState() => _FeedbackFlowModalState();
}

class _FeedbackFlowModalState extends State<FeedbackFlowModal> {
  int _currentStep = 0; // 0: Chọn sao nhanh, 1: Form chi tiết, 2: Thành công
  int _selectedRating = 0;
  Timer? _autoCloseTimer;
  bool _isSubmitting = false;
  String? _titleError;
  String? _descriptionError;
  String? _ratingError;
  // Controllers cho Form ở Bước 1
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startAutoCloseTimer();
  }
  
  Future<void> _submitFeedback() async {
    try {
      setState(() {
      _titleError = null;
      _descriptionError = null;
      _ratingError = null;
    });

    bool hasError = false;

    if (_selectedRating == 0) {
      _ratingError = "Vui lòng chọn số sao đánh giá";
      hasError = true;
    }

    if (_titleController.text.trim().isEmpty) {
      _titleError = "Vui lòng nhập tiêu đề";
      hasError = true;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _descriptionError = "Vui lòng nhập nội dung";
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("Người dùng chưa đăng nhập");
    }

    setState(() {
      _isSubmitting = true;
    });

    await FeedbackService.createFeedback(
      userId: user.uid,
      userDisplayName: user.displayName ?? "Người dùng",
      userAvatar: user.photoURL ?? "",
      subject: _titleController.text.trim(),
      message: _descriptionController.text.trim(),
      rating: _selectedRating,
    );

    if (!mounted) return;

    setState(() {
      _currentStep = 2;
    });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Gửi feedback thất bại: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  void _startAutoCloseTimer() {
    _autoCloseTimer?.cancel();
    // Chỉ tự động đóng sau 2 phút nếu đang ở Bước 0 (chưa tương tác sâu)
    if (_currentStep == 0) {
      _autoCloseTimer = Timer(const Duration(minutes: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  void _resetTimerOnInteraction() {
    if (_currentStep == 0) {
      _startAutoCloseTimer();
    } else {
      _autoCloseTimer?.cancel(); 
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const zaloBlue = Color(0xFF006AF5);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildCurrentStepLayout(zaloBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepLayout(Color zaloBlue) {
    switch (_currentStep) {
      case 0:
        return _buildStep0Initial(zaloBlue);
      case 1:
        return _buildStep1Form(zaloBlue);
      case 2:
        return _buildStep2Success(zaloBlue);
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // BƯỚC 0: HIỂN THỊ CHỌN SAO BAN ĐẦU
  // ==========================================
  Widget _buildStep0Initial(Color zaloBlue) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(color: Color(0xFFE8F2FF), shape: BoxShape.circle),
          child: const Center(
            child: Icon(Icons.star_rounded, color: AppColors.primaryBlue, size: 44),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Đánh giá phản hồi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ý kiến của bạn giúp chúng tôi cải thiện\ndịch vụ tốt hơn.',
          style: TextStyle(fontSize: 14, color: Color(0xFF7A7A7A), height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildRatingStars(),
        if (_ratingError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                _ratingError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 1; // Chuyển sang màn hình điền Form
                _resetTimerOnInteraction();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: zaloBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: const Text('Đánh giá ngay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Text('Bỏ qua', style: TextStyle(color: AppColors.primaryBlue, fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  // ==========================================
  // BƯỚC 1: FORM CHI TIẾT (Hình 1)
  // ==========================================
  Widget _buildStep1Form(Color zaloBlue) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text(
              'Đánh giá phản hồi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onPressed: () {},
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),
        
        // Icon Bong bóng Chat
        Center(
          child: Container(
            width: 70, height: 70,
            decoration: const BoxDecoration(color: Color(0xFFE8F2FF), shape: BoxShape.circle),
            child: const Center(
              child: Icon(Icons.chat_bubble_rounded, color: AppColors.primaryBlue, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text('Bạn cảm thấy dịch vụ như thế nào?', style: TextStyle(fontSize: 14, color: Color(0xFF5A5A5A))),
        ),
        const SizedBox(height: 12),
        _buildRatingStars(),
        const SizedBox(height: 24),

        // Trường: Tiêu đề đánh giá
        const Text('Tiêu đề đánh giá', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          onChanged: (_) {
            if (_titleError != null) {
              setState(() {
                _titleError = null;
              });
            }
          },
          decoration: InputDecoration(
            hintText: 'Nhập tiêu đề (ví dụ: Phản hồi rất tốt)',
            errorText: _titleError,
            hintStyle: const TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 14,
            ),
            fillColor: const Color(0xFFF4F5F7),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Trường: Mô tả chi tiết
        const Text('Mô tả chi tiết', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          onChanged: (_) {
            if (_descriptionError != null) {
              setState(() {
                _descriptionError = null;
              });
            }
          },
          decoration: InputDecoration(
            hintText: 'Chia sẻ thêm trải nghiệm của bạn về dịch vụ...',
            errorText: _descriptionError,
            hintStyle: const TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 14,
            ),
            fillColor: const Color(0xFFF4F5F7),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        
        const SizedBox(height: 24),

        // Nút Gửi Đánh Giá
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : _submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: zaloBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Gửi đánh giá',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BƯỚC 2: THÀNH CÔNG (Hình 2)
  // ==========================================
  Widget _buildStep2Success(Color zaloBlue) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const Text(
          'Feedback Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 32),

        // Icon tích xanh dạng gợn sóng đồng tâm
        Container(
          width: 120, height: 120,
          decoration: const BoxDecoration(color: Color(0xFFE8F8F0), shape: BoxShape.circle),
          child: Center(
            child: Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(color: Color(0xFFC2EED7), shape: BoxShape.circle),
              child: Center(
                child: Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(color: Color(0xFF008744), shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Gửi đánh giá thành công',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cảm ơn bạn đã đóng góp ý kiến để ZaloLite\nngày càng hoàn thiện hơn.',
          style: TextStyle(fontSize: 13, color: Color(0xFF7A7A7A), height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Card "Người đóng góp tích cực"
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF4F5F7), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE8F2FF), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.volunteer_activism, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Người đóng góp tích cực', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    SizedBox(height: 2),
                    Text('Đánh giá của bạn đã được ghi nhận vào hệ thống.', style: TextStyle(fontSize: 11, color: Color(0xFF7A7A7A))),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Nút Hoàn tất
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: zaloBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Hoàn tất', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // Widget dùng chung để tạo cụm 5 ngôi sao
  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = index + 1;
              _resetTimerOnInteraction();
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              Icons.star_rounded,
              size: 38,
              color: index < _selectedRating ? const Color(0xFFFFC107) : const Color(0xFFD0D4DC),
            ),
          ),
        );
      }),
    );
  }
}