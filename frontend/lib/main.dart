import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/apps/app_locale.dart';
import 'package:frontend/apps/router.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/newfeed/providers/feed_provider.dart';
import 'package:frontend/features/newfeed/providers/story_provider.dart';
import 'package:frontend/features/profile/providers/profile_provider.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'services/call_notification_service.dart';
import 'services/message_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.data['type'] == 'incoming_call') {
    await CallNotificationService.showIncomingCall(message.data);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final imagePickerPlatform = ImagePickerPlatform.instance;
  if (imagePickerPlatform is ImagePickerAndroid) {
    imagePickerPlatform.useAndroidPhotoPicker = true;
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  await CallNotificationService.initialize();
  await MessageNotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

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
        );
      },
    );
  }
}
