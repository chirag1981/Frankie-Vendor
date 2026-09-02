package com.vendor.invoice.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "invoice_items",
    foreignKeys = [
        ForeignKey(
            entity = InvoiceEntity::class,
            parentColumns = ["id"],
            childColumns = ["invoice_id"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["invoice_id"])]
)
data class InvoiceItemEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0L,
    @ColumnInfo(name = "invoice_id")
    val invoiceId: Long,
    @ColumnInfo(name = "item_name")
    val itemName: String,
    @ColumnInfo(name = "quantity")
    val quantity: Double,
    @ColumnInfo(name = "unit_price")
    val unitPrice: Double,
    @ColumnInfo(name = "line_total")
    val lineTotal: Double
)
