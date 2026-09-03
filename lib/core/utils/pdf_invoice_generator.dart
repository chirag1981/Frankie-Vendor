import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import 'currency_utils.dart';
import 'whatsapp_formatter.dart';

class PdfInvoiceGenerator {
  static Future<Uint8List> generateInvoicePdf({
    required ShopSettings shopSettings,
    required Invoice invoice,
    required List<InvoiceItem> items,
  }) async {
    pw.ThemeData? theme;
    bool hasUnicodeRupee = false;

    try {
      final regularFont = await PdfGoogleFonts.notoSansDevanagariRegular();
      final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
      theme = pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      );
      hasUnicodeRupee = true;
    } catch (_) {
      // Offline fallback: Use standard Helvetica with 'Rs. ' so it never displays ☒
    }

    final pdf = pw.Document(theme: theme);

    final shopName = shopSettings.shopName.toUpperCase().isEmpty
        ? 'FRANKIE CORNER'
        : shopSettings.shopName.toUpperCase();

    // Use ₹ if Indian font is loaded, otherwise use 'Rs. ' to avoid missing glyph [X]
    final currency = hasUnicodeRupee
        ? (shopSettings.currency.isEmpty ? '₹' : shopSettings.currency)
        : 'Rs. ';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                shopName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (shopSettings.phone.isNotEmpty)
                pw.Text(
                  'Ph: ${shopSettings.phone}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              if (shopSettings.address.isNotEmpty)
                pw.Text(
                  shopSettings.address,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.8),

              // Invoice Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Inv: ${invoice.invoiceNumber}',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(invoice.createdAt.split(' ').first,
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (invoice.customerName.isNotEmpty &&
                  invoice.customerName != 'VALUED CUSTOMER')
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Cust: ${invoice.customerName}',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              pw.Divider(thickness: 0.8),

              // Items Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text('ITEM',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('QTY',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('TOTAL',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // Item rows
              ...items.map((item) {
                final qtyStr = CurrencyUtils.formatQty(item.quantity);
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(item.itemName,
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(qtyStr,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                            '$currency${item.lineTotal.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 0.8),

              // Subtotal & Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('$currency${invoice.subtotal.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (invoice.discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('-$currency${invoice.discount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              if (invoice.tax > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('+$currency${invoice.tax.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              pw.SizedBox(height: 3),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('$currency${invoice.grandTotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('Paid via: ${invoice.paymentMode}',
                    style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.SizedBox(height: 8),

              // Footer Note
              if (shopSettings.footerNote.isNotEmpty)
                pw.Text(
                  shopSettings.footerNote,
                  style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center,
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Saves the PDF invoice directly to the device's Downloads directory (or app documents)
  static Future<String> saveInvoicePdfToDownloads({
    required ShopSettings shopSettings,
    required Invoice invoice,
    required List<InvoiceItem> items,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      shopSettings: shopSettings,
      invoice: invoice,
      items: items,
    );

    final fileName = 'Invoice_${invoice.invoiceNumber}.pdf';

    // 1. Try public Download folder on Android
    final downloadDir = Directory('/storage/emulated/0/Download');
    if (await downloadDir.exists()) {
      try {
        final target = File('${downloadDir.path}/$fileName');
        await target.writeAsBytes(pdfBytes);
        return target.path;
      } catch (_) {}
    }

    // 2. Fallback to app documents
    final docDir = await getApplicationDocumentsDirectory();
    final file = File('${docDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Saves the invoice to storage and sends/shares to WhatsApp
  static Future<String> saveAndSendToWhatsApp({
    required ShopSettings shopSettings,
    required Invoice invoice,
    required List<InvoiceItem> items,
  }) async {
    // 1. Save PDF file
    final savedPath = await saveInvoicePdfToDownloads(
      shopSettings: shopSettings,
      invoice: invoice,
      items: items,
    );

    // 2. Generate formatted WhatsApp receipt text
    final billText = WhatsAppFormatter.generateBillText(
      shopSettings: shopSettings,
      invoice: invoice,
      items: items,
    );

    // 3. Share the PDF document and bill text directly to WhatsApp
    await Share.shareXFiles(
      [XFile(savedPath, mimeType: 'application/pdf', name: 'Invoice_${invoice.invoiceNumber}.pdf')],
      text: billText,
      subject: 'Invoice ${invoice.invoiceNumber}',
    );

    return savedPath;
  }

  static Future<void> printReceipt({
    required ShopSettings shopSettings,
    required Invoice invoice,
    required List<InvoiceItem> items,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      shopSettings: shopSettings,
      invoice: invoice,
      items: items,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}',
    );
  }
}
