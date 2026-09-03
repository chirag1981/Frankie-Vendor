import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/models.dart';
import 'currency_utils.dart';

class PdfInvoiceGenerator {
  static Future<Uint8List> generateInvoicePdf({
    required ShopSettings shopSettings,
    required Invoice invoice,
    required List<InvoiceItem> items,
  }) async {
    final pdf = pw.Document();

    final shopName = shopSettings.shopName.toUpperCase().isEmpty
        ? 'FRANKIE CORNER'
        : shopSettings.shopName.toUpperCase();
    final currency = shopSettings.currency.isEmpty ? '₹' : shopSettings.currency;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
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
