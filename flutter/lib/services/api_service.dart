import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/step.dart';
import '../models/symbol.dart';
import '../models/user.dart';

// APIとの通信をまとめたサービス（backendのFastAPIに対応）
String get baseUrl {
  final raw = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
  return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
}

class ApiService {
  static const _contentTypeJson = {'Content-Type': 'application/json'};

  static Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final qp = query?.map((k, v) => MapEntry(k, v.toString()));
    return Uri.parse('$baseUrl$path').replace(queryParameters: qp);
  }

  static String _formatDate(DateTime date) =>
      date.toIso8601String().split('T').first;

  static Exception _httpException(String action, http.Response response) {
    final body = response.body.isNotEmpty
        ? utf8.decode(response.bodyBytes)
        : '';
    return Exception(
      '$actionに失敗しました (status: ${response.statusCode}${body.isNotEmpty ? ', body: $body' : ''})',
    );
  }

  static T _handleResponse<T>({
    required http.Response response,
    required List<int> okStatus,
    required T Function(dynamic decoded) parse,
    required String action,
  }) {
    if (okStatus.contains(response.statusCode)) {
      final decoded = response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
      return parse(decoded);
    }
    throw _httpException(action, response);
  }

  // ----- User endpoints -----

  static Future<User> createUser({
    required String name,
    required int length,
    required int weight,
  }) async {
    final response = await http.post(
      _buildUri('/user/users'),
      headers: _contentTypeJson,
      body: jsonEncode(
        UserCreateRequest(name: name, length: length, weight: weight).toJson(),
      ),
    );

    return _handleResponse(
      response: response,
      okStatus: const [201],
      parse: (decoded) => User.fromJson(decoded as Map<String, dynamic>),
      action: 'ユーザー作成',
    );
  }

  static Future<List<User>> getUsers({int skip = 0, int limit = 100}) async {
    final response = await http.get(
      _buildUri('/user/users', {'skip': skip, 'limit': limit}),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) {
        final list = decoded as List<dynamic>;
        return list
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      action: 'ユーザー一覧取得',
    );
  }

  static Future<User> getUser(String uuid) async {
    final response = await http.get(_buildUri('/user/users/$uuid'));

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => User.fromJson(decoded as Map<String, dynamic>),
      action: 'ユーザー取得',
    );
  }

  static Future<User> updateUser({
    required String uuid,
    String? name,
    int? length,
    int? weight,
  }) async {
    final payload = UserUpdateRequest(
      name: name,
      length: length,
      weight: weight,
    ).toJson();
    if (payload.isEmpty) {
      throw Exception('更新内容がありません');
    }

    final response = await http.put(
      _buildUri('/user/users/$uuid'),
      headers: _contentTypeJson,
      body: jsonEncode(payload),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => User.fromJson(decoded as Map<String, dynamic>),
      action: 'ユーザー更新',
    );
  }

  static Future<User> deleteUser(String uuid) async {
    final response = await http.delete(_buildUri('/user/users/$uuid'));

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => User.fromJson(decoded as Map<String, dynamic>),
      action: 'ユーザー削除',
    );
  }

  // ----- Step endpoints -----

  static Future<StepEntry> createStep(StepCreateRequest request) async {
    final response = await http.post(
      _buildUri('/step/steps'),
      headers: _contentTypeJson,
      body: jsonEncode(request.toJson()),
    );

    return _handleResponse(
      response: response,
      okStatus: const [201],
      parse: (decoded) => StepEntry.fromJson(decoded as Map<String, dynamic>),
      action: '歩数作成',
    );
  }

  static Future<List<StepEntry>> getSteps({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await http.get(
      _buildUri('/step/steps', {'skip': skip, 'limit': limit}),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) {
        final list = decoded as List<dynamic>;
        return list
            .map((e) => StepEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      action: '歩数一覧取得',
    );
  }

  static Future<StepEntry> getStep(String uuid) async {
    final response = await http.get(_buildUri('/step/steps/$uuid'));

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => StepEntry.fromJson(decoded as Map<String, dynamic>),
      action: '歩数取得',
    );
  }

  static Future<StepEntry> updateStep(
    String uuid,
    StepUpdateRequest request,
  ) async {
    final payload = request.toJson();
    if (payload.isEmpty) {
      throw Exception('更新内容がありません');
    }

    final response = await http.put(
      _buildUri('/step/steps/$uuid'),
      headers: _contentTypeJson,
      body: jsonEncode(payload),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => StepEntry.fromJson(decoded as Map<String, dynamic>),
      action: '歩数更新',
    );
  }

  static Future<StepEntry> deleteStep(String uuid) async {
    final response = await http.delete(_buildUri('/step/steps/$uuid'));

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => StepEntry.fromJson(decoded as Map<String, dynamic>),
      action: '歩数削除',
    );
  }

  static Future<List<StepEntry>> getStepsByUser({
    required String userUuid,
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await http.get(
      _buildUri('/step/users/$userUuid/steps', {'skip': skip, 'limit': limit}),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) {
        final list = decoded as List<dynamic>;
        return list
            .map((e) => StepEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      action: 'ユーザー別歩数取得',
    );
  }

  static Future<StepEntry> getStepByUserAndDate({
    required String userUuid,
    required DateTime targetDate,
  }) async {
    final date = _formatDate(targetDate);
    final response = await http.get(
      _buildUri('/step/users/$userUuid/steps/$date'),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => StepEntry.fromJson(decoded as Map<String, dynamic>),
      action: '日付指定歩数取得',
    );
  }

  static Future<LatestSessionSteps> getLatestSessionSteps(
    String userUuid,
  ) async {
    final response = await http.get(
      _buildUri('/step/users/$userUuid/steps/steps/session/latest'),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) =>
          LatestSessionSteps.fromJson(decoded as Map<String, dynamic>),
      action: '最新セッション歩数取得',
    );
  }

  static Future<DailyTotalSteps> getDailyTotalSteps({
    required String userUuid,
    required DateTime targetDate,
  }) async {
    final date = _formatDate(targetDate);
    final response = await http.get(
      _buildUri('/step/users/$userUuid/steps/daily-total/$date'),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) =>
          DailyTotalSteps.fromJson(decoded as Map<String, dynamic>),
      action: '日別合計歩数取得',
    );
  }

  // ----- Symbol endpoints -----

  static Future<Symbol> createSymbol(SymbolCreateRequest request) async {
    final response = await http.post(
      _buildUri('/symbol/symbols'),
      headers: _contentTypeJson,
      body: jsonEncode(request.toJson()),
    );

    return _handleResponse(
      response: response,
      okStatus: const [201],
      parse: (decoded) => Symbol.fromJson(decoded as Map<String, dynamic>),
      action: 'シンボル作成',
    );
  }

  static Future<List<Symbol>> getSymbols({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await http.get(
      _buildUri('/symbol/symbols', {'skip': skip, 'limit': limit}),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) {
        final list = decoded as List<dynamic>;
        return list
            .map((e) => Symbol.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      action: 'シンボル一覧取得',
    );
  }

  static Future<Symbol> getSymbol(String uuid) async {
    final response = await http.get(_buildUri('/symbol/symbols/$uuid'));

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => Symbol.fromJson(decoded as Map<String, dynamic>),
      action: 'シンボル取得',
    );
  }

  static Future<Symbol> updateSymbol(
    String uuid,
    SymbolUpdateRequest request,
  ) async {
    final payload = request.toJson();
    if (payload.isEmpty) {
      throw Exception('更新内容がありません');
    }

    final response = await http.put(
      _buildUri('/symbol/symbols/$uuid'),
      headers: _contentTypeJson,
      body: jsonEncode(payload),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => Symbol.fromJson(decoded as Map<String, dynamic>),
      action: 'シンボル更新',
    );
  }

  static Future<void> deleteSymbol(String uuid) async {
    final response = await http.delete(_buildUri('/symbol/symbols/$uuid'));

    return _handleResponse(
      response: response,
      okStatus: const [204],
      parse: (_) => null,
      action: 'シンボル削除',
    );
  }

  static Future<UserSymbols> getSymbolsByUser({
    required String userUuid,
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await http.get(
      _buildUri('/symbol/users/$userUuid/symbols', {
        'skip': skip,
        'limit': limit,
      }),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => UserSymbols.fromJson(decoded as Map<String, dynamic>),
      action: 'ユーザー別シンボル取得',
    );
  }

  static Future<int> getKirakiraRemainingTime(String uuid) async {
    final response = await http.get(
      _buildUri('/symbol/symbols/$uuid/kirakira_remaining_time'),
    );

    return _handleResponse(
      response: response,
      okStatus: const [200],
      parse: (decoded) => decoded as int,
      action: 'キラキラ残り時間取得',
    );
  }
}
