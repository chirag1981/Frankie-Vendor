package com.vendor.invoice.ui.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.vendor.invoice.data.local.entity.InvoiceEntity
import com.vendor.invoice.data.local.entity.ShopSettingsEntity
import com.vendor.invoice.data.repository.InvoiceRepository
import com.vendor.invoice.domain.model.InvoiceWithItems
import com.vendor.invoice.domain.model.SalesSummary
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@OptIn(ExperimentalCoroutinesApi::class)
class HistoryViewModel(private val repository: InvoiceRepository) : ViewModel() {

    val shopSettings: StateFlow<ShopSettingsEntity?> = repository.shopSettingsFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    val invoices: StateFlow<List<InvoiceEntity>> = _searchQuery
        .flatMapLatest { query -> repository.searchInvoices(query) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val salesSummary: StateFlow<SalesSummary> = combine(
        repository.totalBillsFlow,
        repository.totalSalesFlow,
        repository.todayBillsFlow,
        repository.todaySalesFlow
    ) { totalBills, totalSales, todayBills, todaySales ->
        SalesSummary(
            totalBills = totalBills,
            totalSales = totalSales,
            todayBills = todayBills,
            todaySales = todaySales
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), SalesSummary())

    private val _selectedInvoiceDetails = MutableStateFlow<InvoiceWithItems?>(null)
    val selectedInvoiceDetails: StateFlow<InvoiceWithItems?> = _selectedInvoiceDetails.asStateFlow()

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
    }

    fun selectInvoice(invoiceId: Long) {
        viewModelScope.launch {
            val details = repository.getInvoiceWithItems(invoiceId)
            _selectedInvoiceDetails.value = details
        }
    }

    fun dismissInvoiceDetails() {
        _selectedInvoiceDetails.value = null
    }

    fun deleteInvoice(invoiceId: Long) {
        viewModelScope.launch {
            repository.deleteInvoice(invoiceId)
            _selectedInvoiceDetails.value = null
        }
    }
}
