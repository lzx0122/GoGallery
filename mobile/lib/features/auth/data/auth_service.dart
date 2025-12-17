import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/google'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
}
