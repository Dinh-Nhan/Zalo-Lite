import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/services/friend_service.dart';
import 'package:frontend/features/friends/widgets/demo_bio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrFriendScreen extends StatefulWidget {
  const QrFriendScreen({super.key});

  @override
  State<QrFriendScreen> createState() => _QrFriendScreenState();
}

class _QrFriendScreenState extends State<QrFriendScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isScanTab = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1) {
          _requestCameraAndShowScanner();
        } else {
          setState(() => _isScanTab = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraAndShowScanner() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _isScanTab = true);
    } else if (status.isPermanentlyDenied) {
      _showSnack('Vui lòng cấp quyền camera trong Cài đặt');
      openAppSettings();
    } else {
      _showSnack('Cần quyền camera để quét mã QR');
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (code == myUid) {
      _showSnack('Đây là mã QR của bạn');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = await FriendService.getUserById(code);
      if (!mounted) return;
      // Ẩn scanner trước khi push để tránh camera conflict
      setState(() => _isScanTab = false);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
      );
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isScanTab = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Không tìm thấy người dùng');
      setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Mã QR kết bạn'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Mã của tôi'),
            Tab(text: 'Quét mã'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyQr(myUid),
          _buildScanner(),
        ],
      ),
    );
  }

  Widget _buildMyQr(String uid) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: uid,
              version: QrVersions.auto,
              size: 220,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0068FF),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cho bạn bè quét mã này để kết bạn',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Chỉ build MobileScanner khi đang ở tab scan
        if (_isScanTab)
          MobileScanner(onDetect: _onDetect)
        else
          const ColoredBox(color: Colors.black),

        // Khung ngắm
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryBlue, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        if (_isProcessing)
          const Center(child: CircularProgressIndicator(color: Colors.white)),

        const Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Text(
            'Đưa mã QR vào khung để quét',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
