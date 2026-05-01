import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5244';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5244';
    }

    if (Platform.isIOS) {
      return 'http://localhost:5244';
    }

    // fallback (desktop, etc)
    return 'http://localhost:5244';
  }
}
