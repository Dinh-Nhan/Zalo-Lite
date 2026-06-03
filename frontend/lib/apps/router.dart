import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/widgets/demo_bio.dart';
import 'package:frontend/features/newfeed/screens/create_post_screen.dart';
import 'package:frontend/features/newfeed/screens/create_story_screen.dart';
import 'package:frontend/features/newfeed/screens/newfeed_screen.dart';
import 'package:frontend/features/newfeed/screens/story_viewer_screen.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/views/auth/set_password_view.dart';
import 'package:frontend/views/chat/chat_detail_view.dart';
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
      GoRoute(
        path: '/chat-detail',
        builder: (context, state) {
          final data = state.extra as Map;

          return ChatDetailView(
            conversationId: data['conversationId'],
            contactName: data['contactName'],
            avatarColor: data['avatarColor'],
            isGroup: data['isGroup'] ?? false,
            memberCount: data['memberCount'],
          );
        },
      ),
      GoRoute(
        path: '/demo-profile',
        builder: (context, state) {
          final user = state.extra as UserSearchModel;

          return UserProfileScreen(user: user);
        },
      ),

      // ===== NEWFEED =====
      GoRoute(
        path: '/newfeed',
        builder: (context, state) => const NewfeedScreen(),
      ),
      GoRoute(
        path: '/create-story',
        builder: (context, state) => const CreateStoryScreen(),
      ),
      GoRoute(
        path: '/story-viewer',
        builder: (context, state) {
          final startIndex = state.extra as int? ?? 0;
          return StoryViewerScreen(startIndex: startIndex);
        },
      ),
      // ===== PROFILE =====
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final userId = state.extra as String?;
          return ProfileScreen(targetUserId: userId);
        },
      ),
      GoRoute(
        path: '/create-post-avatar',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return CreatePostScreen(
            currentUserName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
            currentUserAvatar: FirebaseAuth.instance.currentUser?.photoURL ?? '',
            preSelectedBytes: data?['imageBytes'] as Uint8List?,
            preSelectedPath: data?['imagePath'] as String?,
          );
        },
      ),
    ],
  );
}
