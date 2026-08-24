import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/marketplace_model.dart';
import 'supabase_service.dart';

class MarketplaceService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<MarketplaceItemModel>> fetchListings({String? category}) async {
    var query = _client.from('marketplace_items').select('*');

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }

    final data = await query.order('created_at', ascending: false);

    return (data as List).map((json) => MarketplaceItemModel.fromJson(json as Map<String, dynamic>)).toList();
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

  Future<void> updateListingStatus(String id, String status) async {
    await _client
        .from('marketplace_items')
        .update({'status': status})
        .eq('id', id);
  }
}
