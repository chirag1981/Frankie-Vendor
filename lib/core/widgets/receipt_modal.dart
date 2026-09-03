import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../utils/currency_utils.dart';
import '../utils/pdf_invoice_generator.dart';

class ReceiptModal extends StatelessWidget {
  final ShopSettings shopSettings;
  final Invoice invoice;
  final List<InvoiceItem> items;
  final VoidCallback? onClose;

  const ReceiptModal({
    super.key,
    required this.shopSettings,
    required this.invoice,
    required this.items,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required ShopSettings shopSettings,
    required Invoice invoice,
    required List<InvoiceItem> items,
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReceiptModal(
        shopSettings: shopSettings,
        invoice: invoice,
        items: items,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = shopSettings.currency.isEmpty ? '₹' : shopSettings.currency;

    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scrollable Receipt Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Receipt Header
                  const Center(
                    child: Icon(Icons.receipt_long_rounded,
                        size: 36, color: Color(0xFFE65100)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shopSettings.shopName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  if (shopSettings.phone.isNotEmpty)
                    Text(
                      'Ph: ${shopSettings.phone}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  if (shopSettings.address.isNotEmpty)
                    Text(
                      shopSettings.address,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),

                  const SizedBox(height: 12),
                  _buildDashedLine(),
                  const SizedBox(height: 12),

                  // Metadata
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice: ${invoice.invoiceNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        invoice.createdAt,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (invoice.customerName.isNotEmpty &&
                      invoice.customerName != 'VALUED CUSTOMER') ...[
                    const SizedBox(height: 4),
                    Text(
                      'Customer: ${invoice.customerName} (${invoice.customerPhone})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                  ],

                  const SizedBox(height: 12),
                  _buildDashedLine(),
                  const SizedBox(height: 10),

                  // Items Header
                  Row(
                    children: const [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'ITEM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'QTY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'AMOUNT',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Items List
                  ...items.map((item) {
                    final qtyStr = CurrencyUtils.formatQty(item.quantity);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              qtyStr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              CurrencyUtils.format(item.lineTotal, currency),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 10),
                  _buildDashedLine(),
                  const SizedBox(height: 10),

                  // Totals
                  _buildTotalRow('Subtotal', CurrencyUtils.format(invoice.subtotal, currency)),
                  if (invoice.discount > 0)
                    _buildTotalRow('Discount', '-${CurrencyUtils.format(invoice.discount, currency)}',
                        isDiscount: true),
                  if (invoice.tax > 0)
                    _buildTotalRow('Tax', '+${CurrencyUtils.format(invoice.tax, currency)}'),

                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'GRAND TOTAL',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        Text(
                          CurrencyUtils.format(invoice.grandTotal, currency),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'Paid via ${invoice.paymentMode}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (shopSettings.footerNote.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      shopSettings.footerNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Quick Save PDF Only Button
                IconButton.filledTonal(
                  tooltip: 'Save PDF to Phone',
                  onPressed: () async {
                    try {
                      final path = await PdfInvoiceGenerator.saveInvoicePdfToDownloads(
                        shopSettings: shopSettings,
                        invoice: invoice,
                        items: items,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📁 Invoice PDF saved to Downloads!\n$path'),
                            backgroundColor: const Color(0xFFE65100),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving PDF: $e'),
                            backgroundColor: Colors.red.shade800,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded, color: Color(0xFFE65100)),
                ),
                const SizedBox(width: 8),

                // Primary "Save & Send to WhatsApp" Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final path = await PdfInvoiceGenerator.saveAndSendToWhatsApp(
                          shopSettings: shopSettings,
                          invoice: invoice,
                          items: items,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Invoice saved to Downloads and shared to WhatsApp!\n$path'),
                              backgroundColor: const Color(0xFF2E7D32),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red.shade800,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Save & Send to WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Print Icon Button (Optional / Hardware thermal printer)
                IconButton.outlined(
                  tooltip: 'Thermal Print',
                  onPressed: () {
                    PdfInvoiceGenerator.printReceipt(
                      shopSettings: shopSettings,
                      invoice: invoice,
                      items: items,
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 20, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade400),
              ),
            );
          }),
        );
      },
    );
  }
}
