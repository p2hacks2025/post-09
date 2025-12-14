import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';

//APIとの通信を行うサービス
String get baseUrl {
  final raw = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
  return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
}

class ApiService {
  // ユーザーを作成
  static Future<User> createUser({
    required String name,
    required int length,
    required int weight,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/user/users');
      final request = UserCreateRequest(
        name: name,
        length: length,
        weight: weight,
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return User.fromJson(decoded);
      } else {
        throw Exception('ユーザー作成に失敗しました: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // すべてのユーザーを取得
  static Future<List<User>> getUsers() async {
    try {
      final uri = Uri.parse('$baseUrl/user/users');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((user) => User.fromJson(user)).toList();
        } else {
          throw Exception('予期しないレスポンス形式です');
        }
      } else {
        throw Exception('ユーザー取得に失敗しました: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 特定のユーザーを取得
  static Future<User> getUser(String uuid) async {
    try {
      final uri = Uri.parse('$baseUrl/user/users/$uuid');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return User.fromJson(decoded);
      } else {
        throw Exception('ユーザー取得に失敗しました: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
