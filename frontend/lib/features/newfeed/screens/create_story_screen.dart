import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config/app_colors.dart';
import '../providers/story_provider.dart';

class _CapturedImage {
  final XFile file;
  final Uint8List bytes;

  _CapturedImage({required this.file, required this.bytes});
}

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isFrontCamera = true;
  bool _isTakingPicture = false;
  _CapturedImage? _capturedImage;
  final ImagePicker _imagePicker = ImagePicker();
  String? _errorMessage;
  bool _hasPermission = true;
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isDisposed) return;

    try {
      final cameras = await availableCameras();
      if (_isDisposed) return;

      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _hasPermission = false;
            _errorMessage = 'Không tìm thấy camera trên thiết bị';
          });
        }
        return;
      }

      _cameras = cameras;

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _selectedCameraIndex = _isFrontCamera
          ? cameras.indexOf(frontCamera)
          : cameras.indexOf(backCamera);

      await _setupCamera(cameras[_selectedCameraIndex]);
    } on CameraException catch (e) {
      if (_isDisposed) return;
      if (mounted) {
        setState(() {
          _hasPermission = false;
          if (e.code == 'CameraAccessDenied') {
            _errorMessage = 'Vui lòng cho phép truy cập camera';
          } else {
            _errorMessage = 'Không thể khởi tạo camera: ${e.description}';
          }
        });
      }
    } catch (e) {
      if (_isDisposed) return;
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _errorMessage = 'Lỗi camera: $e';
        });
      }
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    if (_isDisposed) return;

    _cameraController?.dispose();

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (_isDisposed) return;
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } on CameraException catch (e) {
      if (_isDisposed) return;
      if (mounted) {
        setState(() {
          _hasPermission = false;
          if (e.code == 'CameraAccessDenied') {
            _errorMessage = 'Vui lòng cho phép truy cập camera';
          } else {
            _errorMessage = 'Không thể khởi tạo camera';
          }
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_isDisposed || _cameras.length < 2) return;

    if (mounted) {
      setState(() {
        _isFrontCamera = !_isFrontCamera;
        _isCameraInitialized = false;
      });
    }

    final targetDirection = _isFrontCamera
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    final targetCamera = _cameras.firstWhere(
      (c) => c.lensDirection == targetDirection,
      orElse: () => _cameras.first,
    );

    _selectedCameraIndex = _cameras.indexOf(targetCamera);
    await _setupCamera(targetCamera);
  }

  Future<void> _takePicture() async {
    if (_isDisposed ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    if (!mounted) return;
    setState(() => _isTakingPicture = true);

    try {
      final XFile photo = await _cameraController!.takePicture();
      final bytes = await photo.readAsBytes();
      if (_isDisposed) return;
      if (mounted) {
        setState(() {
          _capturedImage = _CapturedImage(file: photo, bytes: bytes);
          _isTakingPicture = false;
        });
      }
    } catch (e) {
      if (_isDisposed) return;
      if (mounted) {
        setState(() => _isTakingPicture = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chụp ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isDisposed) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && !_isDisposed) {
        final bytes = await image.readAsBytes();
        if (_isDisposed) return;
        if (mounted) {
          setState(() {
            _capturedImage = _CapturedImage(file: image, bytes: bytes);
          });
        }
      }
    } catch (e) {
      if (_isDisposed) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retake() {
    if (_isDisposed && mounted) return;
    setState(() {
      _capturedImage = null;
    });
  }

  Future<void> _postStory() async {
    if (_isDisposed || _capturedImage == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    final provider = context.read<StoryProvider>();
    final result = await provider.createStory(_capturedImage!.file);

    if (_isDisposed) return;

    if (mounted) {
      setState(() => _isLoading = false);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng tin thành công!'),
            backgroundColor: AppColors.primaryBlue,
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${provider.errorMessage ?? 'Không thể đăng tin'}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraOrPreview(),
          _buildTopControls(),
          if (_capturedImage == null) _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraOrPreview() {
    if (_capturedImage != null) {
      return Image.memory(
        _capturedImage!.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF2C2C2C),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return _buildErrorView();
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              'Đang khởi tạo camera...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Transform.scale(
      scale: _isFrontCamera ? 1.0 : 1.0,
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white70,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Không thể truy cập camera',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library, color: Colors.white),
              label: const Text(
                'Chọn ảnh từ thư viện',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _controlButton(
                Icons.close,
                () {
                  if (!_isDisposed) context.pop();
                },
                size: 44,
              ),
              if (_capturedImage != null)
                Row(
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    _controlButton(
                      Icons.check,
                      _postStory,
                      bgColor: AppColors.primaryBlue,
                      iconColor: Colors.white,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(bottom: 32, top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: _controlButton(
                  Icons.photo_library,
                  _pickFromGallery,
                  bgColor: Colors.white.withValues(alpha: 0.15),
                  iconColor: Colors.white,
                ),
              ),
              _captureButton(),
              SizedBox(
                width: 52,
                height: 52,
                child: _controlButton(
                  Icons.flip_camera_ios,
                  _cameras.length > 1 ? _switchCamera : () {},
                  bgColor: Colors.white.withValues(alpha: 0.15),
                  iconColor: _cameras.length > 1 ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _captureButton() {
    final isCapturing = _isTakingPicture;
    return GestureDetector(
      onTap: isCapturing ? null : _takePicture,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCapturing ? Colors.grey : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _controlButton(
    IconData icon,
    VoidCallback onTap, {
    double size = 44,
    Color bgColor = Colors.white,
    Color iconColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.5,
        ),
      ),
    );
  }
}
