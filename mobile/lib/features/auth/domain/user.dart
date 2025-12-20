import 'dart:convert';

/// 使用者模型
///
/// 對應後端回傳的 User 資料結構。
class User {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? token; // 用於儲存 ID Token

  User({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.token,
  });

  /// 從 Map 建立 User
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['sub'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      photoUrl: map['picture'] as String?,
      token: map['token'] as String?,
    );
  }

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {'sub': id, 'email': email, 'name': name, 'picture': photoUrl};
  }

  /// 從 JSON 字串建立 User
  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  /// 轉換為 JSON 字串
  String toJson() => json.encode(toMap());

  @override
  String toString() => 'User(id: $id, email: $email)';
}
