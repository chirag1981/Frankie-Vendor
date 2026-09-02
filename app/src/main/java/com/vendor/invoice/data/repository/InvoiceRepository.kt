package com.vendor.invoice.data.repository

import com.vendor.invoice.data.local.AppDatabase
import com.vendor.invoice.data.local.entity.CatalogItemEntity
import com.vendor.invoice.data.local.entity.InvoiceEntity
import com.vendor.invoice.data.local.entity.InvoiceItemEntity
import com.vendor.invoice.data.local.entity.ShopSettingsEntity
import com.vendor.invoice.domain.model.InvoiceWithItems
import kotlinx.coroutines.flow.Flow
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class InvoiceRepository(private val database: AppDatabase) {

    private val shopSettingsDao = database.shopSettingsDao()
    private val catalogItemDao = database.catalogItemDao()
    private val invoiceDao = database.invoiceDao()

    // --- Shop Settings ---
    val shopSettingsFlow: Flow<ShopSettingsEntity?> = shopSettingsDao.getShopSettingsFlow()

    suspend fun getShopSettings(): ShopSettingsEntity {
        return shopSettingsDao.getShopSettings() ?: ShopSettingsEntity()
    }

    suspend fun updateShopSettings(settings: ShopSettingsEntity) {
        val now = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
        shopSettingsDao.insert(settings.copy(id = 1L, updatedAt = now))
    }

    // --- Catalog Items ---
    val activeCatalogItemsFlow: Flow<List<CatalogItemEntity>> = catalogItemDao.getActiveCatalogItemsFlow()
    val allCatalogItemsFlow: Flow<List<CatalogItemEntity>> = catalogItemDao.getAllCatalogItemsFlow()

    suspend fun addCatalogItem(name: String, price: Double, category: String) {
        val now = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
        catalogItemDao.insert(
            CatalogItemEntity(
                name = name.trim().uppercase(Locale.getDefault()),
                price = price,
                category = category.trim().uppercase(Locale.getDefault()).ifEmpty { "GENERAL" },
                createdAt = now
            )
        )
    }

    suspend fun updateCatalogItem(id: Long, name: String, price: Double, category: String) {
        val existing = catalogItemDao.getCatalogItemById(id)
        if (existing != null) {
            catalogItemDao.update(
                existing.copy(
                    name = name.trim().uppercase(Locale.getDefault()),
                    price = price,
                    category = category.trim().uppercase(Locale.getDefault()).ifEmpty { "GENERAL" }
                )
            )
        }
    }

    suspend fun deleteCatalogItem(id: Long) {
        catalogItemDao.deleteById(id)
    }

    // --- Invoices ---
    val allInvoicesFlow: Flow<List<InvoiceEntity>> = invoiceDao.getAllInvoicesFlow()

    fun searchInvoices(query: String): Flow<List<InvoiceEntity>> {
        return if (query.isBlank()) {
            invoiceDao.getAllInvoicesFlow()
        } else {
            invoiceDao.searchInvoicesFlow(query.trim())
        }
    }

    suspend fun getNextInvoiceNumber(): String {
        val lastId = invoiceDao.getLastInvoiceId() ?: 0L
        return "INV-${1001 + lastId}"
    }

    suspend fun createInvoice(
        customerName: String,
        customerPhone: String,
        items: List<Pair<String, Pair<Double, Double>>>, // name -> (qty, price)
        discount: Double = 0.0,
        tax: Double = 0.0,
        paymentMode: String = "Cash"
    ): Pair<Long, InvoiceEntity> {
        val invoiceNumber = getNextInvoiceNumber()
        val subtotal = items.sumOf { it.second.first * it.second.second }
        val grandTotal = maxOf(0.0, subtotal - discount + tax)
        val now = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())

        val invoice = InvoiceEntity(
            invoiceNumber = invoiceNumber,
            customerName = customerName.trim().uppercase(Locale.getDefault()),
            customerPhone = customerPhone.trim(),
            subtotal = (subtotal * 100).toLong() / 100.0,
            discount = (discount * 100).toLong() / 100.0,
            tax = (tax * 100).toLong() / 100.0,
            grandTotal = (grandTotal * 100).toLong() / 100.0,
            paymentMode = paymentMode,
            createdAt = now
        )

        val invoiceItems = items.map { (name, pair) ->
            val qty = pair.first
            val price = pair.second
            InvoiceItemEntity(
                invoiceId = 0L,
                itemName = name.trim().uppercase(Locale.getDefault()),
                quantity = qty,
                unitPrice = price,
                lineTotal = (qty * price * 100).toLong() / 100.0
            )
        }

        val invoiceId = invoiceDao.insertInvoiceWithItems(invoice, invoiceItems)
        return Pair(invoiceId, invoice.copy(id = invoiceId))
    }

    suspend fun getInvoiceWithItems(invoiceId: Long): InvoiceWithItems? {
        return invoiceDao.getInvoiceWithItemsById(invoiceId)
    }

    suspend fun deleteInvoice(invoiceId: Long) {
        invoiceDao.deleteInvoice(invoiceId)
    }

    // --- Analytics Flows ---
    val totalBillsFlow = invoiceDao.getTotalBillsCountFlow()
    val totalSalesFlow = invoiceDao.getTotalSalesFlow()
    val todayBillsFlow = invoiceDao.getTodayBillsCountFlow()
    val todaySalesFlow = invoiceDao.getTodaySalesFlow()
}
