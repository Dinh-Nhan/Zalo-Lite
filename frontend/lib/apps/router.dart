import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/views/auth/enter_name_view.dart';
import 'package:frontend/views/auth/login_view.dart';
import 'package:frontend/views/auth/otp_verify_view.dart';
import 'package:frontend/views/auth/personal_info_view.dart';
import 'package:frontend/views/auth/register_view.dart';
import 'package:frontend/views/auth/reset_password_view.dart';
import 'package:frontend/views/auth/sign_up_view.dart';
import 'package:frontend/views/auth/update_avatar.dart';
import 'package:frontend/views/call/call_receiver_view.dart';
import 'package:frontend/views/call/call_view.dart';
import 'package:frontend/views/chat/chat_list_view.dart';
import 'package:go_router/go_router.dart';

import '../views/home/home_view.dart';
import '../views/home/load_view.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

/// Cấu hình router cho ứng dụng Zalo Lite
/// Cấu trúc: home/ (load, welcome) → auth/ (login, otp, register)
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/load', // Mặc định vào thẳng chat list sau khi load
    refreshListenable: RouterNotifier(),
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final isOnLoad = state.matchedLocation == '/load';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/sign-up' ||
          state.matchedLocation == '/';

      if (isOnLoad) return null;
      if (!isLoggedIn && !isAuthRoute) return '/';
      if (isLoggedIn && isAuthRoute) return '/chat-list';
      return null;
    },
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
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpView(),
      ),
      GoRoute(
        path: '/enter-name',
        builder: (context, state) =>
            const EnterNameView(email: '', password: ''),
      ),
      GoRoute(
        path: '/personal-info',
        builder: (context, state) => const PersonalInfoView(),
      ),
      GoRoute(
        path: '/update-avatar',
        builder: (context, state) => const UpdateAvatarView(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordView(),
      ),
    ],
  );
}
