import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../models/product.dart';
import '../../services/supabase_service.dart';
import '../../widgets/background_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});
  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final _service = SupabaseService.instance;
  bool _loading = true;
  String? _error;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _service.getAllProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _edit([Product? product]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
    );
    if (saved == true) _load();
  }

  Future<void> _toggle(Product p) async {
    try {
      await _service.setProductAvailability(p.id, !p.isAvailable);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteProduct(p.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Menu Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _edit(),
              tooltip: 'Add product',
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingWidget(message: 'Loading menu...');
    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load menu',
        subtitle: _error,
        action: ElevatedButton(onPressed: _load, child: const Text('Retry')),
      );
    }
    if (_products.isEmpty) {
      return const EmptyState(
        icon: Icons.restaurant_menu,
        title: 'No products yet',
        subtitle: 'Tap + to add your first item.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _products.length,
      itemBuilder: (_, i) {
        final p = _products[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 54, height: 54, child: _thumb(p)),
            ),
            title: Text(
              p.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: p.isAvailable ? null : TextDecoration.lineThrough,
                color: p.isAvailable ? null : Colors.grey,
              ),
            ),
            subtitle: Text(
              '${p.formattedPrice}'
              '${p.category != null ? ' · ${p.category}' : ''}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: p.isAvailable ? 'Hide' : 'Show',
                  icon: Icon(
                    p.isAvailable ? Icons.visibility : Icons.visibility_off,
                    color: p.isAvailable ? AppColors.success : Colors.grey,
                  ),
                  onPressed: () => _toggle(p),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.info),
                  onPressed: () => _edit(p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.danger),
                  onPressed: () => _delete(p),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumb(Product p) {
    final url = p.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.cream,
        child: const Icon(Icons.local_cafe, color: AppColors.latte),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.cream,
        child: const Icon(Icons.broken_image, color: AppColors.latte),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  const AddEditProductScreen({super.key, this.product});
  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();

  final _picker = ImagePicker();
  XFile? _picked;
  bool _available = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _price.text = p.price.toString();
      _category.text = p.category ?? '';
      _description.text = p.description ?? '';
      _imageUrl.text = p.imageUrl ?? '';
      _available = p.isAvailable;
    }
  }

  Future<void> _pick() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (img != null) setState(() => _picked = img);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? imageUrl =
          _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim();

      if (_picked != null) {
        final uploaded = await SupabaseService.instance.uploadProductImage(
          file: _picked!,
          productName: _name.text.trim(),
        );
        if (uploaded != null) imageUrl = uploaded;
      }

      final product = Product(
        id: widget.product?.id ?? 0,
        name: _name.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        price: double.parse(_price.text.trim()),
        category: _category.text.trim().isEmpty ? null : _category.text.trim(),
        imageUrl: imageUrl,
        isAvailable: _available,
      );

      if (widget.product == null) {
        await SupabaseService.instance.addProduct(product);
      } else {
        await SupabaseService.instance.updateProduct(product);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: _saving
          ? const LoadingWidget(message: 'Saving...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pick,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: _previewBox(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price *'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'e.g. Coffee, Tea, Desserts',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imageUrl,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (optional)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _available,
                      activeColor: AppColors.success,
                      title: const Text('Available for ordering'),
                      onChanged: (v) => setState(() => _available = v),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(
                          widget.product == null
                              ? 'Add Product'
                              : 'Save Changes',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _previewBox() {
    if (_picked != null) {
      if (kIsWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            _picked!.path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        );
      }
      return _placeholder(
        icon: Icons.check_circle,
        color: AppColors.success,
        text: 'Image selected',
      );
    }
    if (_imageUrl.text.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          _imageUrl.text,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({
    IconData icon = Icons.add_photo_alternate,
    Color color = AppColors.latte,
    String text = 'Tap to add image',
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 6),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _category.dispose();
    _description.dispose();
    _imageUrl.dispose();
    super.dispose();
  }
}
