package com.vendor.invoice.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.vendor.invoice.data.local.entity.ShopSettingsEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ShopSettingsDao {
    @Query("SELECT * FROM shop_settings ORDER BY id ASC LIMIT 1")
    fun getShopSettingsFlow(): Flow<ShopSettingsEntity?>

    @Query("SELECT * FROM shop_settings ORDER BY id ASC LIMIT 1")
    suspend fun getShopSettings(): ShopSettingsEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(settings: ShopSettingsEntity): Long

    @Update
    suspend fun update(settings: ShopSettingsEntity)

    @Query("SELECT COUNT(*) FROM shop_settings")
    suspend fun count(): Int
}
