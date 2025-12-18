// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductVariantImpl _$$ProductVariantImplFromJson(Map<String, dynamic> json) =>
    _$ProductVariantImpl(
      name: json['name'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$ProductVariantImplToJson(
        _$ProductVariantImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'options': instance.options,
    };

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      description: json['description'] as String? ?? '',
      specifications: (json['specifications'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      sellerName: json['sellerName'] as String? ?? '',
      sellerId: json['sellerId'] as String? ?? '',
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'price': instance.price,
      'unit': instance.unit,
      'imageUrls': instance.imageUrls,
      'description': instance.description,
      'specifications': instance.specifications,
      'variants': instance.variants,
      'stockQuantity': instance.stockQuantity,
      'category': instance.category,
      'sellerName': instance.sellerName,
      'sellerId': instance.sellerId,
    };
