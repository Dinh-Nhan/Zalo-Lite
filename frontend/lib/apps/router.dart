import 'package:go_router/go_router.dart';
import '../views/home/home_view.dart';

/// Cấu hình router cho ứng dụng Zalo Lite
/// Hiện tại chỉ có route chính '/' → HomeView
/// Sẽ mở rộng thêm khi có thêm màn hình (auth, chat, contacts, ...)
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeView(),
      ),
      // TODO: Thêm các route sau khi hoàn thiện thêm views
      // GoRoute(path: '/login', builder: (context, state) => const LoginView()),
      // GoRoute(path: '/register', builder: (context, state) => const RegisterView()),
    ],
  );
}
