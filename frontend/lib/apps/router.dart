// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:frontend/views/auth/enter_name_view.dart';
// import 'package:frontend/views/auth/login_view.dart';
// import 'package:frontend/views/auth/otp_verify_view.dart';
// import 'package:frontend/views/auth/personal_info_view.dart';
// import 'package:frontend/views/auth/register_view.dart';
// import 'package:frontend/views/auth/set_password_view.dart';
// import 'package:frontend/views/auth/sign_up_view.dart';
// import 'package:frontend/views/auth/update_avatar.dart';
// import 'package:frontend/views/call/call_receiver_view.dart';
// import 'package:frontend/views/call/call_view.dart';
// import 'package:frontend/views/chat/chat_list_view.dart';
// import 'package:go_router/go_router.dart';

// import '../views/home/home_view.dart';
// import '../views/home/load_view.dart';

// class RouterNotifier extends ChangeNotifier {
//   // bool isReady = false;
//   RouterNotifier() {
//     FirebaseAuth.instance.authStateChanges().listen((_) {
//       // isReady = true;
//       notifyListeners();
//     });
//   }
// }

// /// Cấu hình router cho ứng dụng Zalo Lite
// /// Cấu trúc: home/ (load, welcome) → auth/ (login, otp, register)
// GoRouter createRouter() {
//   return GoRouter(
//     initialLocation: '/load', 
//     refreshListenable: RouterNotifier(),
//     redirect: (context, state) {
//       final user = FirebaseAuth.instance.currentUser;
//       final isLoggedIn = user != null;
//       final isOnLoad = state.matchedLocation == '/load';
//       final isSetupRoute = 
//         state.matchedLocation == '/otp' ||
//         state.matchedLocation == '/enter-name' ||
//         state.matchedLocation == '/reset-password' ||
//         state.matchedLocation == '/personal-info' ||
//         state.matchedLocation == '/update-avatar';
//       final isAuthRoute =
//           state.matchedLocation == '/login' ||
//           state.matchedLocation == '/sign-up' ;//||
//           // state.matchedLocation == '/';

//       if (isOnLoad) return null;
//       if (!isLoggedIn && !isAuthRoute && !isSetupRoute) return '/';
//       if (isLoggedIn && isAuthRoute) return '/chat-list';
//       return null;
//     },
//     routes: [
//       // === HOME ===
//       GoRoute(path: '/load', builder: (context, state) => const LoadView()),
//       GoRoute(path: '/', builder: (context, state) => const HomeView()),

//       // === AUTH ===
//       GoRoute(path: '/login', builder: (context, state) => const LoginView()),
//       GoRoute(
//         path: '/otp',
//         builder: (context, state) {
//           final email = state.extra as String? ?? '';
//           return OtpVerifyView(email: email);
//         },
//       ),

//       // === CHAT ===
//       GoRoute(
//         path: '/chat-list',
//         builder: (context, state) => const ChatListView(),
//       ),

//       // === CALL ===
//       GoRoute(path: '/call', builder: (context, state) => CallView()),
//       GoRoute(
//         path: '/call-receiver',
//         builder: (context, state) => const CallReceiverView(),
//       ),

