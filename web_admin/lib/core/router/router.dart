import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../../features/users/presentation/pages/user_detail_page.dart';
import '../../features/feeds/presentation/pages/feeds_page.dart';
import '../../features/feeds/presentation/pages/feed_detail_page.dart';
import '../../features/hidden_posts/presentation/pages/hidden_posts_page.dart';
import '../../features/friendships/presentation/pages/friendships_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/reports/presentation/pages/report_detail_page.dart';
import '../../features/admins/presentation/pages/admins_page.dart';
import '../../features/feedbacks/presentation/pages/feedbacks_page.dart';
import '../../features/feedbacks/presentation/pages/feedback_detail_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/pages/notification_form_page.dart';
import '../../shared/widgets/admin_scaffold.dart';

// ============================================================
// ROUTER - GoRouter with Auth Guard (no code generation)
// ============================================================

class AppRoutes {
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/';
  static const users = '/users';
  static const feeds = '/feeds';
  static const hiddenPosts = '/hidden-posts';
  static const friendships = '/friendships';
  static const reports = '/reports';
  static const admins = '/admins';
  static const feedbacks = '/feedbacks';
  static const notifications = '/notifications';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authStateAsync.valueOrNull ?? false;
      final loc = state.matchedLocation;
      final isPublicRoute =
          loc == AppRoutes.login || loc == AppRoutes.forgotPassword;

      if (!isLoggedIn && !isPublicRoute) return AppRoutes.login;
      if (isLoggedIn && isPublicRoute) return AppRoutes.dashboard;
      return null;
    },
    refreshListenable: _GoRouterRefreshStream(
      ref.watch(authStateProvider.stream),
    ),
    routes: [
      // Public routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),

      // Admin Shell
      ShellRoute(
        builder: (context, state, child) => AdminScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.users,
            name: 'users',
            builder: (_, __) => const UsersPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'user-detail',
                builder: (_, state) =>
                    UserDetailPage(userId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.feeds,
            name: 'feeds',
            builder: (_, __) => const FeedsPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'feed-detail',
                builder: (_, state) =>
                    FeedDetailPage(feedId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.hiddenPosts,
            name: 'hidden-posts',
            builder: (_, __) => const HiddenPostsPage(),
          ),
          GoRoute(
            path: AppRoutes.friendships,
            name: 'friendships',
            builder: (_, __) => const FriendshipsPage(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            builder: (_, __) => const ReportsPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'report-detail',
                builder: (_, state) =>
                    ReportDetailPage(reportId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.admins,
            name: 'admins',
            builder: (_, __) => const AdminsPage(),
          ),
          GoRoute(
            path: AppRoutes.feedbacks,
            name: 'feedbacks',
            builder: (_, __) => const FeedbacksPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'feedback-detail',
                builder: (_, state) => FeedbackDetailPage(
                    feedbackId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: 'notifications',
            builder: (_, __) => const NotificationsPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'notification-new',
                builder: (_, __) => const NotificationFormPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
