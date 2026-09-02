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
interface InvoiceDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertInvoice(invoice: InvoiceEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertInvoiceItems(items: List<InvoiceItemEntity>)

    @Query("SELECT * FROM invoices ORDER BY id DESC")
    fun getAllInvoicesFlow(): Flow<List<InvoiceEntity>>

    @Query("""
        SELECT * FROM invoices 
        WHERE invoice_number LIKE '%' || :query || '%' 
           OR customer_name LIKE '%' || :query || '%' 
           OR customer_phone LIKE '%' || :query || '%' 
        ORDER BY id DESC
    """)
    fun searchInvoicesFlow(query: String): Flow<List<InvoiceEntity>>

    @Transaction
    @Query("SELECT * FROM invoices WHERE id = :invoiceId LIMIT 1")
    suspend fun getInvoiceWithItemsById(invoiceId: Long): InvoiceWithItems?

    @Query("SELECT * FROM invoice_items WHERE invoice_id = :invoiceId ORDER BY id ASC")
    suspend fun getInvoiceItems(invoiceId: Long): List<InvoiceItemEntity>

    @Query("SELECT COUNT(*) FROM invoice_items WHERE invoice_id = :invoiceId")
    suspend fun getInvoiceItemsCount(invoiceId: Long): Int

    @Query("SELECT id FROM invoices ORDER BY id DESC LIMIT 1")
    suspend fun getLastInvoiceId(): Long?

    @Query("DELETE FROM invoices WHERE id = :invoiceId")
    suspend fun deleteInvoice(invoiceId: Long)

    @Query("SELECT COUNT(*) FROM invoices")
    fun getTotalBillsCountFlow(): Flow<Int>

    @Query("SELECT COALESCE(SUM(grand_total), 0.0) FROM invoices")
    fun getTotalSalesFlow(): Flow<Double>

    @Query("SELECT COUNT(*) FROM invoices WHERE DATE(created_at) = DATE('now', 'localtime')")
    fun getTodayBillsCountFlow(): Flow<Int>

    @Query("SELECT COALESCE(SUM(grand_total), 0.0) FROM invoices WHERE DATE(created_at) = DATE('now', 'localtime')")
    fun getTodaySalesFlow(): Flow<Double>
}
