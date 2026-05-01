import 'package:frontend/views/auth/login_view.dart';
import 'package:frontend/views/auth/otp_verify_view.dart';
import 'package:frontend/views/auth/register_view.dart';
import 'package:frontend/views/call/call_receiver_view.dart';
import 'package:frontend/views/call/call_view.dart';
import 'package:frontend/views/chat/chat_list_view.dart';
import 'package:go_router/go_router.dart';

import '../views/home/home_view.dart';
import '../views/home/load_view.dart';

/// Cấu hình router cho ứng dụng Zalo Lite
/// Cấu trúc: home/ (load, welcome) → auth/ (login, otp, register)
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/', // Mặc định vào thẳng chat list sau khi load
    routes: [
      // === HOME ===
      GoRoute(path: '/load', builder: (context, state) => const LoadView()),
      GoRoute(path: '/', builder: (context, state) => const HomeView()),

      // === AUTH ===
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerifyView(phone: phone);
        },
      ),

      // === CHAT ===
      GoRoute(
        path: '/chat-list',
        builder: (context, state) => const ChatListView(),
      ),

      // === CALL ===
      GoRoute(path: '/call', builder: (context, state) => CallView()),
      GoRoute(
        path: '/call-receiver',
        builder: (context, state) => const CallReceiverView(),
      ),

      // TODO: [Backend] Thêm route chat chi tiết khi có ChatDetailView
      // GoRoute(
      //   path: '/chat/:conversationId',
      //   builder: (context, state) {
      //     final conversationId = state.pathParameters['conversationId']!;
      //     return ChatDetailView(conversationId: conversationId);
      //   },
      // ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      // TODO: [Backend] Thêm route quên mật khẩu
      // GoRoute(
      //   path: '/forgot-password',
      //   builder: (context, state) => const ForgotPasswordView(),
      // ),
    ],
  );
}
