import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/marketplace_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/marketplace_service.dart';
import 'widgets/create_listing_dialog.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _marketplaceService = MarketplaceService();
  final categories = ['All', 'Books', 'Electronics', 'Clothing', 'Furniture', 'Other'];
  String _selectedCategory = 'All';
  List<MarketplaceItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);
    final list = await _marketplaceService.fetchListings(category: _selectedCategory);
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: RefreshIndicator(
          onRefresh: _loadListings,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Campus Marketplace', style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        'Buy and sell with classmates on campus.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                        ),
                      ),
                    ],
                  ),
                  GlassButton(
                    variant: GlassButtonVariant.primary,
                    text: 'List item',
                    icon: Icons.add_rounded,
                    height: 38,
                    onPressed: () {
                      if (auth.user == null) {
                        ToastOverlay.show(context, 'Sign in to list an item', type: ToastType.info);
                        return;
                      }
                      CreateListingDialog.show(
                        context,
                        onCreated: (newItem) {
                          setState(() => _items.insert(0, newItem));
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Category Filter Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final isSelected = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.violet500,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkInk300 : AppColors.lightInk300),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedCategory = cat);
                          _loadListings();
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Items Grid
              if (_isLoading)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, __) => const SkeletonLoader(height: 180),
                )
              else if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.coral400),
                      const SizedBox(height: 12),
                      const Text('No items in this category yet', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'List an item for sale to get started.',
                        style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return GlassContainer(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Image Header Placeholder
                          Container(
                            height: 110,
                            width: double.infinity,
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                            child: Center(
                              child: Icon(
                                Icons.tag_rounded,
                                size: 36,
                                color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.formatCurrency(item.price, item.currency),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.violet400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (item.category != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.category!,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
