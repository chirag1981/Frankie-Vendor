"""
Catalog / Menu Management View: Add, Edit, Delete items with pre-configured prices.
"""

import flet as ft
from typing import Callable
from app import database, utils


def create_catalog_view(page: ft.Page, on_catalog_changed: Callable = None) -> ft.Control:
    """Builds the Catalog / Menu Items Management View."""
    shop_settings = database.get_shop_settings()
    currency_symbol = shop_settings.get("currency", "₹")

    catalog_items_column = ft.Column(spacing=8)

    def show_item_modal(item_id: int = None, existing_name: str = "", existing_price: float = 0.0, existing_category: str = "Frankie"):
        name_input = ft.TextField(
            label="Item Name",
            value=existing_name,
            capitalization=ft.TextCapitalization.CHARACTERS,
            dense=True,
            border_radius=8
        )
        price_input = ft.TextField(
            label=f"Price ({currency_symbol})",
            value=f"{existing_price:.0f}" if existing_price > 0 else "",
            keyboard_type=ft.KeyboardType.NUMBER,
            dense=True,
            border_radius=8
        )
        category_input = ft.TextField(
            label="Category (e.g. Frankie, Drinks, Snacks)",
            value=existing_category,
            dense=True,
            border_radius=8
        )

        def save_item(e):
            name = name_input.value.strip().upper()
            if not name:
                name_input.error_text = "Name is required"
                name_input.update()
                return

            try:
                price = float(price_input.value or 0)
            except ValueError:
                price_input.error_text = "Valid price required"
                price_input.update()
                return

            category = category_input.value.strip().upper() or "GENERAL"

            if item_id:
                database.update_catalog_item(item_id, name, price, category)
            else:
                try:
                    database.add_catalog_item(name, price, category)
                except Exception:
                    name_input.error_text = "Item with this name already exists"
                    name_input.update()
                    return

            utils.close_dialog(page, dialog)
            load_catalog()
            if on_catalog_changed:
                on_catalog_changed()
            utils.show_snack_bar(page, f"✅ Item '{name}' saved successfully!")

        dialog = ft.AlertDialog(
            title=ft.Text("Edit Item" if item_id else "Add New Item", weight=ft.FontWeight.BOLD, size=16),
            content=ft.Container(
                width=320,
                content=ft.Column(
                    tight=True,
                    spacing=10,
                    controls=[name_input, price_input, category_input]
                )
            ),
            actions=[
                ft.TextButton("Cancel", on_click=lambda e: utils.close_dialog(page, dialog)),
                ft.FilledButton("Save", on_click=save_item)
            ]
        )
        utils.open_dialog(page, dialog)

    def confirm_delete(item_id: int, item_name: str):
        def on_yes(e):
            database.delete_catalog_item(item_id)
            utils.close_dialog(page, dialog)
            load_catalog()
            if on_catalog_changed:
                on_catalog_changed()
            utils.show_snack_bar(page, f"🗑️ Deleted {item_name}")

        dialog = ft.AlertDialog(
            title=ft.Text("Delete Item?", size=16, weight=ft.FontWeight.BOLD),
            content=ft.Text(f"Are you sure you want to remove '{item_name}' from the menu?"),
            actions=[
                ft.TextButton("Cancel", on_click=lambda e: utils.close_dialog(page, dialog)),
                ft.TextButton("Delete", style=ft.ButtonStyle(color=ft.Colors.RED), on_click=on_yes)
            ]
        )
        utils.open_dialog(page, dialog)

    def load_catalog():
        catalog_items_column.controls.clear()
        items = database.get_catalog_items(active_only=False)

        if not items:
            catalog_items_column.controls.append(
                ft.Container(
                    alignment=ft.Alignment(0, 0),
                    padding=40,
                    content=ft.Column(
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                        spacing=8,
                        controls=[
                            ft.Icon(ft.Icons.RESTAURANT_MENU_OUTLINED, size=48, color=ft.Colors.GREY_400),
                            ft.Text("No menu items yet.", size=14, color=ft.Colors.GREY_600),
                            ft.Text("Click '+ Add Item' above to start your menu!", size=12, color=ft.Colors.GREY_500)
                        ]
                    )
                )
            )
            return

        current_cat = None
        for it in items:
            cat = it.get("category", "GENERAL")
            if cat != current_cat:
                current_cat = cat
                catalog_items_column.controls.append(
                    ft.Container(
                        padding=ft.Padding(4, 12, 4, 4),
                        content=ft.Row([
                            ft.Icon(ft.Icons.FOLDER_OPEN, size=16, color=ft.Colors.PRIMARY),
                            ft.Text(f"{current_cat}", weight=ft.FontWeight.BOLD, size=13, color=ft.Colors.PRIMARY)
                        ], spacing=6)
                    )
                )

            card = ft.Card(
                elevation=1,
                shape=ft.RoundedRectangleBorder(radius=10),
                content=ft.Container(
                    padding=ft.Padding(12, 8, 8, 8),
                    content=ft.Row(
                        controls=[
                            ft.Column(
                                controls=[
                                    ft.Text(it["name"], weight=ft.FontWeight.BOLD, size=14),
                                    ft.Container(
                                        padding=ft.Padding(6, 2, 6, 2),
                                        border_radius=6,
                                        bgcolor=ft.Colors.GREEN_50,
                                        content=ft.Text(f"{currency_symbol}{it['price']:.2f}", weight=ft.FontWeight.BOLD, size=12, color=ft.Colors.GREEN_700)
                                    )
                                ],
                                spacing=4,
                                expand=True
                            ),
                            ft.Row(
                                tight=True,
                                controls=[
                                    ft.IconButton(
                                        icon=ft.Icons.EDIT_OUTLINED,
                                        icon_size=20,
                                        tooltip="Edit Price / Name",
                                        on_click=lambda e, item=it: show_item_modal(item["id"], item["name"], item["price"], item["category"])
                                    ),
                                    ft.IconButton(
                                        icon=ft.Icons.DELETE_OUTLINE,
                                        icon_color=ft.Colors.RED_400,
                                        icon_size=20,
                                        tooltip="Remove Item",
                                        on_click=lambda e, item=it: confirm_delete(item["id"], item["name"])
                                    )
                                ],
                                spacing=0
                            )
                        ],
                        alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                    )
                )
            )
            catalog_items_column.controls.append(card)

        try:
            catalog_items_column.update()
        except Exception:
            pass

    load_catalog()

    return ft.Container(
        padding=ft.Padding(14, 12, 14, 24),
        content=ft.Column(
            scroll=ft.ScrollMode.AUTO,
            spacing=12,
            controls=[
                # Top Header Banner
                ft.Card(
                    elevation=1,
                    content=ft.Container(
                        padding=12,
                        content=ft.Row(
                            controls=[
                                ft.Column(
                                    controls=[
                                        ft.Text("Menu & Price Catalog", size=16, weight=ft.FontWeight.BOLD),
                                        ft.Text("Pre-configure items for 1-tap billing", size=11, color=ft.Colors.GREY_600)
                                    ],
                                    spacing=2,
                                    expand=True
                                ),
                                ft.FilledButton(
                                    "+ Add Item",
                                    icon=ft.Icons.ADD,
                                    style=ft.ButtonStyle(
                                        shape=ft.RoundedRectangleBorder(radius=8),
                                        padding=ft.Padding(10, 8, 12, 8)
                                    ),
                                    on_click=lambda e: show_item_modal()
                                )
                            ],
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                        )
                    )
                ),
                catalog_items_column,
                ft.Container(height=24)
            ]
        )
    )
