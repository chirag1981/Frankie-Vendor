import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import 'currency_utils.dart';

class WhatsAppFormatter {
  static String generateBillText({
    required ShopSettings shopSettings,
    required Invoice invoice,
    required List<InvoiceItem> items,
  }) {
    final shopName = shopSettings.shopName.toUpperCase().isEmpty
        ? 'FRANKIE CORNER'
        : shopSettings.shopName.toUpperCase();
    final phone = shopSettings.phone.trim();
    final footerNote = shopSettings.footerNote.trim();
    final currency = shopSettings.currency.isEmpty ? '₹' : shopSettings.currency;

    final buffer = StringBuffer();
    buffer.writeln('🧾 *$shopName*');
    if (phone.isNotEmpty) {
      buffer.writeln('📞 Contact: $phone');
    }
    buffer.writeln('────────────────────────');
    buffer.writeln('📄 *Invoice #:* ${invoice.invoiceNumber}');
    if (invoice.createdAt.isNotEmpty) {
      buffer.writeln('📅 *Date:* ${invoice.createdAt}');
    }
    if (invoice.customerName.isNotEmpty &&
        invoice.customerName != 'VALUED CUSTOMER') {
      buffer.writeln('👤 *Customer:* ${invoice.customerName}');
    }
    buffer.writeln('────────────────────────');
    buffer.writeln('*ITEMS & CHARGES:*');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final qtyStr = CurrencyUtils.formatQty(item.quantity);
      final priceStr = item.unitPrice.toStringAsFixed(2);
      final totalStr = item.lineTotal.toStringAsFixed(2);
      buffer.writeln('${i + 1}. ${item.itemName}');
      buffer.writeln('   $qtyStr x $currency$priceStr = *$currency$totalStr*');
    }

    buffer.writeln('────────────────────────');
    buffer.writeln('Subtotal: $currency${invoice.subtotal.toStringAsFixed(2)}');
    if (invoice.discount > 0) {
      buffer.writeln('Discount: -$currency${invoice.discount.toStringAsFixed(2)}');
    }
    if (invoice.tax > 0) {
      buffer.writeln('Tax: +$currency${invoice.tax.toStringAsFixed(2)}');
    }
    buffer.writeln('💰 *TOTAL AMOUNT: $currency${invoice.grandTotal.toStringAsFixed(2)}*');
    buffer.writeln('💳 Payment Mode: ${invoice.paymentMode}');

    if (footerNote.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('✨ _${footerNote}_');
    }

    return buffer.toString();
  }

  static Future<bool> launchWhatsApp({
    required String phone,
    required String message,
  }) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final encodedMsg = Uri.encodeComponent(message);
    final Uri url = cleanPhone.isNotEmpty
        ? Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMsg')
        : Uri.parse('https://api.whatsapp.com/send?text=$encodedMsg');

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy to clipboard and invoke native share sheet
        await Clipboard.setData(ClipboardData(text: message));
        await Share.share(message, subject: 'Invoice Receipt');
        return true;
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: message));
      await Share.share(message, subject: 'Invoice Receipt');
      return true;
    }
  }
}
