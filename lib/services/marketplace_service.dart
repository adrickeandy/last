import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace_model.dart';
import 'supabase_service.dart';

class MarketplaceService {
  final SupabaseClient _client = SupabaseService.client;

  static const String _imageBucket = 'marketplace-images';

  Future<List<MarketplaceItemModel>> fetchListings({
    String? category,
  }) async {
    var query = _client.from('marketplace_items').select('*');

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }

    final data = await query.order('created_at', ascending: false);

    return (data as List)
        .map(
          (json) => MarketplaceItemModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Uploads marketplace images to Supabase Storage.
  ///
  /// Returns the public URLs of the uploaded images.
  Future<List<String>> uploadMarketplaceImages({
    required String sellerId,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) {
      return [];
    }

    final uploadedUrls = <String>[];

    for (int i = 0; i < images.length; i++) {
      final image = images[i];

      final Uint8List bytes = await image.readAsBytes();

      final extension = _getExtension(image.name);

      final fileName =
          '${DateTime.now().microsecondsSinceEpoch}_${i + 1}.$extension';

      final storagePath = '$sellerId/$fileName';

      await _client.storage.from(_imageBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: false,
            ),
          );

      final publicUrl = _client.storage
          .from(_imageBucket)
          .getPublicUrl(storagePath);

      uploadedUrls.add(publicUrl);
    }

    return uploadedUrls;
  }

  Future<MarketplaceItemModel> createListing({
    required String sellerId,
    required String title,
    String? description,
    required num price,
    String currency = 'UGX',
    List<String> imageUrls = const [],
    String? category,
  }) async {
    final data = await _client
        .from('marketplace_items')
        .insert({
          'seller_id': sellerId,
          'title': title,
          'description': description,
          'price': price,
          'currency': currency,
          'image_urls': imageUrls,
          'category': category,
          'status': 'available',
        })
        .select()
        .single();

    return MarketplaceItemModel.fromJson(data);
  }

  Future<MarketplaceItemModel> createListingWithImages({
    required String sellerId,
    required String title,
    String? description,
    required num price,
    String currency = 'UGX',
    List<XFile> images = const [],
    String? category,
  }) async {
    final imageUrls = await uploadMarketplaceImages(
      sellerId: sellerId,
      images: images,
    );

    return createListing(
      sellerId: sellerId,
      title: title,
      description: description,
      price: price,
      currency: currency,
      imageUrls: imageUrls,
      category: category,
    );
  }

  Future<void> updateListingStatus(
    String id,
    String status,
  ) async {
    await _client
        .from('marketplace_items')
        .update({'status': status})
        .eq('id', id);
  }

  String _getExtension(String fileName) {
    final parts = fileName.split('.');

    if (parts.length < 2) {
      return 'jpg';
    }

    final extension = parts.last.toLowerCase();

    const allowed = [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'heic',
      'heif',
    ];

    if (!allowed.contains(extension)) {
      return 'jpg';
    }

    return extension;
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      case 'heic':
        return 'image/heic';

      case 'heif':
        return 'image/heif';

      default:
        return 'image/jpeg';
    }
  }
}
