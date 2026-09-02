package com.vendor.invoice.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "catalog_items",
    indices = [Index(value = ["name"], unique = true)]
)
data class CatalogItemEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0L,
    @ColumnInfo(name = "name")
    val name: String,
    @ColumnInfo(name = "price")
    val price: Double,
    @ColumnInfo(name = "category")
    val category: String = "GENERAL",
    @ColumnInfo(name = "is_active")
    val isActive: Int = 1,
    @ColumnInfo(name = "created_at")
    val createdAt: String = ""
)
