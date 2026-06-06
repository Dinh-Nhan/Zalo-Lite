import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/widgets/demo_bio.dart';
import 'package:frontend/features/friends/widgets/my_profile.dart';
import 'package:frontend/features/newfeed/screens/create_post_screen.dart';
import 'package:frontend/features/newfeed/screens/create_story_screen.dart';
import 'package:frontend/features/newfeed/screens/newfeed_screen.dart';
import 'package:frontend/features/newfeed/screens/story_viewer_screen.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/views/auth/set_password_view.dart';
import 'package:go_router/go_router.dart';

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

      final isAuthRoute = location == '/login' || location == '/sign-up';
      final isSetupRoute =
          location == '/otp' ||
          location == '/enter-name' ||
          location == '/reset-password' ||
          location == '/personal-info' ||
          location == '/update-avatar';

      if (location == '/load') return null;
      if (!isLoggedIn && !isAuthRoute && !isSetupRoute) return '/';
      if (isLoggedIn && (location == '/' || location == '/login')) {
        return '/chat-list';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/load',
        builder: (context, state) => const LoadView(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeView(),
      ),
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
      GoRoute(
        path: '/chat-list',
        builder: (context, state) => const ChatListView(),
      ),
      GoRoute(
        path: '/chat-detail',
        builder: (context, state) => const ChatListView(),
      ),
      GoRoute(
        path: '/demo-profile',
        builder: (context, state) {
          final user = state.extra as UserSearchModel;
          return UserProfileScreen(user: user);
        },
      ),
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
            currentUserName:
                FirebaseAuth.instance.currentUser?.displayName ?? 'User',
            currentUserAvatar:
                data?['currentUserAvatar'] as String? ??
                FirebaseAuth.instance.currentUser?.photoURL ?? '',
            preSelectedBytes: data?['imageBytes'] as Uint8List?,
            preSelectedPath: data?['imagePath'] as String?,
            shouldUpdateAvatarOnSubmit:
                data?['shouldUpdateAvatarOnSubmit'] as bool? ?? false,
            avatarImagePath: data?['avatarImagePath'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/my-profile',
        builder: (context, state) => const MyProfileScreen(),
      ),
    ],
  );
}
