import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/database/database_helper.dart';
import '../models/models.dart';

// Database Instance Provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// Shop Settings Provider
final shopSettingsProvider = AsyncNotifierProvider<ShopSettingsNotifier, ShopSettings>(() {
  return ShopSettingsNotifier();
});

class ShopSettingsNotifier extends AsyncNotifier<ShopSettings> {
  @override
  Future<ShopSettings> build() async {
    final db = ref.watch(databaseHelperProvider);
    return await db.getShopSettings();
  }

  Future<void> updateSettings(ShopSettings newSettings) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseHelperProvider);
      await db.updateShopSettings(newSettings);
      return newSettings;
    });
  }
}

// Catalog Provider
final catalogListProvider = AsyncNotifierProvider<CatalogListNotifier, List<CatalogItem>>(() {
  return CatalogListNotifier();
});

class CatalogListNotifier extends AsyncNotifier<List<CatalogItem>> {
  @override
  Future<List<CatalogItem>> build() async {
    final db = ref.watch(databaseHelperProvider);
    return await db.getCatalogItems();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseHelperProvider);
      return await db.getCatalogItems();
    });
  }

  Future<void> addItem(String name, double price, String category) async {
    final db = ref.read(databaseHelperProvider);
    await db.insertCatalogItem(CatalogItem(
      name: name,
      price: price,
      category: category,
      isActive: true,
    ));
    await refresh();
  }

  Future<void> updateItem(CatalogItem item) async {
    final db = ref.read(databaseHelperProvider);
    await db.updateCatalogItem(item);
    await refresh();
  }

  Future<void> deleteItem(int id) async {
    final db = ref.read(databaseHelperProvider);
    await db.deleteCatalogItem(id);
    await refresh();
  }
}

// Billing Cart State
class CartState {
  final List<DraftCartItem> items;
  final String customerName;
  final String customerPhone;
  final double discount;
  final String paymentMode;

  const CartState({
    this.items = const [],
    this.customerName = '',
    this.customerPhone = '',
    this.discount = 0.0,
    this.paymentMode = 'Cash',
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double calculateTax(double taxPercent) {
    if (taxPercent <= 0) return 0.0;
    final taxable = (subtotal - discount).clamp(0.0, double.infinity);
    return (taxable * taxPercent) / 100.0;
  }

  double calculateGrandTotal(double taxPercent) {
    final afterDiscount = (subtotal - discount).clamp(0.0, double.infinity);
    return afterDiscount + calculateTax(taxPercent);
  }

  int get totalItemCount => items.fold(0, (count, item) => count + item.quantity.toInt());

  CartState copyWith({
    List<DraftCartItem>? items,
    String? customerName,
    String? customerPhone,
    double? discount,
    String? paymentMode,
  }) {
    return CartState(
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      discount: discount ?? this.discount,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }
}

final billingCartProvider = NotifierProvider<BillingCartNotifier, CartState>(() {
  return BillingCartNotifier();
});

class BillingCartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  void addCatalogItem(CatalogItem item) {
    final existingIndex = state.items.indexWhere((i) => i.catalogItemId == item.id);
    if (existingIndex >= 0) {
      final current = state.items[existingIndex];
      final updated = current.copyWith(quantity: current.quantity + 1);
      final newItems = List<DraftCartItem>.from(state.items);
      newItems[existingIndex] = updated;
      state = state.copyWith(items: newItems);
    } else {
      final newItem = DraftCartItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        catalogItemId: item.id,
        name: item.name,
        unitPrice: item.price,
        quantity: 1,
        category: item.category,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void addCustomItem(String name, double price, double quantity) {
    final newItem = DraftCartItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      unitPrice: price,
      quantity: quantity,
      category: 'CUSTOM',
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void updateQuantity(String id, double delta) {
    final index = state.items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final item = state.items[index];
      final newQty = item.quantity + delta;
      final newItems = List<DraftCartItem>.from(state.items);
      if (newQty <= 0) {
        newItems.removeAt(index);
      } else {
        newItems[index] = item.copyWith(quantity: newQty);
      }
      state = state.copyWith(items: newItems);
    }
  }

  void removeItem(String id) {
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
  }

  void updateCustomerDetails({String? name, String? phone}) {
    state = state.copyWith(
      customerName: name ?? state.customerName,
      customerPhone: phone ?? state.customerPhone,
    );
  }

  void updateDiscount(double discount) {
    state = state.copyWith(discount: discount.clamp(0.0, state.subtotal));
  }

  void updatePaymentMode(String mode) {
    state = state.copyWith(paymentMode: mode);
  }

  void clearCart() {
    state = const CartState();
  }

  Future<InvoiceWithItems> checkout(double taxPercent) async {
    final db = ref.read(databaseHelperProvider);
    final invNumber = await db.generateNextInvoiceNumber();
    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final subtotal = state.subtotal;
    final discount = state.discount;
    final tax = state.calculateTax(taxPercent);
    final grandTotal = state.calculateGrandTotal(taxPercent);

    final invoice = Invoice(
      invoiceNumber: invNumber,
      customerName: state.customerName.trim().isEmpty
          ? 'VALUED CUSTOMER'
          : state.customerName.trim().toUpperCase(),
      customerPhone: state.customerPhone.trim(),
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      grandTotal: grandTotal,
      paymentMode: state.paymentMode,
      createdAt: nowStr,
    );

    final saved = await db.saveInvoice(
      invoice: invoice,
      cartItems: state.items,
    );

    // Refresh history
    ref.invalidate(invoicesHistoryProvider);
    ref.invalidate(salesSummaryProvider);

    // Reset cart
    clearCart();

    return saved;
  }
}

// Invoices History Provider
final invoicesHistoryProvider = AsyncNotifierProvider<InvoicesHistoryNotifier, List<InvoiceWithItems>>(() {
  return InvoicesHistoryNotifier();
});

class InvoicesHistoryNotifier extends AsyncNotifier<List<InvoiceWithItems>> {
  String _searchQuery = '';
  String? _dateFilter;

  @override
  Future<List<InvoiceWithItems>> build() async {
    final db = ref.watch(databaseHelperProvider);
    return await db.getInvoices(
      searchQuery: _searchQuery,
      dateFilter: _dateFilter,
    );
  }

  Future<void> filter({String? query, String? date}) async {
    _searchQuery = query ?? _searchQuery;
    _dateFilter = date ?? _dateFilter;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseHelperProvider);
      return await db.getInvoices(
        searchQuery: _searchQuery,
        dateFilter: _dateFilter,
      );
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseHelperProvider);
      return await db.getInvoices(
        searchQuery: _searchQuery,
        dateFilter: _dateFilter,
      );
    });
  }
}

// Sales Summary Provider
final salesSummaryProvider = FutureProvider<SalesSummary>((ref) async {
  final db = ref.watch(databaseHelperProvider);
  return await db.getSalesSummary();
});
