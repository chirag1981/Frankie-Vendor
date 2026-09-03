import 'package:flutter/foundation.dart';

@immutable
class CatalogItem {
  final int? id;
  final String name;
  final double price;
  final String category;
  final bool isActive;
  final String createdAt;

  const CatalogItem({
    this.id,
    required this.name,
    required this.price,
    this.category = 'GENERAL',
    this.isActive = true,
    this.createdAt = '',
  });

  CatalogItem copyWith({
    int? id,
    String? name,
    double? price,
    String? category,
    bool? isActive,
    String? createdAt,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name.toUpperCase().trim(),
      'price': price,
      'category': category.toUpperCase().trim(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory CatalogItem.fromMap(Map<String, dynamic> map) {
    return CatalogItem(
      id: map['id'] as int?,
      name: (map['name'] as String? ?? '').toUpperCase(),
      price: (map['price'] as num? ?? 0.0).toDouble(),
      category: (map['category'] as String? ?? 'GENERAL').toUpperCase(),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}

@immutable
class Invoice {
  final int? id;
  final String invoiceNumber;
  final String customerName;
  final String customerPhone;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final String paymentMode;
  final String createdAt;

  const Invoice({
    this.id,
    required this.invoiceNumber,
    this.customerName = '',
    this.customerPhone = '',
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    this.paymentMode = 'Cash',
    required this.createdAt,
  });

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    String? customerName,
    String? customerPhone,
    double? subtotal,
    double? discount,
    double? tax,
    double? grandTotal,
    String? paymentMode,
    String? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMode: paymentMode ?? this.paymentMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'customer_name': customerName.toUpperCase().trim(),
      'customer_phone': customerPhone.trim(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'grand_total': grandTotal,
      'payment_mode': paymentMode,
      'created_at': createdAt,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? '',
      customerPhone: map['customer_phone'] as String? ?? '',
      subtotal: (map['subtotal'] as num? ?? 0.0).toDouble(),
      discount: (map['discount'] as num? ?? 0.0).toDouble(),
      tax: (map['tax'] as num? ?? 0.0).toDouble(),
      grandTotal: (map['grand_total'] as num? ?? 0.0).toDouble(),
      paymentMode: map['payment_mode'] as String? ?? 'Cash',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}

@immutable
class InvoiceItem {
  final int? id;
  final int invoiceId;
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  const InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_id': invoiceId,
      'item_name': itemName.toUpperCase().trim(),
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int? ?? 0,
      itemName: (map['item_name'] as String? ?? '').toUpperCase(),
      quantity: (map['quantity'] as num? ?? 1.0).toDouble(),
      unitPrice: (map['unit_price'] as num? ?? 0.0).toDouble(),
      lineTotal: (map['line_total'] as num? ?? 0.0).toDouble(),
    );
  }
}

@immutable
class InvoiceWithItems {
  final Invoice invoice;
  final List<InvoiceItem> items;

  const InvoiceWithItems({
    required this.invoice,
    required this.items,
  });
}

@immutable
class DraftCartItem {
  final String id;
  final int? catalogItemId;
  final String name;
  final double unitPrice;
  final double quantity;
  final String category;

  const DraftCartItem({
    required this.id,
    this.catalogItemId,
    required this.name,
    required this.unitPrice,
    this.quantity = 1.0,
    this.category = 'GENERAL',
  });

  double get lineTotal => quantity * unitPrice;

  DraftCartItem copyWith({
    String? id,
    int? catalogItemId,
    String? name,
    double? unitPrice,
    double? quantity,
    String? category,
  }) {
    return DraftCartItem(
      id: id ?? this.id,
      catalogItemId: catalogItemId ?? this.catalogItemId,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
    );
  }
}

@immutable
class ShopSettings {
  final int id;
  final String shopName;
  final String phone;
  final String address;
  final String upiId;
  final String currency;
  final double taxPercent;
  final String footerNote;
  final String updatedAt;

  const ShopSettings({
    this.id = 1,
    this.shopName = 'FRANKIE CORNER',
    this.phone = '9876543210',
    this.address = 'Food Street, Market Road',
    this.upiId = '',
    this.currency = '₹',
    this.taxPercent = 0.0,
    this.footerNote = 'Fresh & Delicious! Visit Again!',
    this.updatedAt = '',
  });

  ShopSettings copyWith({
    int? id,
    String? shopName,
    String? phone,
    String? address,
    String? upiId,
    String? currency,
    double? taxPercent,
    String? footerNote,
    String? updatedAt,
  }) {
    return ShopSettings(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      upiId: upiId ?? this.upiId,
      currency: currency ?? this.currency,
      taxPercent: taxPercent ?? this.taxPercent,
      footerNote: footerNote ?? this.footerNote,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_name': shopName.toUpperCase().trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'upi_id': upiId.trim(),
      'currency': currency.trim(),
      'tax_percent': taxPercent,
      'footer_note': footerNote.trim(),
      'updated_at': updatedAt,
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      id: map['id'] as int? ?? 1,
      shopName: (map['shop_name'] as String? ?? 'FRANKIE CORNER').toUpperCase(),
      phone: map['phone'] as String? ?? '9876543210',
      address: map['address'] as String? ?? 'Food Street, Market Road',
      upiId: map['upi_id'] as String? ?? '',
      currency: map['currency'] as String? ?? '₹',
      taxPercent: (map['tax_percent'] as num? ?? 0.0).toDouble(),
      footerNote: map['footer_note'] as String? ?? 'Fresh & Delicious! Visit Again!',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}

@immutable
class SalesSummary {
  final int totalBills;
  final double totalSales;
  final int todayBills;
  final double todaySales;

  const SalesSummary({
    this.totalBills = 0,
    this.totalSales = 0.0,
    this.todayBills = 0,
    this.todaySales = 0.0,
  });
}
