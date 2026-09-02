package com.vendor.invoice.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "invoices",
    indices = [Index(value = ["invoice_number"], unique = true)]
)
data class InvoiceEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0L,
    @ColumnInfo(name = "invoice_number")
    val invoiceNumber: String,
    @ColumnInfo(name = "customer_name")
    val customerName: String = "",
    @ColumnInfo(name = "customer_phone")
    val customerPhone: String = "",
    @ColumnInfo(name = "subtotal")
    val subtotal: Double,
    @ColumnInfo(name = "discount")
    val discount: Double = 0.0,
    @ColumnInfo(name = "tax")
    val tax: Double = 0.0,
    @ColumnInfo(name = "grand_total")
    val grandTotal: Double,
    @ColumnInfo(name = "payment_mode")
    val paymentMode: String = "Cash",
    @ColumnInfo(name = "created_at")
    val createdAt: String = ""
)
