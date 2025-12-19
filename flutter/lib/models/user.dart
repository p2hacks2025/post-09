import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

//ユーザーデータをバックエンドから取得する
@JsonSerializable()
class User {
  final String uuid;
  final String name;
  final int length;
  final int weight;

  User({
    required this.uuid,
    required this.name,
    required this.length,
    required this.weight,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class UserCreateRequest {
  final String name;
  final int length;
  final int weight;

  UserCreateRequest({
    required this.name,
    required this.length,
    required this.weight,
  });

  factory UserCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$UserCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UserCreateRequestToJson(this);
}

class UserUpdateRequest {
  final String? name;
  final int? length;
  final int? weight;

  UserUpdateRequest({this.name, this.length, this.weight});

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (length != null) 'length': length,
      if (weight != null) 'weight': weight,
    };
  }
}
