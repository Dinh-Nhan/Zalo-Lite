import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5244';
}
