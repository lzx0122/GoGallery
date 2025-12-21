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
      // 如果後端沒有回傳 token，則使用 Google ID Token 作為 fallback
      if (data['token'] == null) {
        data['token'] = idToken;
      }
      return User.fromMap(data);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
}
