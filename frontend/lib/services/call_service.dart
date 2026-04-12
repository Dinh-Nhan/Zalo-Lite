import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CallService {
  CameraController? cameraController;

  // Kiểm tra và xin quyền
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    return statuses[Permission.camera]!.isGranted && statuses[Permission.microphone]!.isGranted;
  }

  // Khởi tạo camera cho Video Call
  Future<CameraController?> initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;
    
    cameraController = CameraController(
      cameras[1], // Camera trước
      ResolutionPreset.high,
      enableAudio: true,
    );
    await cameraController!.initialize();
    return cameraController;
  }

  void dispose() {
    cameraController?.dispose();
  }
}