//       // TODO: [Backend] Thêm route chat chi tiết khi có ChatDetailView
//       // GoRoute(
//       //   path: '/chat/:conversationId',
//       //   builder: (context, state) {
//       //     final conversationId = state.pathParameters['conversationId']!;
//       //     return ChatDetailView(conversationId: conversationId);
//       //   },
//       // ),
//       GoRoute(
//         path: '/register',
//         builder: (context, state) => const RegisterView(),
//       ),
//       // TODO: [Backend] Thêm route quên mật khẩu
//       // GoRoute(
//       //   path: '/forgot-password',
//       //   builder: (context, state) => const ForgotPasswordView(),
//       // ),
//       GoRoute(
//         path: '/sign-up',
//         builder: (context, state) => const SignUpView(),
//       ),
//       GoRoute(
//         path: '/enter-name',
//         builder: (context, state) {
//           final email = (state.extra as Map<String, dynamic>?)?['email'] as String?;
//           final password = (state.extra as Map<String, dynamic>?)?['password'] as String?;
//           final name = (state.extra as Map<String, dynamic>?)?['name'] as String?;
//           return EnterNameView(
//             email: email ?? '',
//             password: password ?? '',
//             name: name ?? '',
//           );
//         },
//       ),
//       GoRoute(
//         path: '/personal-info',
//         builder: (context, state) {
//           final email = (state.extra as Map<String, dynamic>?)?['email'] as String?;
//           final password = (state.extra as Map<String, dynamic>?)?['password'] as String?;
//           final name = (state.extra as Map<String, dynamic>?)?['name'] as String?;
//           return PersonalInfoView(
//             email: email ?? '',
//             password: password ?? '',
//             name: name ?? '',
//           );
//         }
//       ),
//       GoRoute(
//         path: '/update-avatar',
//         builder: (context, state) => const UpdateAvatarView(),
//       ),
//       GoRoute(
//         path: '/reset-password',
//         builder: (context, state) {
//           final email = state.extra as String?;
//           return ResetPasswordView(
//             email: email
//           );
//         },
//       ),
//     ],
//   );
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/views/auth/set_password_view.dart';
import 'package:go_router/go_router.dart';

// Views
import 'package:frontend/views/home/load_view.dart';
import 'package:frontend/views/home/home_view.dart';
import 'package:frontend/views/auth/login_view.dart';
import 'package:frontend/views/auth/sign_up_view.dart';
import 'package:frontend/views/auth/otp_verify_view.dart';
import 'package:frontend/views/auth/enter_name_view.dart';
import 'package:frontend/views/auth/personal_info_view.dart';
import 'package:frontend/views/auth/update_avatar.dart';
import 'package:frontend/views/chat/chat_list_view.dart';

/// 🔥 FIX: dùng stream thay vì currentUser
class RouterNotifier extends ChangeNotifier {
  User? user;

  RouterNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((u) {
       print("Auth changed: $u");
      user = u;
      notifyListeners();
    });
  }
}

GoRouter createRouter() {
  final routerNotifier = RouterNotifier();

  return GoRouter(
    initialLocation: '/load',
    refreshListenable: routerNotifier,

    redirect: (context, state) {
      final user = routerNotifier.user;
      final isLoggedIn = user != null;

      final location = state.matchedLocation;

      final isAuthRoute =
          location == '/login' ||
          location == '/sign-up';

      final isSetupRoute =
          location == '/otp' ||
          location == '/enter-name' ||
          location == '/reset-password' ||
          location == '/personal-info' ||
          location == '/update-avatar';

      // ✅ cho load chạy bình thường
      if (location == '/load') return null;

      // ❌ chưa login mà vào lung tung → về home
      if (!isLoggedIn && !isAuthRoute && !isSetupRoute) {
        return '/';
      }

      // ❌ đã login mà quay lại login → đá về chat
      if (isLoggedIn && (location == '/' || location == '/login')) {
        return '/chat-list';
      }

      // ✅ còn lại cho đi bình thường
      return null;
    },

    routes: [
      // ===== HOME =====
      GoRoute(
        path: '/load',
        builder: (context, state) => const LoadView(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeView(),
      ),

      // ===== AUTH =====
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),

      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpView(),
      ),

      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpVerifyView(email: email);
        },
      ),

      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.extra as String?;
          return ResetPasswordView(email: email);
        },
      ),

      // ===== SETUP =====
      GoRoute(
        path: '/enter-name',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;

          return EnterNameView(
            email: data?['email'] ?? '',
            password: data?['password'] ?? '',
            name: data?['name'],
          );
        },
      ),

      GoRoute(
        path: '/personal-info',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;

          return PersonalInfoView(
            email: data?['email'] ?? '',
            password: data?['password'] ?? '',
            name: data?['name'] ?? '',
          );
        },
      ),

      GoRoute(
        path: '/update-avatar',
        builder: (context, state) => const UpdateAvatarView(),
      ),

      // ===== CHAT =====
      GoRoute(
        path: '/chat-list',
        builder: (context, state) => const ChatListView(),
      ),
    ],
  );
}