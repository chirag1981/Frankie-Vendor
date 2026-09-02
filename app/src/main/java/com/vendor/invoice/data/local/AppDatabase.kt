package com.vendor.invoice.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import com.vendor.invoice.data.local.dao.CatalogItemDao
import com.vendor.invoice.data.local.dao.InvoiceDao
import com.vendor.invoice.data.local.dao.ShopSettingsDao
import com.vendor.invoice.data.local.entity.CatalogItemEntity
import com.vendor.invoice.data.local.entity.InvoiceEntity
import com.vendor.invoice.data.local.entity.InvoiceItemEntity
import com.vendor.invoice.data.local.entity.ShopSettingsEntity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Database(
    entities = [
        ShopSettingsEntity::class,
        CatalogItemEntity::class,
        InvoiceEntity::class,
        InvoiceItemEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun shopSettingsDao(): ShopSettingsDao
    abstract fun catalogItemDao(): CatalogItemDao
    abstract fun invoiceDao(): InvoiceDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "vendor_invoice.db"
                )
                    .addCallback(DatabaseCallback())
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }

        private class DatabaseCallback : Callback() {
            override fun onCreate(db: SupportSQLiteDatabase) {
                super.onCreate(db)
                INSTANCE?.let { database ->
                    CoroutineScope(Dispatchers.IO).launch {
                        seedDefaultData(database)
                    }
                }
            }

            private suspend fun seedDefaultData(database: AppDatabase) {
                val now = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())

                // 1. Seed Shop Settings
                val shopDao = database.shopSettingsDao()
                if (shopDao.count() == 0) {
                    shopDao.insert(
                        ShopSettingsEntity(
                            id = 1L,
                            shopName = "FRANKIE CORNER",
                            phone = "9876543210",
                            address = "Food Street, Market Road",
                            upiId = "",
                            currency = "₹",
                            taxPercent = 0.0,
                            footerNote = "Fresh & Delicious! Visit Again!",
                            updatedAt = now
                        )
                    )
                }

                // 2. Seed Default Catalog Items
                val catalogDao = database.catalogItemDao()
                if (catalogDao.count() == 0) {
                    val sampleItems = listOf(
                        CatalogItemEntity(name = "VEG FRANKIE", price = 50.0, category = "FRANKIE", createdAt = now),
                        CatalogItemEntity(name = "CHEESE VEG FRANKIE", price = 70.0, category = "FRANKIE", createdAt = now),
                        CatalogItemEntity(name = "PANEER FRANKIE", price = 80.0, category = "FRANKIE", createdAt = now),
                        CatalogItemEntity(name = "CHEESE PANEER FRANKIE", price = 100.0, category = "FRANKIE", createdAt = now),
                        CatalogItemEntity(name = "SCHEZWAN NOODLE FRANKIE", price = 60.0, category = "FRANKIE", createdAt = now),
                        CatalogItemEntity(name = "PERI PERI FRIES", price = 70.0, category = "SNACKS", createdAt = now),
                        CatalogItemEntity(name = "COLD COFFEE", price = 40.0, category = "BEVERAGES", createdAt = now),
                        CatalogItemEntity(name = "MINERAL WATER (500ML)", price = 10.0, category = "BEVERAGES", createdAt = now)
                    )
                    catalogDao.insertAll(sampleItems)
                }
            }
        }
    }
}
