package com.vendor.invoice.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.vendor.invoice.data.local.entity.CatalogItemEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface CatalogItemDao {
    @Query("SELECT * FROM catalog_items WHERE is_active = 1 ORDER BY category ASC, name ASC")
    fun getActiveCatalogItemsFlow(): Flow<List<CatalogItemEntity>>

    @Query("SELECT * FROM catalog_items ORDER BY category ASC, name ASC")
    fun getAllCatalogItemsFlow(): Flow<List<CatalogItemEntity>>

    @Query("SELECT * FROM catalog_items WHERE id = :id LIMIT 1")
    suspend fun getCatalogItemById(id: Long): CatalogItemEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(item: CatalogItemEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(items: List<CatalogItemEntity>)

    @Update
    suspend fun update(item: CatalogItemEntity)

    @Query("DELETE FROM catalog_items WHERE id = :id")
    suspend fun deleteById(id: Long)

    @Query("SELECT COUNT(*) FROM catalog_items")
    suspend fun count(): Int
}
