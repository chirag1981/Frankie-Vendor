package com.vendor.invoice.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
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

sealed class SettingsUiEffect {
    data class ShowSnackbar(val message: String) : SettingsUiEffect()
}

class SettingsViewModel(private val repository: InvoiceRepository) : ViewModel() {

    val shopSettings: StateFlow<ShopSettingsEntity?> = repository.shopSettingsFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    private val _uiEffect = MutableSharedFlow<SettingsUiEffect>()
    val uiEffect: SharedFlow<SettingsUiEffect> = _uiEffect.asSharedFlow()

    fun saveSettings(
        shopName: String,
        phone: String,
        address: String,
        currency: String,
        footerNote: String
    ) {
        if (shopName.isBlank()) {
            viewModelScope.launch {
                _uiEffect.emit(SettingsUiEffect.ShowSnackbar("Shop name is required"))
            }
            return
        }

        viewModelScope.launch {
            repository.updateShopSettings(
                ShopSettingsEntity(
                    id = 1L,
                    shopName = shopName.trim().uppercase(),
                    phone = phone.trim(),
                    address = address.trim(),
                    upiId = "",
                    currency = currency.trim().ifEmpty { "₹" },
                    taxPercent = 0.0,
                    footerNote = footerNote.trim().ifEmpty { "Thank you for your visit!" }
                )
            )
            _uiEffect.emit(SettingsUiEffect.ShowSnackbar("✅ Shop settings updated successfully!"))
        }
    }
}
