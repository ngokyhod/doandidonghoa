// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Review _$ReviewFromJson(Map<String, dynamic> json) => _Review(
  userName: json['userName'] as String,
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String,
  date: DateTime.parse(json['date'] as String),
);

Map<String, dynamic> _$ReviewToJson(_Review instance) => <String, dynamic>{
  'userName': instance.userName,
  'rating': instance.rating,
  'comment': instance.comment,
  'date': instance.date.toIso8601String(),
};

_ProductVariant _$ProductVariantFromJson(Map<String, dynamic> json) =>
    _ProductVariant(
      name: json['name'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ProductVariantToJson(_ProductVariant instance) =>
    <String, dynamic>{'name': instance.name, 'options': instance.options};
