import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../domain/user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  // TODO: Move this to a configuration file or environment variable
  // For Android Emulator, use 10.0.2.2. For iOS Simulator, use localhost.
  String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// 使用 Google ID Token 登入後端
  ///
  /// 回傳 [User] 物件
  Future<User> loginWithGoogle(String idToken) async {
    // 直接使用真實的 Google ID Token
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/google'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // 將 ID Token 注入到 User 物件中，因為後端回傳的 User 可能不包含 Token
      // 但後續 API 呼叫需要這個 Token
      data['token'] = idToken;
      return User.fromMap(data);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
}
