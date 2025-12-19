import 'user.dart';

/// シンボル（地図上の目印・ランドマーク）データ
class Symbol {
  final String uuid;
  final String userUuid;
  final String symbolName;
  final double symbolXCoord;
  final double symbolYCoord;
  final int kirakiraLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  Symbol({
    required this.uuid,
    required this.userUuid,
    required this.symbolName,
    required this.symbolXCoord,
    required this.symbolYCoord,
    required this.kirakiraLevel,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Symbol.fromJson(Map<String, dynamic> json) {
    return Symbol(
      uuid: json['uuid'] as String,
      userUuid: json['user_uuid'] as String,
      symbolName: json['symbol_name'] as String,
      symbolXCoord: (json['symbol_x_coord'] as num).toDouble(),
      symbolYCoord: (json['symbol_y_coord'] as num).toDouble(),
      kirakiraLevel: json['kirakira_level'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'user_uuid': userUuid,
      'symbol_name': symbolName,
      'symbol_x_coord': symbolXCoord,
      'symbol_y_coord': symbolYCoord,
      'kirakira_level': kirakiraLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }
}

/// シンボル作成リクエスト
class SymbolCreateRequest {
  final String userUuid;
  final String symbolName;
  final double symbolXCoord;
  final double symbolYCoord;
  final int kirakiraLevel;

  SymbolCreateRequest({
    required this.userUuid,
    required this.symbolName,
    required this.symbolXCoord,
    required this.symbolYCoord,
    this.kirakiraLevel = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_uuid': userUuid,
      'symbol_name': symbolName,
      'symbol_x_coord': symbolXCoord,
      'symbol_y_coord': symbolYCoord,
      'kirakira_level': kirakiraLevel,
    };
  }
}

/// シンボル更新リクエスト
class SymbolUpdateRequest {
  final String? symbolName;
  final double? symbolXCoord;
  final double? symbolYCoord;
  final int? kirakiraLevel;

  SymbolUpdateRequest({
    this.symbolName,
    this.symbolXCoord,
    this.symbolYCoord,
    this.kirakiraLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      if (symbolName != null) 'symbol_name': symbolName,
      if (symbolXCoord != null) 'symbol_x_coord': symbolXCoord,
      if (symbolYCoord != null) 'symbol_y_coord': symbolYCoord,
      if (kirakiraLevel != null) 'kirakira_level': kirakiraLevel,
    };
  }
}

/// ユーザーのシンボル一覧レスポンス
class UserSymbols {
  final String userUuid;
  final List<Symbol> symbols;

  UserSymbols({required this.userUuid, required this.symbols});

  factory UserSymbols.fromJson(Map<String, dynamic> json) {
    return UserSymbols(
      userUuid: json['user_uuid'] as String,
      symbols: (json['symbols'] as List<dynamic>)
          .map((e) => Symbol.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_uuid': userUuid,
      'symbols': symbols.map((s) => s.toJson()).toList(),
    };
  }
}
