import 'package:flutter_test/flutter_test.dart';
import 'package:frankie_vendor/core/utils/currency_utils.dart';
import 'package:frankie_vendor/core/utils/whatsapp_formatter.dart';
import 'package:frankie_vendor/features/providers.dart';
import 'package:frankie_vendor/models/models.dart';

void main() {
  group('CurrencyUtils Tests', () {
    test('formats rupees correctly', () {
      final formatted = CurrencyUtils.format(120.50);
      expect(formatted, contains('120.50'));
    });

    test('formats quantity correctly without trailing decimal for integers', () {
      expect(CurrencyUtils.formatQty(2.0), '2');
      expect(CurrencyUtils.formatQty(2.5), '2.5');
    });
  });

  group('CartState Calculations Tests', () {
    test('calculates subtotal and grand total with tax accurately', () {
      const cart = CartState(
        items: [
          DraftCartItem(
            id: '1',
            name: 'VEG FRANKIE',
            unitPrice: 60.0,
            quantity: 2.0,
          ),
          DraftCartItem(
            id: '2',
            name: 'COLD DRINK',
            unitPrice: 40.0,
            quantity: 1.0,
          ),
        ],
        discount: 10.0,
      );

      // Subtotal = (60 * 2) + (40 * 1) = 120 + 40 = 160.0
      expect(cart.subtotal, 160.0);

      // Taxable = 160 - 10 = 150.0; Tax at 5% = 7.5
      expect(cart.calculateTax(5.0), 7.5);

      // Grand total = 150.0 + 7.5 = 157.5
      expect(cart.calculateGrandTotal(5.0), 157.5);
    });
  });

  group('WhatsAppFormatter Tests', () {
    test('generates formatted bill text with shop details and items', () {
      const shop = ShopSettings(
        shopName: 'FRANKIE CORNER',
        phone: '9876543210',
        currency: '₹',
        footerNote: 'Visit Again!',
      );

      const invoice = Invoice(
        invoiceNumber: 'INV-20260903-001',
        customerName: 'RAHUL SHARMA',
        customerPhone: '9876543210',
        subtotal: 120.0,
        grandTotal: 120.0,
        paymentMode: 'UPI',
        createdAt: '2026-09-03 12:00:00',
      );

      const items = [
        InvoiceItem(
          invoiceId: 1,
          itemName: 'CHEESE FRANKIE',
          quantity: 1.0,
          unitPrice: 90.0,
          lineTotal: 90.0,
        ),
        InvoiceItem(
          invoiceId: 1,
          itemName: 'EXTRA CHEESE',
          quantity: 1.0,
          unitPrice: 30.0,
          lineTotal: 30.0,
        ),
      ];

      final text = WhatsAppFormatter.generateBillText(
        shopSettings: shop,
        invoice: invoice,
        items: items,
      );

      expect(text, contains('FRANKIE CORNER'));
      expect(text, contains('INV-20260903-001'));
      expect(text, contains('CHEESE FRANKIE'));
      expect(text, contains('EXTRA CHEESE'));
      expect(text, contains('TOTAL AMOUNT: ₹120.00'));
      expect(text, contains('Visit Again!'));
    });
  });
}
