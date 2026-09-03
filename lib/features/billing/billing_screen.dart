import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/widgets/receipt_modal.dart';
import '../../models/models.dart';
import '../providers.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  String _selectedCategory = 'ALL';

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogListProvider);
    final cart = ref.watch(billingCartProvider);
    final settingsAsync = ref.watch(shopSettingsProvider);
    final currency = settingsAsync.value?.currency ?? '₹';
    final taxPercent = settingsAsync.value?.taxPercent ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.point_of_sale_rounded,
                  color: Color(0xFFE65100), size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Billing POS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(
                  settingsAsync.value?.shopName ?? 'FRANKIE CORNER',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add Custom Item',
            icon: const Icon(Icons.add_shopping_cart_rounded),
            onPressed: () => _showAddCustomItemDialog(context),
          ),
          if (cart.items.isNotEmpty)
            IconButton(
              tooltip: 'Clear Cart',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () {
                ref.read(billingCartProvider.notifier).clearCart();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Category selector
          _buildCategoryFilter(catalogAsync.value ?? []),

          // Food Catalog Items Grid
          Expanded(
            child: catalogAsync.when(
              data: (items) {
                final filtered = items.where((item) {
                  if (!item.isActive) return false;
                  if (_selectedCategory == 'ALL') return true;
                  return item.category == _selectedCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fastfood_outlined,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No items in $_selectedCategory',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.25,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final cartQty = _getCartQty(cart.items, item.id);

                    return _buildMenuItemCard(item, cartQty, currency);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),

      // Bottom Bar with Running Total & Checkout Trigger
      bottomSheet: cart.items.isNotEmpty
          ? _buildBottomCartBar(context, cart, currency, taxPercent)
          : null,
    );
  }

  double _getCartQty(List<DraftCartItem> cartItems, int? catalogId) {
    if (catalogId == null) return 0;
    final found = cartItems.where((i) => i.catalogItemId == catalogId);
    if (found.isEmpty) return 0;
    return found.first.quantity;
  }

  Widget _buildCategoryFilter(List<CatalogItem> allItems) {
    final categories = <String>{'ALL'};
    for (final item in allItems) {
      if (item.category.isNotEmpty) {
        categories.add(item.category);
      }
    }

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories.elementAt(index);
          final isSelected = _selectedCategory == cat;

          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            selectedColor: const Color(0xFFE65100),
            backgroundColor: Theme.of(context).cardColor,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedCategory = cat);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuItemCard(CatalogItem item, double cartQty, String currency) {
    final hasQty = cartQty > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ref.read(billingCartProvider.notifier).addCatalogItem(item);
      },
      child: Card(
        color: hasQty ? const Color(0xFFFFF8E1) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: hasQty ? const Color(0xFFE65100) : Colors.grey.shade300,
            width: hasQty ? 1.8 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  if (hasQty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x${CurrencyUtils.formatQty(cartQty)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyUtils.format(item.price, currency),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCartBar(
    BuildContext context,
    CartState cart,
    String currency,
    double taxPercent,
  ) {
    final grandTotal = cart.calculateGrandTotal(taxPercent);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cart.totalItemCount} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  CurrencyUtils.format(grandTotal, currency),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCartSheet(context, taxPercent),
                icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                label: const Text('Review & Pay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartSheet(BuildContext context, double taxPercent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final cart = ref.watch(billingCartProvider);
          final settings = ref.watch(shopSettingsProvider).value ?? const ShopSettings();
          final currency = settings.currency;
          final grandTotal = cart.calculateGrandTotal(taxPercent);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Bill',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Cart items list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  CurrencyUtils.format(item.unitPrice, currency),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Qty controls
                          Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 22, color: Color(0xFFE65100)),
                                onPressed: () {
                                  ref
                                      .read(billingCartProvider.notifier)
                                      .updateQuantity(item.id, -1);
                                },
                              ),
                              Text(
                                CurrencyUtils.formatQty(item.quantity),
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 22, color: Color(0xFFE65100)),
                                onPressed: () {
                                  ref
                                      .read(billingCartProvider.notifier)
                                      .updateQuantity(item.id, 1);
                                },
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              CurrencyUtils.format(item.lineTotal, currency),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Customer & Payment inputs
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Customer Name',
                                isDense: true,
                                prefixIcon: Icon(Icons.person_outline, size: 18),
                              ),
                              onChanged: (val) {
                                ref
                                    .read(billingCartProvider.notifier)
                                    .updateCustomerDetails(name: val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Phone (WhatsApp)',
                                isDense: true,
                                prefixIcon: Icon(Icons.phone_outlined, size: 18),
                              ),
                              onChanged: (val) {
                                ref
                                    .read(billingCartProvider.notifier)
                                    .updateCustomerDetails(phone: val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Payment Mode Choice
                      Row(
                        children: [
                          const Text('Payment: ',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          ...['Cash', 'UPI', 'Card'].map((mode) {
                            final isSel = cart.paymentMode == mode;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(mode),
                                selected: isSel,
                                selectedColor: const Color(0xFF2E7D32),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: isSel ? Colors.white : Colors.black87,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                ),
                                onSelected: (_) {
                                  ref
                                      .read(billingCartProvider.notifier)
                                      .updatePaymentMode(mode);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Bill Totals
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          Text(CurrencyUtils.format(cart.subtotal, currency),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (taxPercent > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tax ($taxPercent%)',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            Text(
                              '+${CurrencyUtils.format(cart.calculateTax(taxPercent), currency)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GRAND TOTAL',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(
                            CurrencyUtils.format(grandTotal, currency),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Generate Invoice Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final savedInvoiceWithItems = await ref
                                .read(billingCartProvider.notifier)
                                .checkout(taxPercent);

                            if (context.mounted) {
                              Navigator.pop(context); // Close cart sheet
                              ReceiptModal.show(
                                context,
                                shopSettings: settings,
                                invoice: savedInvoiceWithItems.invoice,
                                items: savedInvoiceWithItems.items,
                              );
                            }
                          },
                          child: const Text(
                            'Save & Generate Receipt',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
    );
  }

  void _showAddCustomItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Item',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g. EXTRA CHEESE DIP',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixText: '₹ ',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim().toUpperCase();
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
              final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;

              if (name.isNotEmpty && price > 0) {
                ref
                    .read(billingCartProvider.notifier)
                    .addCustomItem(name, price, qty);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}
