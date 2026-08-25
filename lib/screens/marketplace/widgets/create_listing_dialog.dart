import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../../../core/widgets/toast_overlay.dart';
import '../../../models/marketplace_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/marketplace_service.dart';

class CreateListingDialog extends StatefulWidget {
  final Function(MarketplaceItemModel)? onCreated;

  const CreateListingDialog({
    super.key,
    this.onCreated,
  });

  static Future<void> show(
    BuildContext context, {
    Function(MarketplaceItemModel)? onCreated,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => CreateListingDialog(
        onCreated: onCreated,
      ),
    );
  }

  @override
  State<CreateListingDialog> createState() => _CreateListingDialogState();
}

class _CreateListingDialogState extends State<CreateListingDialog> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  final _marketplaceService = MarketplaceService();
  final _imagePicker = ImagePicker();

  String _selectedCategory = 'Books';

  bool _isLoading = false;
  bool _isPickingImages = false;

  List<XFile> _selectedImages = [];

  static const int _maxImages = 6;

  final categories = [
    'Books',
    'Electronics',
    'Clothing',
    'Furniture',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      ToastOverlay.show(
        context,
        'You can add up to $_maxImages photos',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isPickingImages = true);

    try {
      final remaining = _maxImages - _selectedImages.length;

      final images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (images.isEmpty) {
        return;
      }

      final newImages = images.take(remaining).toList();

      setState(() {
        _selectedImages.addAll(newImages);
      });

      if (images.length > remaining && mounted) {
        ToastOverlay.show(
          context,
          'Only $_maxImages photos can be added',
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint('[CreateListingDialog] Image picker error: $e');

      if (mounted) {
        ToastOverlay.show(
          context,
          'Could not select images',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  Future<void> _pickCameraImage() async {
    if (_selectedImages.length >= _maxImages) {
      ToastOverlay.show(
        context,
        'You can add up to $_maxImages photos',
        type: ToastType.error,
      );
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _selectedImages.add(image);
      });
    } catch (e) {
      debugPrint('[CreateListingDialog] Camera error: $e');

      if (mounted) {
        ToastOverlay.show(
          context,
          'Could not open camera',
          type: ToastType.error,
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: GlassContainer(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add Photos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select multiple photos'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImages();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Take a Photo'),
                  subtitle: const Text('Use your camera'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickCameraImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      ToastOverlay.show(
        context,
        'Sign in to list an item',
        type: ToastType.error,
      );
      return;
    }

    final price = double.tryParse(
          _priceController.text.trim().replaceAll(',', ''),
        ) ??
        0;

    if (price <= 0) {
      ToastOverlay.show(
        context,
        'Enter a valid price',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final item = await _marketplaceService.createListingWithImages(
        sellerId: user.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: price,
        category: _selectedCategory,
        images: _selectedImages,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      widget.onCreated?.call(item);

      ToastOverlay.show(
        context,
        'Item listed on Marketplace!',
        type: ToastType.success,
      );
    } catch (e) {
      debugPrint('[CreateListingDialog] error: $e');

      if (mounted) {
        ToastOverlay.show(
          context,
          'Could not list item. Please try again.',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_selectedImages.length}/$_maxImages',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_selectedImages.isEmpty)
          InkWell(
            onTap: _isPickingImages ? null : _showImageSourcePicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withOpacity(0.4),
                ),
              ),
              child: _isPickingImages
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 38,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add photos of your item',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gallery or camera',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length +
                      (_selectedImages.length < _maxImages ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return _buildAddImageButton();
                    }

                    return _buildImagePreview(
                      _selectedImages[index],
                      index,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add clear photos showing the item's condition.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.55),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: _showImageSourcePicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 105,
        height: 105,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withOpacity(0.4),
          ),
        ),
        child: const Icon(
          Icons.add_photo_alternate_rounded,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildImagePreview(
    XFile image,
    int index,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: FutureBuilder(
            future: image.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Container(
                  width: 105,
                  height: 105,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: const Icon(
                    Icons.broken_image_outlined,
                  ),
                );
              }

              return Image.memory(
                snapshot.data!,
                width: 105,
                height: 105,
                fit: BoxFit.cover,
              );
            },
          ),
        ),

        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ),

        if (index == 0)
          Positioned(
            bottom: 5,
            left: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text(
                'Cover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'List Item for Sale',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildImagePicker(),

                  const SizedBox(height: 18),

                  GlassTextField(
                    controller: _titleController,
                    labelText: 'Item Title',
                    hintText:
                        'e.g. Calculus 8th Edition Textbook',
                    validator: (v) =>
                        AppValidators.validateRequired(
                      v,
                      'Title',
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: _priceController,
                          labelText: 'Price (UGX)',
                          hintText: '45000',
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) =>
                              AppValidators.validateRequired(
                            v,
                            'Price',
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              items: categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style:
                                            const TextStyle(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isLoading
                                  ? null
                                  : (v) {
                                      setState(
                                        () =>
                                            _selectedCategory =
                                                v ?? 'Books',
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  GlassTextField(
                    controller: _descController,
                    labelText: 'Description & Condition',
                    hintText:
                        'Good condition, no missing pages, pickup on main campus.',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  GlassButton(
                    width: double.infinity,
                    height: 44,
                    text: _selectedImages.isEmpty
                        ? 'Publish Listing'
                        : 'Publish Listing (${_selectedImages.length} photos)',
                    isLoading: _isLoading,
                    onPressed:
                        _isLoading ? null : _handleCreate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
