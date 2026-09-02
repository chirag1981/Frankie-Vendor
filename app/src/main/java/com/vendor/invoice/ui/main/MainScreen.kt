package com.vendor.invoice.ui.main

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.ReceiptLong
import androidx.compose.material.icons.filled.RestaurantMenu
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.ReceiptLong
import androidx.compose.material.icons.outlined.RestaurantMenu
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.vendor.invoice.QuickVendorApp
import com.vendor.invoice.ui.billing.BillingScreen
import com.vendor.invoice.ui.billing.BillingViewModel
import com.vendor.invoice.ui.catalog.CatalogScreen
import com.vendor.invoice.ui.catalog.CatalogViewModel
import com.vendor.invoice.ui.history.HistoryScreen
import com.vendor.invoice.ui.history.HistoryViewModel
import com.vendor.invoice.ui.settings.SettingsScreen
import com.vendor.invoice.ui.settings.SettingsViewModel

sealed class NavTab(val index: Int, val title: String) {
    object Billing : NavTab(0, "Billing")
    object History : NavTab(1, "History")
    object Menu : NavTab(2, "Menu")
    object Settings : NavTab(3, "Settings")
}

@Composable
fun MainScreen() {
    val repository = QuickVendorApp.instance.repository
    val snackbarHostState = remember { SnackbarHostState() }

    val billingViewModel = remember { BillingViewModel(repository) }
    val historyViewModel = remember { HistoryViewModel(repository) }
    val catalogViewModel = remember { CatalogViewModel(repository) }
    val settingsViewModel = remember { SettingsViewModel(repository) }

    var selectedTab by remember { mutableIntStateOf(0) }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            NavigationBar(
                containerColor = Color.White,
                contentColor = Color(0xFF4F46E5)
            ) {
                NavigationBarItem(
                    selected = selectedTab == 0,
                    onClick = {
                        selectedTab = 0
                        billingViewModel.refreshInvoiceNumberAndDate()
                    },
                    icon = {
                        Icon(
                            if (selectedTab == 0) Icons.Filled.ReceiptLong else Icons.Outlined.ReceiptLong,
                            contentDescription = "Billing"
                        )
                    },
                    label = { Text("Billing") },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = Color(0xFF4F46E5),
                        selectedTextColor = Color(0xFF4F46E5),
                        indicatorColor = Color(0xFFEEF2FF)
                    )
                )

                NavigationBarItem(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    icon = {
                        Icon(
                            if (selectedTab == 1) Icons.Filled.History else Icons.Outlined.History,
                            contentDescription = "History"
                        )
                    },
                    label = { Text("History") },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = Color(0xFF4F46E5),
                        selectedTextColor = Color(0xFF4F46E5),
                        indicatorColor = Color(0xFFEEF2FF)
                    )
                )

                NavigationBarItem(
                    selected = selectedTab == 2,
                    onClick = { selectedTab = 2 },
                    icon = {
                        Icon(
                            if (selectedTab == 2) Icons.Filled.RestaurantMenu else Icons.Outlined.RestaurantMenu,
                            contentDescription = "Menu"
                        )
                    },
                    label = { Text("Menu") },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = Color(0xFF4F46E5),
                        selectedTextColor = Color(0xFF4F46E5),
                        indicatorColor = Color(0xFFEEF2FF)
                    )
                )

                NavigationBarItem(
                    selected = selectedTab == 3,
                    onClick = { selectedTab = 3 },
                    icon = {
                        Icon(
                            if (selectedTab == 3) Icons.Filled.Settings else Icons.Outlined.Settings,
                            contentDescription = "Settings"
                        )
                    },
                    label = { Text("Settings") },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = Color(0xFF4F46E5),
                        selectedTextColor = Color(0xFF4F46E5),
                        indicatorColor = Color(0xFFEEF2FF)
                    )
                )
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when (selectedTab) {
                0 -> BillingScreen(viewModel = billingViewModel, snackbarHostState = snackbarHostState)
                1 -> HistoryScreen(viewModel = historyViewModel, snackbarHostState = snackbarHostState)
                2 -> CatalogScreen(viewModel = catalogViewModel, snackbarHostState = snackbarHostState)
                3 -> SettingsScreen(viewModel = settingsViewModel, snackbarHostState = snackbarHostState)
            }
        }
    }
}
