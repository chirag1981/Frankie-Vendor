package com.vendor.invoice.domain.model

import androidx.room.Embedded
import androidx.room.Relation
import com.vendor.invoice.data.local.entity.InvoiceEntity
import com.vendor.invoice.data.local.entity.InvoiceItemEntity

data class InvoiceWithItems(
    @Embedded val invoice: InvoiceEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "invoice_id"
    )
    val items: List<InvoiceItemEntity>
)

data class DraftInvoiceItem(
    val id: String = java.util.UUID.randomUUID().toString(),
    val name: String = "",
    val quantity: Double = 1.0,
    val unitPrice: Double = 0.0
) {
    val lineTotal: Double
        get() = (quantity * unitPrice)
}

data class SalesSummary(
    val totalBills: Int = 0,
    val totalSales: Double = 0.0,
    val todayBills: Int = 0,
    val todaySales: Double = 0.0
)
