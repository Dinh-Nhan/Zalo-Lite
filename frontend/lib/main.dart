import 'package:flutter/material.dart';
import 'views/home/load_view.dart';
import 'config/app_theme.dart';

/// Điểm khởi chạy ứng dụng Zalo Lite
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Widget gốc của ứng dụng
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zalo Lite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Hiển thị LoadView (splash) đầu tiên
      // LoadView sẽ tự động chuyển sang HomeView sau 3 giây
      home: const LoadView(),
    );
  }
}
