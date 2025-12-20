import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/trash_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // 使用 ValueNotifier 來觸發 Router 刷新，而不是重建 Router
  final authStateListenable = ValueNotifier<bool>(false);

  ref.listen(authProvider, (_, __) {
    authStateListenable.value = !authStateListenable.value;
  });

  return GoRouter(
    refreshListenable: authStateListenable,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/map',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return MapScreen(initialMediaId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/trash',
        builder: (context, state) => const TrashScreen(),
      ),
    ],
    redirect: (context, state) {
      // 這裡使用 read 來獲取最新狀態，避免觸發 Provider 重建
      final authState = ref.read(authProvider);

      // 如果 Auth 狀態還在 Loading，暫時不處理 (或可導向 Splash Screen)
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';

      // 如果未登入且不在登入頁，導向登入頁
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // 如果已登入且在登入頁，導向首頁
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
  );
});
