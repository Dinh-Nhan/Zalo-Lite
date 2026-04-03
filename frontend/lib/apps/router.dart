import 'package:frontend/views/home_view.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/views/detail_view.dart';

GoRouter createdRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => HomeView()),
      GoRoute(path: '/detail', builder: (context, state) => DetailView()),
    ],
  );
}
