package com.vendor.invoice

import com.vendor.invoice.data.local.entity.InvoiceEntity
import com.vendor.invoice.data.local.entity.InvoiceItemEntity
import com.vendor.invoice.data.local.entity.ShopSettingsEntity
import com.vendor.invoice.domain.util.WhatsAppFormatter
import org.junit.Assert.assertTrue
import org.junit.Test

class WhatsAppFormatterTest {

    @Test
    fun testWhatsAppBillFormatting() {
        val shop = ShopSettingsEntity(
            shopName = "FRANKIE CORNER",
            phone = "9876543210",
            footerNote = "Visit Again!",
            currency = "₹"
        )
        val invoice = InvoiceEntity(
            id = 1L,
            invoiceNumber = "INV-1001",
            customerName = "RAHUL SHARMA",
            customerPhone = "9876543210",
            subtotal = 120.0,
            discount = 10.0,
            grandTotal = 110.0,
            paymentMode = "Cash",
            createdAt = "2026-09-02 12:30:00"
        )
        val items = listOf(
            InvoiceItemEntity(
                id = 1L,
                invoiceId = 1L,
                itemName = "VEG FRANKIE",
                quantity = 1.0,
                unitPrice = 50.0,
                lineTotal = 50.0
            ),
            InvoiceItemEntity(
                id = 2L,
                invoiceId = 1L,
                itemName = "CHEESE VEG FRANKIE",
                quantity = 1.0,
                unitPrice = 70.0,
                lineTotal = 70.0
            )
        )

        val result = WhatsAppFormatter.generateWhatsAppBillText(shop, invoice, items)

        assertTrue(result.contains("🧾 *FRANKIE CORNER*"))
        assertTrue(result.contains("📞 Contact: 9876543210"))
        assertTrue(result.contains("📄 *Invoice #:* INV-1001"))
        assertTrue(result.contains("👤 *Customer:* RAHUL SHARMA"))
        assertTrue(result.contains("1. VEG FRANKIE"))
        assertTrue(result.contains("2. CHEESE VEG FRANKIE"))
        assertTrue(result.contains("Subtotal: ₹120.00"))
        assertTrue(result.contains("Discount: -₹10.00"))
        assertTrue(result.contains("💰 *TOTAL AMOUNT: ₹110.00*"))
        assertTrue(result.contains("💳 Payment Mode: Cash"))
        assertTrue(result.contains("✨ _Visit Again!_"))
    }
}
