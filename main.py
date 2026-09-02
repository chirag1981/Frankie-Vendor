"""
Main Application Entry Point for Shop Vendor Invoice.
Built with Python + Flet (Flutter Material 3 UI).
"""

import flet as ft
from app import database
from app.views import (
    create_billing_view,
    create_history_view,
    create_catalog_view,
    create_settings_view
)


def main(page: ft.Page):
    # Page / Mobile Viewport Configuration
    page.title = "Quick Vendor Invoice"
    page.theme_mode = ft.ThemeMode.LIGHT
    page.window_width = 410
    page.window_height = 800
    page.window_resizable = True
    page.padding = 0

    # Custom modern Material theme palette
    page.theme = ft.Theme(
        color_scheme_seed=ft.Colors.INDIGO,
        use_material3=True,
    )

    # Register system URL launcher and file sharing services
    page.overlay.extend([ft.UrlLauncher(), ft.Share()])

    # Initialize SQLite schema and initial data
    database.init_db()

    # Content container that holds the active view
    body_container = ft.Container(expand=True)

    def reload_views():
        """Refreshes active view when settings or items change."""
        current_idx = nav_bar.selected_index
        switch_tab(current_idx)

    def switch_tab(index: int):
        nav_bar.selected_index = index
        if index == 0:
            body_container.content = create_billing_view(page, on_invoice_created=reload_views)
        elif index == 1:
            body_container.content = create_history_view(page)
        elif index == 2:
            body_container.content = create_catalog_view(page, on_catalog_changed=reload_views)
        elif index == 3:
            body_container.content = create_settings_view(page, on_settings_saved=reload_views)
        page.update()

    # Bottom Navigation Bar for Mobile ergonomics
    nav_bar = ft.NavigationBar(
        selected_index=0,
        on_change=lambda e: switch_tab(e.control.selected_index),
        destinations=[
            ft.NavigationBarDestination(icon=ft.Icons.RECEIPT_LONG_OUTLINED, selected_icon=ft.Icons.RECEIPT_LONG, label="Billing"),
            ft.NavigationBarDestination(icon=ft.Icons.HISTORY_OUTLINED, selected_icon=ft.Icons.HISTORY, label="History"),
            ft.NavigationBarDestination(icon=ft.Icons.RESTAURANT_MENU_OUTLINED, selected_icon=ft.Icons.RESTAURANT_MENU, label="Menu"),
            ft.NavigationBarDestination(icon=ft.Icons.SETTINGS_OUTLINED, selected_icon=ft.Icons.SETTINGS, label="Settings"),
        ]
    )

    page.navigation_bar = nav_bar

    # Initial view load
    switch_tab(0)

    # Wrap in SafeArea to prevent overlap with Android status bar, camera notch, and navigation
    safe_area = ft.SafeArea(content=body_container, expand=True)
    page.add(safe_area)


import sys

if __name__ == "__main__":
    if "--web" in sys.argv:
        print("Starting in Web Browser mode...")
        ft.run(main, view=ft.AppView.WEB_BROWSER)
    else:
        ft.run(main)

