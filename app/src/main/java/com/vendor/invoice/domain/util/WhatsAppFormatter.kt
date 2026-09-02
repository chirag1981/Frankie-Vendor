package com.vendor.invoice.domain.util

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.vendor.invoice.data.local.entity.InvoiceEntity
import com.vendor.invoice.data.local.entity.InvoiceItemEntity
import com.vendor.invoice.data.local.entity.ShopSettingsEntity
import java.net.URLEncoder

object WhatsAppFormatter {

    fun generateWhatsAppBillText(
        shopSettings: ShopSettingsEntity,
        invoice: InvoiceEntity,
        items: List<InvoiceItemEntity>
    ): String {
        val shopName = shopSettings.shopName.uppercase().ifEmpty { "OUR SHOP" }
        val phone = shopSettings.phone.trim()
        val footerNote = shopSettings.footerNote.trim()
        val currency = shopSettings.currency.ifEmpty { "₹" }

        val invNumber = invoice.invoiceNumber
        val dateStr = invoice.createdAt
        val custName = invoice.customerName.trim()
        val paymentMode = invoice.paymentMode
        val subtotal = invoice.subtotal
        val discount = invoice.discount
        val grandTotal = invoice.grandTotal

        val lines = mutableListOf<String>()
        lines.add("🧾 *$shopName*")
        if (phone.isNotEmpty()) {
            lines.add("📞 Contact: $phone")
        }
        lines.add("────────────────────────")
        lines.add("📄 *Invoice #:* $invNumber")
        if (dateStr.isNotEmpty()) {
            lines.add("📅 *Date:* $dateStr")
        }
        if (custName.isNotEmpty() && custName != "VALUED CUSTOMER") {
            lines.add("👤 *Customer:* $custName")
        }
        lines.add("────────────────────────")
        lines.add("*ITEMS & CHARGES:*")

        items.forEachIndexed { index, item ->
            val qtyStr = CurrencyUtils.formatQty(item.quantity)
            val priceStr = String.format(java.util.Locale.US, "%.2f", item.unitPrice)
            val totalStr = String.format(java.util.Locale.US, "%.2f", item.lineTotal)
            lines.add("${index + 1}. ${item.itemName}")
            lines.add("   $qtyStr x $currency$priceStr = *$currency$totalStr*")
        }

        lines.add("────────────────────────")
        lines.add("Subtotal: $currency${String.format(java.util.Locale.US, "%.2f", subtotal)}")
        if (discount > 0) {
            lines.add("Discount: -$currency${String.format(java.util.Locale.US, "%.2f", discount)}")
        }
        lines.add("💰 *TOTAL AMOUNT: $currency${String.format(java.util.Locale.US, "%.2f", grandTotal)}*")
        lines.add("💳 Payment Mode: $paymentMode")

        if (footerNote.isNotEmpty()) {
            lines.add("")
            lines.add("✨ _${footerNote}_")
        }

        return lines.joinToString("\n")
    }

    fun launchWhatsApp(context: Context, phone: String, message: String) {
        var cleanPhone = phone.filter { it.isDigit() }
        if (cleanPhone.length == 10) {
            cleanPhone = "91$cleanPhone"
        }

        val encodedMsg = try {
            URLEncoder.encode(message, "UTF-8")
        } catch (e: Exception) {
            Uri.encode(message)
        }

        val url = if (cleanPhone.isNotEmpty()) {
            "https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMsg"
        } else {
            "https://api.whatsapp.com/send?text=$encodedMsg"
        }

        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            // Fallback: Copy to clipboard and open general share sheet
            copyToClipboard(context, message)
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, message)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(Intent.createChooser(shareIntent, "Share Bill"))
        }
    }

    fun copyToClipboard(context: Context, text: String) {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("Invoice Receipt", text)
        clipboard.setPrimaryClip(clip)
    }
}
