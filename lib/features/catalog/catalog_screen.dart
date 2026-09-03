import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/models.dart';
import '../providers.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogListProvider);
    final settingsAsync = ref.watch(shopSettingsProvider);
    final currency = settingsAsync.value?.currency ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Catalog',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Add New Food Item',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAddEditDialog(context, ref),
          ),
        ],
      ),
      body: catalogAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu,
                      size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No items in catalog',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Item'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE65100).withValues(alpha: 0.12),
                    child: Text(
                      item.name.isNotEmpty ? item.name[0] : 'F',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration:
                                item.isActive ? null : TextDecoration.lineThrough,
                            color: item.isActive
                                ? Colors.black87
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    CurrencyUtils.format(item.price, currency),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE65100),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: item.isActive,
                        activeThumbColor: const Color(0xFFE65100),
                        onChanged: (val) {
                          ref
                              .read(catalogListProvider.notifier)
                              .updateItem(item.copyWith(isActive: val));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () =>
                            _showAddEditDialog(context, ref, item: item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, ref),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Item', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      {CatalogItem? item}) {
    final isEditing = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl =
        TextEditingController(text: item != null ? item.price.toStringAsFixed(2) : '');
    String category = item?.category ?? 'FRANKIE';

    final categories = ['FRANKIE', 'BEVERAGE', 'SNACKS', 'EXTRA', 'GENERAL'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Item' : 'Add Food Item',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g. PERI PERI FRANKIE',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price (₹)',
                    hintText: 'e.g. 80.00',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => category = val);
                  },
                ),
              ],
            ),
            actions: [
              if (isEditing)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    ref.read(catalogListProvider.notifier).deleteItem(item.id!);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Delete'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim().toUpperCase();
                  final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;

                  if (name.isNotEmpty && price > 0) {
                    if (isEditing) {
                      ref.read(catalogListProvider.notifier).updateItem(
                            item.copyWith(
                              name: name,
                              price: price,
                              category: category,
                            ),
                          );
                    } else {
                      ref
                          .read(catalogListProvider.notifier)
                          .addItem(name, price, category);
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Add Item'),
              ),
            ],
          );
        },
      ),
    );
  }
}
