package com.vendor.invoice.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "shop_settings")
data class ShopSettingsEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 1L,
    @ColumnInfo(name = "shop_name")
    val shopName: String = "FRANKIE CORNER",
    @ColumnInfo(name = "phone")
    val phone: String = "9876543210",
    @ColumnInfo(name = "address")
    val address: String = "Food Street, Market Road",
    @ColumnInfo(name = "upi_id")
    val upiId: String = "",
    @ColumnInfo(name = "currency")
    val currency: String = "₹",
    @ColumnInfo(name = "tax_percent")
    val taxPercent: Double = 0.0,
    @ColumnInfo(name = "footer_note")
    val footerNote: String = "Fresh & Delicious! Visit Again!",
    @ColumnInfo(name = "updated_at")
    val updatedAt: String = ""
)
