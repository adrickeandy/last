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

  final categories = [
    'All',
    'Books',
    'Electronics',
    'Clothing',
    'Furniture',
    'Other',
  ];

  String _selectedCategory = 'All';
  List<MarketplaceItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final list = await _marketplaceService.fetchListings(
        category: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _items = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MarketplaceScreen] Failed to load listings: $e');

      if (mounted) {
        setState(() {
          _items = [];
          _isLoading = false;
        });

        ToastOverlay.show(
          context,
          'Could not load Marketplace',
          type: ToastType.error,
        );
      }
    }
  }

  int _getCrossAxisCount(double width) {
    if (width >= 800) {
      return 3;
    }

    if (width >= 560) {
      return 2;
    }

    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final auth = context.watch<AuthProvider>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 900,
        ),
        child: RefreshIndicator(
          onRefresh: _loadListings,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
                  _getCrossAxisCount(constraints.maxWidth);

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // =========================================================
                  // HEADER
                  // =========================================================

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Campus Marketplace',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Buy and sell with classmates on campus.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? AppColors.darkInk400
                                    : AppColors.lightInk400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GlassButton(
                        variant:
                            GlassButtonVariant.primary,
                        text: 'List item',
                        icon: Icons.add_rounded,
                        height: 38,
                        onPressed: () {
                          if (auth.user == null) {
                            ToastOverlay.show(
                              context,
                              'Sign in to list an item',
                              type: ToastType.info,
                            );
                            return;
                          }

                          CreateListingDialog.show(
                            context,
                            onCreated: (newItem) {
                              if (!mounted) return;

                              setState(() {
                                _items.insert(0, newItem);
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // =========================================================
                  // CATEGORY FILTER
                  // =========================================================

                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = categories[i];
                        final isSelected =
                            cat == _selectedCategory;

                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor:
                              AppColors.violet500,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.04),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkInk300
                                    : AppColors.lightInk300),
                          ),
                          onSelected: (val) {
                            if (!val) return;

                            setState(() {
                              _selectedCategory = cat;
                            });

                            _loadListings();
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =========================================================
                  // LOADING
                  // =========================================================

                  if (_isLoading)
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio:
                            crossAxisCount == 1 ? 1.65 : 0.85,
                      ),
                      itemCount: 6,
                      itemBuilder: (_, __) =>
                          const SkeletonLoader(
                        height: 180,
                      ),
                    )

                  // =========================================================
                  // EMPTY
                  // =========================================================

                  else if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 48,
                            color: AppColors.coral400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No items in this category yet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'List an item for sale to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppColors.darkInk400
                                  : AppColors.lightInk400,
                            ),
                          ),
                        ],
                      ),
                    )

                  // =========================================================
                  // MARKETPLACE GRID
                  // =========================================================

                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio:
                            crossAxisCount == 1 ? 1.65 : 0.85,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        return _MarketplaceItemCard(
                          item: _items[i],
                          isDark: isDark,
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MARKETPLACE ITEM CARD
// ============================================================================

class _MarketplaceItemCard extends StatelessWidget {
  final MarketplaceItemModel item;
  final bool isDark;

  const _MarketplaceItemCard({
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrls.isNotEmpty;

    return GlassContainer(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showItemDetails(context);
        },
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =============================================================
            // IMAGE
            // =============================================================

            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(
                        item.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                        loadingBuilder:
                            (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }

                          return _buildImageLoading();
                        },
                      )
                    else
                      _buildImagePlaceholder(),

                    // Image count
                    if (item.imageUrls.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black
                                .withOpacity(0.65),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_library_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.imageUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Status
                    if (item.status != 'available')
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black
                                .withOpacity(0.65),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.status
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // =============================================================
            // DETAILS
            // =============================================================

            Expanded(
              flex: 4,
              child: Padding(
                padding:
                    const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      AppFormatters.formatCurrency(
                        item.price,
                        item.currency,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.violet400,
                      ),
                    ),

                    const Spacer(),

                    if (item.category != null)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration:
                            BoxDecoration(
                          color: isDark
                              ? Colors.white
                                  .withOpacity(0.06)
                              : Colors.black
                                  .withOpacity(0.04),
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: Text(
                          item.category!,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? AppColors
                                    .darkInk400
                                : AppColors
                                    .lightInk400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.04),
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 38,
          color: isDark
              ? AppColors.darkInk500
              : AppColors.lightInk500,
        ),
      ),
    );
  }

  Widget _buildImageLoading() {
    return Container(
      color: isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.04),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _MarketplaceItemDetailsDialog(
        item: item,
        isDark: isDark,
      ),
    );
  }
}

