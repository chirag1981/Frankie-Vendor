package com.vendor.invoice.ui.catalog

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.vendor.invoice.data.local.entity.CatalogItemEntity
import com.vendor.invoice.data.local.entity.ShopSettingsEntity
import com.vendor.invoice.data.repository.InvoiceRepository
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed class CatalogUiEffect {
    data class ShowSnackbar(val message: String) : CatalogUiEffect()
}

class CatalogViewModel(private val repository: InvoiceRepository) : ViewModel() {

    val shopSettings: StateFlow<ShopSettingsEntity?> = repository.shopSettingsFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    val catalogItems: StateFlow<List<CatalogItemEntity>> = repository.allCatalogItemsFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _editingItem = MutableStateFlow<CatalogItemEntity?>(null)
    val editingItem: StateFlow<CatalogItemEntity?> = _editingItem.asStateFlow()

    private val _isAddDialogVisible = MutableStateFlow(false)
    val isAddDialogVisible: StateFlow<Boolean> = _isAddDialogVisible.asStateFlow()

    private val _uiEffect = MutableSharedFlow<CatalogUiEffect>()
    val uiEffect: SharedFlow<CatalogUiEffect> = _uiEffect.asSharedFlow()

    fun openAddDialog() {
        _editingItem.value = null
        _isAddDialogVisible.value = true
    }

    fun openEditDialog(item: CatalogItemEntity) {
        _editingItem.value = item
        _isAddDialogVisible.value = true
    }

    fun dismissDialog() {
        _editingItem.value = null
        _isAddDialogVisible.value = false
    }

    fun saveItem(name: String, price: Double, category: String) {
        if (name.isBlank()) {
            viewModelScope.launch {
                _uiEffect.emit(CatalogUiEffect.ShowSnackbar("Item name is required"))
            }
            return
        }

        viewModelScope.launch {
            val item = _editingItem.value
            if (item != null) {
                repository.updateCatalogItem(item.id, name, price, category)
                _uiEffect.emit(CatalogUiEffect.ShowSnackbar("✅ Item '$name' updated!"))
            } else {
                repository.addCatalogItem(name, price, category)
                _uiEffect.emit(CatalogUiEffect.ShowSnackbar("✅ Item '$name' added!"))
            }
            dismissDialog()
        }
    }

    fun deleteItem(itemId: Long, name: String) {
        viewModelScope.launch {
            repository.deleteCatalogItem(itemId)
            _uiEffect.emit(CatalogUiEffect.ShowSnackbar("🗑️ Deleted $name"))
        }
    }
}
