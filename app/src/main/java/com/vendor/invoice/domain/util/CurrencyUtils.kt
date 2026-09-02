package com.vendor.invoice.domain.util

import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale

object CurrencyUtils {

    fun format(amount: Double, symbol: String = "₹"): String {
        val symbols = DecimalFormatSymbols(Locale.getDefault())
        val formatter = DecimalFormat("#,##0.00", symbols)
        return "$symbol${formatter.format(amount)}"
    }

    fun formatQty(qty: Double): String {
        return if (qty % 1.0 == 0.0) {
            qty.toLong().toString()
        } else {
            String.format(Locale.getDefault(), "%.2f", qty)
        }
    }
}
