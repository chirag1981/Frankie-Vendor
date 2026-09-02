package com.vendor.invoice

import com.vendor.invoice.domain.model.DraftInvoiceItem
import org.junit.Assert.assertEquals
import org.junit.Test

class InvoiceMathTest {

    @Test
    fun testDraftItemLineTotalCalculation() {
        val item1 = DraftInvoiceItem(name = "VEG FRANKIE", quantity = 2.0, unitPrice = 50.0)
        assertEquals(100.0, item1.lineTotal, 0.001)

        val item2 = DraftInvoiceItem(name = "CHEESE PANEER FRANKIE", quantity = 3.0, unitPrice = 100.0)
        assertEquals(300.0, item2.lineTotal, 0.001)
    }

    @Test
    fun testSubtotalAndGrandTotalCalculation() {
        val items = listOf(
            DraftInvoiceItem(name = "VEG FRANKIE", quantity = 2.0, unitPrice = 50.0),      // 100.0
            DraftInvoiceItem(name = "CHEESE VEG FRANKIE", quantity = 1.0, unitPrice = 70.0) // 70.0
        )
        val subtotal = items.sumOf { it.lineTotal }
        assertEquals(170.0, subtotal, 0.001)

        val discount = 20.0
        val grandTotal = maxOf(0.0, subtotal - discount)
        assertEquals(150.0, grandTotal, 0.001)
    }

    @Test
    fun testDiscountExceedingSubtotalCapsAtZero() {
        val items = listOf(
            DraftInvoiceItem(name = "COLD COFFEE", quantity = 1.0, unitPrice = 40.0)
        )
        val subtotal = items.sumOf { it.lineTotal }
        val discount = 100.0
        val grandTotal = maxOf(0.0, subtotal - discount)
        assertEquals(0.0, grandTotal, 0.001)
    }
}
