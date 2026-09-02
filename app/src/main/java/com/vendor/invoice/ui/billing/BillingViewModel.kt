package com.vendor.invoice.ui.billing

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.vendor.invoice.data.local.entity.CatalogItemEntity
import com.vendor.invoice.data.local.entity.InvoiceEntity
import com.vendor.invoice.data.local.entity.InvoiceItemEntity
import com.vendor.invoice.data.local.entity.ShopSettingsEntity
import com.vendor.invoice.data.repository.InvoiceRepository
import com.vendor.invoice.domain.model.DraftInvoiceItem
import com.vendor.invoice.domain.util.PdfInvoiceGenerator
import com.vendor.invoice.domain.util.WhatsAppFormatter
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

sealed class BillingUiEffect {
    data class ShowSnackbar(val message: String) : BillingUiEffect()
    data class OpenWhatsApp(val phone: String, val message: String) : BillingUiEffect()
    data class OpenPdf(val file: File) : BillingUiEffect()
}

data class BillingUiState(
    val nextInvoiceNumber: String = "INV-1001",
    val currentDateText: String = "",
    val customerName: String = "",
    val customerPhone: String = "",
    val draftItems: List<DraftInvoiceItem> = emptyList(),
    val discountText: String = "0",
    val paymentMode: String = "Cash",
    val savedInvoiceModal: Pair<InvoiceEntity, List<InvoiceItemEntity>>? = null,
    val savedPdfFile: File? = null
) {
    val subtotal: Double
        get() = draftItems.sumOf { it.lineTotal }

    val discount: Double
        get() = discountText.toDoubleOrNull() ?: 0.0

    val grandTotal: Double
        get() = maxOf(0.0, subtotal - discount)
}

class BillingViewModel(private val repository: InvoiceRepository) : ViewModel() {

    val shopSettings: StateFlow<ShopSettingsEntity?> = repository.shopSettingsFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    val catalogItems: StateFlow<List<CatalogItemEntity>> = repository.activeCatalogItemsFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _uiState = MutableStateFlow(BillingUiState())
    val uiState: StateFlow<BillingUiState> = _uiState.asStateFlow()

    private val _uiEffect = MutableSharedFlow<BillingUiEffect>()
    val uiEffect: SharedFlow<BillingUiEffect> = _uiEffect.asSharedFlow()

    init {
        refreshInvoiceNumberAndDate()
    }

    fun refreshInvoiceNumberAndDate() {
        viewModelScope.launch {
            val nextNum = repository.getNextInvoiceNumber()
            val dateStr = SimpleDateFormat("dd-MMM-yyyy hh:mm a", Locale.getDefault()).format(Date())
            _uiState.value = _uiState.value.copy(
                nextInvoiceNumber = nextNum,
                currentDateText = dateStr
            )
        }
    }

    fun onCustomerNameChange(name: String) {
        _uiState.value = _uiState.value.copy(customerName = name)
    }

    fun onCustomerPhoneChange(phone: String) {
        _uiState.value = _uiState.value.copy(customerPhone = phone)
    }

    fun onDiscountChange(discount: String) {
        _uiState.value = _uiState.value.copy(discountText = discount)
    }

    fun onPaymentModeChange(mode: String) {
        _uiState.value = _uiState.value.copy(paymentMode = mode)
    }

    fun addOrIncrementCatalogItem(catalogItem: CatalogItemEntity) {
        val currentList = _uiState.value.draftItems.toMutableList()
        val existingIndex = currentList.indexOfFirst {
            it.name.trim().equals(catalogItem.name.trim(), ignoreCase = true)
        }

        if (existingIndex != -1) {
            val existing = currentList[existingIndex]
            currentList[existingIndex] = existing.copy(quantity = existing.quantity + 1.0)
        } else {
            currentList.add(
                DraftInvoiceItem(
                    name = catalogItem.name,
                    quantity = 1.0,
                    unitPrice = catalogItem.price
                )
            )
        }
        _uiState.value = _uiState.value.copy(draftItems = currentList)
    }

    fun addCustomItem() {
        val currentList = _uiState.value.draftItems.toMutableList()
        currentList.add(DraftInvoiceItem(name = "", quantity = 1.0, unitPrice = 0.0))
        _uiState.value = _uiState.value.copy(draftItems = currentList)
    }

    fun updateDraftItem(itemId: String, name: String, quantity: Double, unitPrice: Double) {
        val currentList = _uiState.value.draftItems.map {
            if (it.id == itemId) {
                it.copy(name = name, quantity = quantity, unitPrice = unitPrice)
            } else it
        }
        _uiState.value = _uiState.value.copy(draftItems = currentList)
    }

    fun removeDraftItem(itemId: String) {
        val currentList = _uiState.value.draftItems.filterNot { it.id == itemId }
        _uiState.value = _uiState.value.copy(draftItems = currentList)
    }

    fun resetBill() {
        _uiState.value = _uiState.value.copy(
            customerName = "",
            customerPhone = "",
            draftItems = emptyList(),
            discountText = "0",
            paymentMode = "Cash"
        )
        refreshInvoiceNumberAndDate()
    }

    fun saveInvoice(context: Context, isWhatsAppShare: Boolean) {
        val validItems = _uiState.value.draftItems.filter { it.name.isNotBlank() && it.quantity > 0.0 }
        if (validItems.isEmpty()) {
            viewModelScope.launch {
                _uiEffect.emit(BillingUiEffect.ShowSnackbar("⚠️ Please add at least 1 item to the bill."))
            }
            return
        }

        viewModelScope.launch {
            val itemsForDb = validItems.map {
                Pair(it.name, Pair(it.quantity, it.unitPrice))
            }

            val (invId, invoiceEntity) = repository.createInvoice(
                customerName = _uiState.value.customerName,
                customerPhone = _uiState.value.customerPhone,
                items = itemsForDb,
                discount = _uiState.value.discount,
                tax = 0.0,
                paymentMode = _uiState.value.paymentMode
            )

            val fullInvoice = repository.getInvoiceWithItems(invId)
            val invoiceItems = fullInvoice?.items ?: emptyList()
            val currentShop = shopSettings.value ?: ShopSettingsEntity()

            // Generate PDF
            val pdfFile = PdfInvoiceGenerator.generatePdf(context, currentShop, invoiceEntity, invoiceItems)

            _uiState.value = _uiState.value.copy(
                savedInvoiceModal = Pair(invoiceEntity, invoiceItems),
                savedPdfFile = pdfFile
            )

            if (isWhatsAppShare) {
                val waText = WhatsAppFormatter.generateWhatsAppBillText(currentShop, invoiceEntity, invoiceItems)
                _uiEffect.emit(BillingUiEffect.OpenWhatsApp(invoiceEntity.customerPhone, waText))
                _uiEffect.emit(BillingUiEffect.ShowSnackbar("✅ Invoice saved & opening WhatsApp!"))
            } else {
                _uiEffect.emit(BillingUiEffect.ShowSnackbar("✅ Invoice #${invoiceEntity.invoiceNumber} saved!"))
            }

            resetBill()
        }
    }

    fun dismissReceiptModal() {
        _uiState.value = _uiState.value.copy(savedInvoiceModal = null, savedPdfFile = null)
    }
}
