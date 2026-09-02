package com.vendor.invoice

import android.app.Application
import com.vendor.invoice.data.local.AppDatabase
import com.vendor.invoice.data.repository.InvoiceRepository

class QuickVendorApp : Application() {

    lateinit var database: AppDatabase
        private set

    lateinit var repository: InvoiceRepository
        private set

    override fun onCreate() {
        super.onCreate()
        instance = this
        database = AppDatabase.getInstance(this)
        repository = InvoiceRepository(database)
    }

    companion object {
        lateinit var instance: QuickVendorApp
            private set
    }
}
