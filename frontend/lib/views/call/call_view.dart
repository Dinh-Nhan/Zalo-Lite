import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:frontend/component/ripple_aminimation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/call_model.dart';
import '../../config/app_colors.dart';
import '../../providers/call_provider.dart';
import '../../services/call_service.dart';

class CallView extends StatefulWidget {
  const CallView({super.key});

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  final CallService _callService = CallService();
  bool _isCamReady = false;

  @override
  void initState() {
    super.initState();
    // Sử dụng addPostFrameCallback để đảm bảo context đã sẵn sàng hoàn toàn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareCall();
    });
  }

  Future<void> _prepareCall() async {
    // 1. Kiểm tra quyền Camera & Mic
    bool hasPermission = await _callService.requestPermissions();
    if (hasPermission) {
      final prov = context.read<CallProvider>();
      // 2. Nếu là cuộc gọi Video, tiến hành khởi tạo Camera
      if (prov.currentCall?.isVideo == true) {
        try {
          await _callService.initCamera();
          if (mounted) setState(() => _isCamReady = true);
        } catch (e) {
          debugPrint("Lỗi khởi tạo Camera: $e");
        }
      }
    }
  }

  @override
  void dispose() {
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callProv = context.watch<CallProvider>();
    final call = callProv.currentCall;

    // Nếu cuộc gọi đã kết thúc (do timeout hoặc bấm nút), quay về màn hình trước
    if (call == null || call.status == CallStatus.ended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zalo"),
        centerTitle: true,
        backgroundColor: Color.from(alpha: 1, red: 0, green: 0.518, blue: 1),
        leading: Center(
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_left, color: Color.fromARGB(187, 255, 255, 255), size: 28),
              onPressed: () => context.pop(),
              style: IconButton.styleFrom(
                backgroundColor: const Color.fromARGB(121, 102, 102, 102),
                padding: EdgeInsets.zero,
                fixedSize: const Size(40, 40),
                minimumSize: const Size(32, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.videocam_outlined, color: Color.fromARGB(187, 255, 255, 255), size: 28),
              onPressed: () => context.pop(),
              style: IconButton.styleFrom(
                backgroundColor: const Color.fromARGB(121, 102, 102, 102),
                padding: EdgeInsets.zero,
                fixedSize: const Size(40, 40),
                minimumSize: const Size(32, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            ),
          SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(callProv),
          SafeArea(
            child: Column(
              children: [
                // _buildHeader(context),
                // const SizedBox(height: 40),

                // CHỈ HIỆN SÓNG KHI ĐANG ĐỔ CHUÔNG (dialing)
               SizedBox(
                  width: 150,
                  height: 150,
                  child: Center( // Đảm bảo Avatar luôn nằm giữa vùng chứa 150x150
                    child: call.status == CallStatus.dialing
                        ? RippleAnimation(child: _buildAvatar(call)) // Hiện sóng
                        : _buildAvatar(call), // Chỉ hiện Avatar (nhưng vẫn nằm trong khung 150x150)
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  call.remoteName,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600),
                ),
                
                const SizedBox(height: 8),
                // THÔNG TIN TRẠNG THÁI
                 _buildStatusOrTimer(callProv, call),

                const Spacer(),
                _buildActionButtons(callProv),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   final callProv = context.watch<CallProvider>();
  //   final call = callProv.currentCall;

  //   if (call == null) return const Scaffold(backgroundColor: Colors.black);

  //   return Scaffold(
  //     body: Stack(
  //       children: [
  //         _buildBackground(callProv),
  //         SafeArea(
  //           child: Column(
  //             children: [
  //               _buildHeader(context),
  //               const SizedBox(height: 20),

  //               // 2. AVATAR VÀ SÓNG (Cố định vị trí)
  //               SizedBox(
  //                 height: 150,
  //                 child: Center(
  //                   child: call.status == CallStatus.dialing
  //                       ? RippleAnimation(child: _buildAvatar(call))
  //                       : _buildAvatar(call),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),

  //               // 1. TÊN NGƯỜI GỌI Ở TRÊN
  //               Text(
  //                 call.remoteName,
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 28,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               const SizedBox(height: 8),

  //               // 3. TEXT TRẠNG THÁI HOẶC THỜI GIAN
  //               _buildStatusOrTimer(callProv, call),

  //               const Spacer(),
  //               _buildActionButtons(callProv),
  //               // const SizedBox(height: 50),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

Widget _buildStatusOrTimer(CallProvider prov, CallModel call) {
  // Nếu đã bắt máy -> Hiển thị thời gian
  if (call.status == CallStatus.active) {
    return Text(
      prov.formattedDuration,
      style: const TextStyle(color: Colors.white, fontSize: 20),
    );
  }

  // Logic hiển thị text theo từng trường hợp
  String displaySubtitle = "";
  if (call.status == CallStatus.dialing) {
    displaySubtitle = "Đang đổ chuông...";
  } else if (prov.statusText.isNotEmpty) {
    // statusText lấy từ Provider (ví dụ: "Người nhận hiện đang bận")
    displaySubtitle = prov.statusText; 
  }

  return Text(
    displaySubtitle,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 16,
      letterSpacing: 1.2,
    ),
  );
}
  // Widget cho các nút ở phía trên
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white, size: 24),
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: const Color.fromARGB(121, 102, 102, 102),
              padding: const EdgeInsets.all(8),
              // Để nút nhỏ lại, bạn cần chỉnh cả 2 thông số này
              minimumSize: const Size(32, 32), 
              tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Loại bỏ khoảng trống thừa xung quanh
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
                onPressed: () {}, // Thêm người vào cuộc gọi
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          )
        ],
      ),
    );
  }

  // Widget Avatar tách riêng để tái sử dụng
  Widget _buildAvatar(CallModel call) {
    return CircleAvatar(
      radius: 55,
      backgroundColor: Colors.white24,
      backgroundImage: call.remoteAvatar.isNotEmpty ? NetworkImage(call.remoteAvatar) : null,
      child: call.remoteAvatar.isEmpty 
        ? Text(call.remoteName[0], style: const TextStyle(fontSize: 40, color: Colors.white)) 
        : null,
    );
  }
  Widget _buildBackground(CallProvider prov) {
    // Ưu tiên hiển thị Camera nếu là Video Call và Camera đã sẵn sàng
    if (prov.currentCall?.isVideo == true && _isCamReady && _callService.cameraController != null) {
      return SizedBox.expand(
        child: CameraPreview(_callService.cameraController!),
      );
    }
    
    // Nếu không phải Video Call hoặc Camera chưa sẵn sàng, hiện màu xanh Zalo
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.from(alpha: 1, red: 0, green: 0.518, blue: 1), Color(0xFF0056B3)],
        ),
      ),
    );
  }

  Widget _buildActionButtons(CallProvider prov) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconBtn(
          prov.isSpeakerOn ? Icons.volume_up : Icons.volume_off, 
          "Loa", 
          prov.toggleSpeaker, 
          prov.isSpeakerOn
        ),
        _iconBtn(
          Icons.call_end, 
          "Kết thúc", 
          () {
            prov.endCall();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/chat-list');
            }
          }, 
          false, 
          color: AppColors.callRed
        ),
        _iconBtn(
          prov.isMuted ? Icons.mic_off : Icons.mic, 
          "Mic", 
          prov.toggleMute, 
          !prov.isMuted
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, String label, VoidCallback onTap, bool isActive, {Color? color}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 35,
            backgroundColor: isActive ? Colors.white : (color ?? Colors.white24),
            child: Icon(
              icon, 
              color: isActive && color == null ? const Color(0xFF0084FF) : Colors.white, 
              size: 30
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}