// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';
//jsonとdartの変換を自動生成するコード

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  uuid: json['uuid'] as String,
  name: json['name'] as String,
  length: (json['length'] as num).toInt(),
  weight: (json['weight'] as num).toInt(),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'uuid': instance.uuid,
  'name': instance.name,
  'length': instance.length,
  'weight': instance.weight,
};

UserCreateRequest _$UserCreateRequestFromJson(Map<String, dynamic> json) =>
    UserCreateRequest(
      name: json['name'] as String,
      length: (json['length'] as num).toInt(),
      weight: (json['weight'] as num).toInt(),
    );

Map<String, dynamic> _$UserCreateRequestToJson(UserCreateRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'length': instance.length,
      'weight': instance.weight,
    };
