"""
Shop Profile & Settings View: Configure Shop Name, Phone, Address, UPI ID, Currency, and Footer Note.
"""

import flet as ft
from typing import Callable
from app import database, utils


def create_settings_view(page: ft.Page, on_settings_saved: Callable = None) -> ft.Control:
    """Builds the Shop Settings & Configuration View."""
    current_settings = database.get_shop_settings()

    shop_name_field = ft.TextField(
        label="Shop / Business Name",
        value=current_settings.get("shop_name", ""),
        prefix_icon=ft.Icons.STORE,
        capitalization=ft.TextCapitalization.CHARACTERS,
        dense=True,
        border_radius=8
    )

    phone_field = ft.TextField(
        label="Phone / Mobile Number",
        value=current_settings.get("phone", ""),
        prefix_icon=ft.Icons.PHONE,
        keyboard_type=ft.KeyboardType.PHONE,
        dense=True,
        border_radius=8
    )

    address_field = ft.TextField(
        label="Shop Address / Location",
        value=current_settings.get("address", ""),
        prefix_icon=ft.Icons.LOCATION_ON_OUTLINED,
        multiline=True,
        min_lines=2,
        max_lines=3,
        dense=True,
        border_radius=8
    )

    currency_field = ft.TextField(
        label="Currency Symbol",
        value=current_settings.get("currency", "₹"),
        prefix_icon=ft.Icons.CURRENCY_RUPEE,
        dense=True,
        width=120,
        border_radius=8
    )

    footer_note_field = ft.TextField(
        label="Receipt Footer Note",
        value=current_settings.get("footer_note", "Thank you for your visit!"),
        prefix_icon=ft.Icons.FAVORITE_BORDER,
        dense=True,
        border_radius=8
    )

    def save_settings(e):
        name = shop_name_field.value.strip().upper()
        if not name:
            shop_name_field.error_text = "Shop name is required"
            shop_name_field.update()
            return

        database.update_shop_settings(
            shop_name=name,
            phone=phone_field.value.strip(),
            address=address_field.value.strip(),
            upi_id="",
            currency=currency_field.value.strip() or "₹",
            footer_note=footer_note_field.value.strip()
        )

        utils.show_snack_bar(page, "✅ Shop settings updated successfully!")

        if on_settings_saved:
            on_settings_saved()

    return ft.Container(
        padding=ft.Padding(14, 12, 14, 24),
        content=ft.Column(
            scroll=ft.ScrollMode.AUTO,
            spacing=12,
            controls=[
                ft.Text("Shop Profile & Invoice Settings", size=16, weight=ft.FontWeight.BOLD),
                ft.Text("These details appear on your printed PDF and WhatsApp receipts.", size=12, color=ft.Colors.GREY_600),

                ft.Card(
                    elevation=2,
                    content=ft.Container(
                        padding=14,
                        content=ft.Column(
                            spacing=12,
                            controls=[
                                shop_name_field,
                                phone_field,
                                address_field,
                                currency_field,
                                footer_note_field
                            ]
                        )
                    )
                ),

                ft.FilledButton(
                    "💾 Save Shop Details",
                    icon=ft.Icons.SAVE,
                    style=ft.ButtonStyle(
                        shape=ft.RoundedRectangleBorder(radius=10),
                        padding=ft.Padding(0, 12, 0, 12)
                    ),
                    width=float("inf"),
                    on_click=save_settings
                ),

                ft.Container(height=10),

                # App Info Card
                ft.Card(
                    elevation=1,
                    content=ft.Container(
                        padding=12,
                        content=ft.Column(
                            spacing=4,
                            controls=[
                                ft.Text("About Quick Vendor Invoice", weight=ft.FontWeight.BOLD, size=13),
                                ft.Text("Version: 1.0.0 (Android APK Ready)", size=11, color=ft.Colors.GREY_600),
                                ft.Text("Built with Python & Flet (Flutter UI Engine)", size=11, color=ft.Colors.GREY_600),
                            ]
                        )
                    )
                ),

                ft.Container(height=20)
            ]
        )
    )
