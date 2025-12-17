import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/auth_service.dart';
import '../../domain/user.dart';

/// 提供 GoogleSignIn 實例
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(scopes: ['email', 'profile', 'openid']);
});

/// Auth Notifier 用於管理登入狀態
///
/// 負責處理 Google 登入、後端驗證與狀態保存。
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // 檢查是否已經登入 (Persistence)
    // GoogleSignIn 支援 silent login，這會在 App 啟動時嘗試恢復登入狀態
    final googleSignIn = ref.read(googleSignInProvider);

    // 注意：signInSilently 可能會拋出異常，需要 try-catch
    try {
      final googleUser = await googleSignIn.signInSilently();
      if (googleUser != null) {
        // 如果 Google 已經登入，嘗試取得 Token 並與後端同步
        return await _authenticateWithBackend(googleUser);
      }
    } catch (e) {
      // 靜默登入失敗，視為未登入
      print('Silent sign-in failed: $e');
    }

    return null;
  }

  /// 處理 Google 登入流程
  Future<void> loginWithGoogle() async {
    // 設定為 Loading 狀態
    state = const AsyncValue.loading();

    // 執行登入邏輯並更新狀態
    state = await AsyncValue.guard(() async {
      final googleSignIn = ref.read(googleSignInProvider);
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // 使用者取消登入，拋出一個特定的錯誤或直接返回 null
        // 這裡我們選擇拋出錯誤讓 UI 處理，或者如果我們希望保持 null 狀態
        // 但 AsyncValue.guard 會捕捉錯誤。
        // 如果回傳 null，狀態會變成 AsyncData(null)，即未登入。
        return null;
      }

      return await _authenticateWithBackend(googleUser);
    });
  }

  /// 登出
  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final googleSignIn = ref.read(googleSignInProvider);
      await googleSignIn.signOut();
      return null;
    });
  }

  /// 內部函式：與後端驗證
  Future<User> _authenticateWithBackend(GoogleSignInAccount googleUser) async {
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Failed to retrieve ID Token');
    }

    final authService = ref.read(authServiceProvider);
    try {
      return await authService.loginWithGoogle(idToken);
    } catch (e) {
      // 如果後端驗證失敗，但 Google 登入成功，我們至少可以顯示 Google 的名稱
      // 這是一個 Fallback 機制，避免因為後端連線問題導致使用者看到 "Guest"
      print('Backend authentication failed: $e');
      return User(
        id: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );
    }
  }
}

/// Auth Provider
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});
