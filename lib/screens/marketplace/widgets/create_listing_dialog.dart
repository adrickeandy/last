import 'package:flutter/material.dart';
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

  const CreateListingDialog({super.key, this.onCreated});

  static Future<void> show(BuildContext context, {Function(MarketplaceItemModel)? onCreated}) async {
    await showDialog(
      context: context,
      builder: (ctx) => CreateListingDialog(onCreated: onCreated),
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
  String _selectedCategory = 'Books';
  bool _isLoading = false;

  final categories = ['Books', 'Electronics', 'Clothing', 'Furniture', 'Other'];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to list an item', type: ToastType.error);
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    setState(() => _isLoading = true);

    try {
      final item = await _marketplaceService.createListing(
        sellerId: user.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: price,
        category: _selectedCategory,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated?.call(item);
        ToastOverlay.show(context, 'Item listed on Marketplace!', type: ToastType.success);
      }
    } catch (e) {
      print('[CreateListingDialog] error: $e');
      if (mounted) {
        ToastOverlay.show(context, 'Could not list item', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('List Item for Sale', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GlassTextField(
                  controller: _titleController,
                  labelText: 'Item Title',
                  hintText: 'e.g. Calculus 8th Edition Textbook',
                  validator: (v) => AppValidators.validateRequired(v, 'Title'),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: GlassTextField(
                        controller: _priceController,
                        labelText: 'Price (UGX)',
                        hintText: '45000',
                        keyboardType: TextInputType.number,
                        validator: (v) => AppValidators.validateRequired(v, 'Price'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            items: categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCategory = v ?? 'Books'),
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
                  hintText: 'Good condition, no missing pages, pickup on main campus.',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                GlassButton(
                  width: double.infinity,
                  height: 44,
                  text: 'Publish Listing',
                  isLoading: _isLoading,
                  onPressed: _handleCreate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
