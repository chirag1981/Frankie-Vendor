package com.vendor.invoice.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import com.vendor.invoice.data.local.entity.InvoiceEntity
import com.vendor.invoice.data.local.entity.InvoiceItemEntity
import com.vendor.invoice.domain.model.InvoiceWithItems
import kotlinx.coroutines.flow.Flow

@Dao
abstract class InvoiceDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun insertInvoice(invoice: InvoiceEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    abstract suspend fun insertInvoiceItems(items: List<InvoiceItemEntity>)

    @Transaction
    open suspend fun insertInvoiceWithItems(invoice: InvoiceEntity, items: List<InvoiceItemEntity>): Long {
        val invoiceId = insertInvoice(invoice)
        val linkedItems = items.map { it.copy(invoiceId = invoiceId) }
        insertInvoiceItems(linkedItems)
        return invoiceId
    }

    @Query("SELECT * FROM invoices ORDER BY id DESC")
    abstract fun getAllInvoicesFlow(): Flow<List<InvoiceEntity>>

    @Query("""
        SELECT * FROM invoices 
        WHERE invoice_number LIKE '%' || :query || '%' 
           OR customer_name LIKE '%' || :query || '%' 
           OR customer_phone LIKE '%' || :query || '%' 
        ORDER BY id DESC
    """)
    abstract fun searchInvoicesFlow(query: String): Flow<List<InvoiceEntity>>

    @Transaction
    @Query("SELECT * FROM invoices WHERE id = :invoiceId LIMIT 1")
    abstract suspend fun getInvoiceWithItemsById(invoiceId: Long): InvoiceWithItems?

    @Query("SELECT * FROM invoice_items WHERE invoice_id = :invoiceId ORDER BY id ASC")
    abstract suspend fun getInvoiceItems(invoiceId: Long): List<InvoiceItemEntity>

    @Query("SELECT COUNT(*) FROM invoice_items WHERE invoice_id = :invoiceId")
    abstract suspend fun getInvoiceItemsCount(invoiceId: Long): Int

    @Query("SELECT id FROM invoices ORDER BY id DESC LIMIT 1")
    abstract suspend fun getLastInvoiceId(): Long?

    @Query("DELETE FROM invoices WHERE id = :invoiceId")
    abstract suspend fun deleteInvoice(invoiceId: Long)

    @Query("SELECT COUNT(*) FROM invoices")
    abstract fun getTotalBillsCountFlow(): Flow<Int>

    @Query("SELECT COALESCE(SUM(grand_total), 0.0) FROM invoices")
    abstract fun getTotalSalesFlow(): Flow<Double>

    @Query("SELECT COUNT(*) FROM invoices WHERE DATE(created_at) = DATE('now', 'localtime')")
    abstract fun getTodayBillsCountFlow(): Flow<Int>

    @Query("SELECT COALESCE(SUM(grand_total), 0.0) FROM invoices WHERE DATE(created_at) = DATE('now', 'localtime')")
    abstract fun getTodaySalesFlow(): Flow<Double>
}