// ============================================================================
// ITEM DETAILS
// ============================================================================

class _MarketplaceItemDetailsDialog
    extends StatefulWidget {
  final MarketplaceItemModel item;
  final bool isDark;

  const _MarketplaceItemDetailsDialog({
    required this.item,
    required this.isDark,
  });

  @override
  State<_MarketplaceItemDetailsDialog>
      createState() =>
          _MarketplaceItemDetailsDialogState();
}

class _MarketplaceItemDetailsDialogState
    extends State<_MarketplaceItemDetailsDialog> {
  final PageController _pageController =
      PageController();

  int _currentImage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasImages = item.imageUrls.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 650,
          maxHeight: 750,
        ),
        child: GlassContainer(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // =========================================================
                // IMAGE VIEWER
                // =========================================================

                SizedBox(
                  height: 320,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: hasImages
                            ? PageView.builder(
                                controller:
                                    _pageController,
                                itemCount:
                                    item.imageUrls.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImage =
                                        index;
                                  });
                                },
                                itemBuilder:
                                    (context, index) {
                                  return Image.network(
                                    item.imageUrls[index],
                                    width:
                                        double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) {
                                      return _buildLargePlaceholder();
                                    },
                                  );
                                },
                              )
                            : _buildLargePlaceholder(),
                      ),

                      // Close
                      Positioned(
                        top: 12,
                        right: 12,
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.black
                                    .withOpacity(0.6),
                            foregroundColor:
                                Colors.white,
                          ),
                          onPressed: () =>
                              Navigator.pop(
                            context,
                          ),
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                        ),
                      ),

                      // Image counter
                      if (item.imageUrls.length > 1)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withOpacity(0.65),
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: Text(
                              '${_currentImage + 1}/${item.imageUrls.length}',
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // =========================================================
                // DETAILS
                // =========================================================

                Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        AppFormatters.formatCurrency(
                          item.price,
                          item.currency,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppColors.violet400,
                        ),
                      ),

                      if (item.category != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration:
                              BoxDecoration(
                            color: widget.isDark
                                ? Colors.white
                                    .withOpacity(0.06)
                                : Colors.black
                                    .withOpacity(0.04),
                            borderRadius:
                                BorderRadius.circular(
                              9,
                            ),
                          ),
                          child: Text(
                            item.category!,
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isDark
                                  ? AppColors
                                      .darkInk400
                                  : AppColors
                                      .lightInk400,
                            ),
                          ),
                        ),
                      ],

                      if (item.description !=
                              null &&
                          item.description!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Description',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: widget.isDark
                                ? AppColors
                                    .darkInk300
                                : AppColors
                                    .lightInk300,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      if (item.status != 'available')
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets.all(
                            12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                            color: AppColors.coral400
                                .withOpacity(0.1),
                          ),
                          child: Text(
                            'This item is ${item.status}.',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        GlassButton(
                          width:
                              double.infinity,
                          height: 44,
                          text:
                              'Contact Seller',
                          icon: Icons
                              .chat_bubble_outline_rounded,
                          variant:
                              GlassButtonVariant
                                  .primary,
                          onPressed: () {
                            ToastOverlay.show(
                              context,
                              'Seller contact can be connected here.',
                              type:
                                  ToastType.info,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargePlaceholder() {
    return Container(
      width: double.infinity,
      color: widget.isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.04),
      child: const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 64,
          color: AppColors.coral400,
        ),
      ),
    );
  }
}
