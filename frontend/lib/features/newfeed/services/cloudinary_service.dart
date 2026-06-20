import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'dzfmyyopy';
  static const String _uploadPreset = 'zalo_lite_unsigned';

  static Future<String> uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name;

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
        'upload_preset': _uploadPreset,
      });

      final response = await Dio().post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      }

      throw Exception('Upload failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<List<String>> uploadImages(List<XFile> imageFiles) async {
    final urls = <String>[];
    for (final file in imageFiles) {
      final url = await uploadImage(file);
      urls.add(url);
    }
    return urls;
  }
}
