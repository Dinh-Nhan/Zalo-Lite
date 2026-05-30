import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/apps/router.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';

/// Điểm khởi chạy ứng dụng Zalo Lite
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Widget gốc của ứng dụng
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createRouter();
    return ValueListenableBuilder(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp.router(
          title: 'Zalo Lite',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: router,
          locale: Locale(locale),
          // Hiển thị LoadView (splash) đầu tiên
          // LoadView sẽ tự động chuyển sang HomeView sau 3 giây
          // home: const LoadView(),
        );
      },
    );
  }
}
