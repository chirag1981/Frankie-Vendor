"""
Billing View: Fast, mobile-optimized invoice creator with quick menu tap-to-add,
real-time calculation, PDF export, and WhatsApp sharing.
"""

from datetime import datetime
import os
import webbrowser
import flet as ft
from typing import Callable, Dict, List, Any
from app import database, pdf_service, utils


class ItemRowControl(ft.Container):
    """Component representing a single bill item line."""

    def __init__(
        self,
        name: str = "",
        qty: float = 1.0,
        price: float = 0.0,
        on_change_callback: Callable = None,
        on_delete_callback: Callable = None
    ):
        super().__init__()
        self.on_change_callback = on_change_callback
        self.on_delete_callback = on_delete_callback

        self.name_field = ft.TextField(
            value=name,
            hint_text="Item name",
            dense=True,
            expand=True,
            capitalization=ft.TextCapitalization.CHARACTERS,
            border_radius=8,
            text_size=14,
            on_change=lambda e: self._on_change()
        )

        self.qty_field = ft.TextField(
            value=str(int(qty) if float(qty).is_integer() else qty),
            keyboard_type=ft.KeyboardType.NUMBER,
            width=50,
            dense=True,
            text_size=14,
            text_align=ft.TextAlign.CENTER,
            border_radius=8,
            on_change=lambda e: self._on_change()
        )

        self.price_field = ft.TextField(
            value=f"{price:.0f}" if float(price).is_integer() else f"{price:.2f}",
            keyboard_type=ft.KeyboardType.NUMBER,
            width=65,
            dense=True,
            text_size=14,
            text_align=ft.TextAlign.RIGHT,
            border_radius=8,
            on_change=lambda e: self._on_change()
        )

        self.line_total_text = ft.Text(
            "₹0.00",
            size=15,
            weight=ft.FontWeight.BOLD,
            width=80,
            text_align=ft.TextAlign.RIGHT,
            color=ft.Colors.PRIMARY
        )

        self.minus_btn = ft.IconButton(
            icon=ft.Icons.REMOVE_CIRCLE_OUTLINE,
            icon_size=20,
            tooltip="Decrease Qty",
            on_click=self._decrease_qty
        )

        self.plus_btn = ft.IconButton(
            icon=ft.Icons.ADD_CIRCLE_OUTLINE,
            icon_size=20,
            tooltip="Increase Qty",
            on_click=self._increase_qty
        )

        self.delete_btn = ft.IconButton(
            icon=ft.Icons.DELETE_OUTLINE,
            icon_color=ft.Colors.RED_400,
            icon_size=20,
            tooltip="Remove Item",
            on_click=lambda e: self.on_delete_callback(self) if self.on_delete_callback else None
        )

        self.content = ft.Card(
            elevation=1,
            shape=ft.RoundedRectangleBorder(radius=10),
            content=ft.Container(
                padding=10,
                content=ft.Column(
                    spacing=8,
                    controls=[
                        ft.Row(
                            controls=[
                                self.name_field,
                                self.delete_btn
                            ],
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                        ),
                        ft.Row(
                            controls=[
                                ft.Row([self.minus_btn, self.qty_field, self.plus_btn], spacing=0),
                                ft.Row([
                                    ft.Text("₹", size=13, color=ft.Colors.GREY_600),
                                    self.price_field
                                ], spacing=2),
                                self.line_total_text
                            ],
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                        )
                    ]
                )
            )
        )
        self._on_change()

    def _decrease_qty(self, e):
        try:
            val = float(self.qty_field.value or 1)
            if val > 1:
                self.qty_field.value = str(int(val - 1) if (val - 1).is_integer() else (val - 1))
                try:
                    self.qty_field.update()
                except Exception:
                    pass
                self._on_change()
        except ValueError:
            pass

    def _increase_qty(self, e):
        try:
            val = float(self.qty_field.value or 0)
            self.qty_field.value = str(int(val + 1) if (val + 1).is_integer() else (val + 1))
            try:
                self.qty_field.update()
            except Exception:
                pass
            self._on_change()
        except ValueError:
            pass

    def _on_change(self):
        try:
            q = float(self.qty_field.value or 0)
            p = float(self.price_field.value or 0)
            tot = q * p
            self.line_total_text.value = f"₹{tot:.2f}"
            self.line_total_text.update()
        except Exception:
            pass

        if self.on_change_callback:
            self.on_change_callback()

    def get_data(self) -> Dict[str, Any]:
        try:
            qty = float(self.qty_field.value or 0)
        except ValueError:
            qty = 0.0
        try:
            price = float(self.price_field.value or 0)
        except ValueError:
            price = 0.0

        return {
            "item_name": self.name_field.value.strip().upper(),
            "quantity": qty,
            "unit_price": price,
            "line_total": round(qty * price, 2)
        }


def create_billing_view(page: ft.Page, on_invoice_created: Callable = None) -> ft.Control:
    """Builds the main Billing / POS View."""
    shop_settings = database.get_shop_settings()
    currency_symbol = shop_settings.get("currency", "₹")

    # Header / Invoice Info
    inv_number_text = ft.Text(
        f"Invoice: {database.get_next_invoice_number()}",
        size=14,
        weight=ft.FontWeight.BOLD,
        color=ft.Colors.PRIMARY
    )
    date_text = ft.Text(
        datetime.now().strftime("%d-%b-%Y %I:%M %p"),
        size=11,
        color=ft.Colors.GREY_600
    )

    # Customer inputs (stacked cleanly in a column so no clipping occurs on mobile)
    cust_name_field = ft.TextField(
        label="Customer Name (Optional)",
        prefix_icon=ft.Icons.PERSON_OUTLINE,
        dense=True,
        border_radius=8,
        capitalization=ft.TextCapitalization.CHARACTERS
    )
    cust_phone_field = ft.TextField(
        label="Phone Number (for WhatsApp Bill)",
        prefix_icon=ft.Icons.PHONE_ANDROID,
        keyboard_type=ft.KeyboardType.PHONE,
        dense=True,
        border_radius=8
    )

    # Item Rows Column
    items_column = ft.Column(spacing=8)

    # Empty state placeholder when no items added yet
    empty_items_placeholder = ft.Container(
        padding=16,
        alignment=ft.Alignment(0, 0),
        content=ft.Column(
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=4,
            controls=[
                ft.Icon(ft.Icons.TOUCH_APP_OUTLINED, color=ft.Colors.PRIMARY, size=28),
                ft.Text("No items added yet.", size=13, weight=ft.FontWeight.W_500),
                ft.Text("Tap any menu item above or click '+ Custom Item'", size=11, color=ft.Colors.GREY_600)
            ]
        )
    )

    items_container = ft.Column(controls=[empty_items_placeholder], spacing=8)

    # Quick Menu Catalog items chips
    quick_menu_row = ft.Row(wrap=True, spacing=6)

    # Totals Display
    subtotal_text = ft.Text("₹0.00", size=15, weight=ft.FontWeight.W_600)
    discount_field = ft.TextField(
        value="0",
        label="Discount (₹)",
        keyboard_type=ft.KeyboardType.NUMBER,
        dense=True,
        expand=1,
        border_radius=8,
        on_change=lambda e: recalculate_totals()
    )
    payment_mode_dropdown = ft.Dropdown(
        label="Payment Mode",
        dense=True,
        expand=1,
        border_radius=8,
        value="Cash",
        options=[
            ft.DropdownOption("Cash"),
            ft.DropdownOption("UPI / Online"),
        ]
    )
    grand_total_text = ft.Text(
        "₹0.00",
        size=26,
        weight=ft.FontWeight.BOLD,
        color=ft.Colors.GREEN_600
    )

    def sync_items_display():
        """Updates the container to show empty placeholder or item cards."""
        if not items_column.controls:
            items_container.controls = [empty_items_placeholder]
        else:
            items_container.controls = [items_column]
        try:
            items_container.update()
        except Exception:
            pass

    def recalculate_totals():
        subtotal = 0.0
        for ctrl in items_column.controls:
            if isinstance(ctrl, ItemRowControl):
                data = ctrl.get_data()
                subtotal += data["line_total"]

        try:
            discount = float(discount_field.value or 0)
        except ValueError:
            discount = 0.0

        grand_total = max(0.0, subtotal - discount)
        subtotal_text.value = f"{currency_symbol}{subtotal:.2f}"
        grand_total_text.value = f"{currency_symbol}{grand_total:.2f}"

        try:
            subtotal_text.update()
            grand_total_text.update()
        except Exception:
            pass

    def remove_item_row(row_ctrl: ItemRowControl):
        if row_ctrl in items_column.controls:
            items_column.controls.remove(row_ctrl)
            try:
                items_column.update()
            except Exception:
                pass
            sync_items_display()
            recalculate_totals()

    def add_item_row(name: str = "", qty: float = 1.0, price: float = 0.0):
        # If item already in list, simply increment quantity
        if name:
            for ctrl in items_column.controls:
                if isinstance(ctrl, ItemRowControl) and ctrl.name_field.value.strip().upper() == name.strip().upper():
                    try:
                        curr_q = float(ctrl.qty_field.value or 0)
                        ctrl.qty_field.value = str(int(curr_q + qty) if (curr_q + qty).is_integer() else (curr_q + qty))
                        try:
                            ctrl.qty_field.update()
                        except Exception:
                            pass
                        ctrl._on_change()
                        return
                    except ValueError:
                        pass

        row = ItemRowControl(
            name=name,
            qty=qty,
            price=price,
            on_change_callback=recalculate_totals,
            on_delete_callback=remove_item_row
        )
        items_column.controls.append(row)
        sync_items_display()
        try:
            items_column.update()
        except Exception:
            pass
        recalculate_totals()

    def load_quick_menu():
        quick_menu_row.controls.clear()
        catalog = database.get_catalog_items(active_only=True)
        if not catalog:
            quick_menu_row.controls.append(
                ft.Text("No menu items saved. Add some in Menu tab!", size=12, italic=True, color=ft.Colors.GREY_500)
            )
            return

        for item in catalog:
            btn = ft.Chip(
                label=ft.Text(f"{item['name']} ({currency_symbol}{item['price']:.0f})", size=12),
                leading=ft.Icon(ft.Icons.FASTFOOD, size=16, color=ft.Colors.ORANGE_700),
                on_click=lambda e, it=item: add_item_row(name=it["name"], qty=1.0, price=it["price"])
            )
            quick_menu_row.controls.append(btn)

    def reset_bill():
        items_column.controls.clear()
        sync_items_display()
        cust_name_field.value = ""
        cust_phone_field.value = ""
        discount_field.value = "0"
        payment_mode_dropdown.value = "Cash"
        inv_number_text.value = f"Invoice: {database.get_next_invoice_number()}"
        date_text.value = datetime.now().strftime("%d-%b-%Y %I:%M %p")
        try:
            page.update()
        except Exception:
            pass
        recalculate_totals()

    def validate_and_collect_data():
        items_data = []
        for ctrl in items_column.controls:
            if isinstance(ctrl, ItemRowControl):
                data = ctrl.get_data()
                if data["item_name"] and data["quantity"] > 0:
                    items_data.append(data)

        if not items_data:
            utils.show_snack_bar(page, "⚠️ Please add at least 1 item to the bill.")
            return None, None

        try:
            discount = float(discount_field.value or 0)
        except ValueError:
            discount = 0.0

        subtotal = sum(it["line_total"] for it in items_data)
        grand_total = max(0.0, subtotal - discount)

        inv_data = {
            "invoice_number": database.get_next_invoice_number(),
            "customer_name": cust_name_field.value.strip().upper(),
            "customer_phone": cust_phone_field.value.strip(),
            "subtotal": subtotal,
            "discount": discount,
            "tax": 0.0,
            "grand_total": grand_total,
            "payment_mode": payment_mode_dropdown.value or "Cash",
            "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        return inv_data, items_data

    def show_receipt_modal(inv_data: Dict[str, Any], items_data: List[Dict[str, Any]], pdf_path: str = ""):
        current_shop = database.get_shop_settings()
        wa_text = utils.generate_whatsapp_bill_text(current_shop, inv_data, items_data)
        wa_url = utils.get_whatsapp_share_url(inv_data["customer_phone"], wa_text)

        items_display = []
        for idx, it in enumerate(items_data, 1):
            items_display.append(
                ft.Row(
                    controls=[
                        ft.Text(f"{idx}. {it['item_name']}", size=13, weight=ft.FontWeight.W_500, expand=True),
                        ft.Text(f"{it['quantity']} × {currency_symbol}{it['unit_price']:.2f}", size=12, color=ft.Colors.GREY_600),
                        ft.Text(f"{currency_symbol}{it['line_total']:.2f}", size=13, weight=ft.FontWeight.BOLD)
                    ],
                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                )
            )

        def on_whatsapp_click(e):
            utils.open_url(page, wa_url)
            utils.show_snack_bar(page, "💬 Opening WhatsApp...")

        def on_copy_click(e):
            utils.copy_to_clipboard(page, wa_text)
            utils.show_snack_bar(page, "📋 Bill copied to clipboard! You can paste anywhere.")

        dialog = ft.AlertDialog(
            title=ft.Row([
                ft.Text(f"Invoice {inv_data['invoice_number']}", weight=ft.FontWeight.BOLD, size=16),
                ft.Container(
                    content=ft.Text(inv_data.get("payment_mode", "Cash"), size=11, color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.GREEN_600 if inv_data.get("payment_mode") == "Cash" else ft.Colors.BLUE_600,
                    padding=ft.Padding(8, 2, 8, 2),
                    border_radius=12
                )
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            content=ft.Container(
                width=340,
                content=ft.Column(
                    tight=True,
                    spacing=8,
                    controls=[
                        ft.Text(f"Date: {inv_data.get('created_at', '')}", size=11, color=ft.Colors.GREY_600),
                        ft.Text(
                            f"Customer: {inv_data['customer_name'] or 'Walk-in'}" + (f" ({inv_data['customer_phone']})" if inv_data.get("customer_phone") else ""),
                            size=12
                        ),
                        ft.Divider(),
                        ft.Text("Items:", weight=ft.FontWeight.BOLD, size=12),
                        ft.Column(controls=items_display, spacing=3),
                        ft.Divider(),
                        ft.Row(
                            [ft.Text("Subtotal:", size=12), ft.Text(f"{currency_symbol}{inv_data['subtotal']:.2f}", size=12)],
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                        ),
                        ft.Row(
                            [ft.Text("Discount:", size=12), ft.Text(f"-{currency_symbol}{inv_data['discount']:.2f}", size=12)],
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                        ) if inv_data.get('discount', 0) > 0 else ft.Container(),
                        ft.Row(
                            [ft.Text("Grand Total:", size=15, weight=ft.FontWeight.BOLD), ft.Text(f"{currency_symbol}{inv_data['grand_total']:.2f}", size=16, weight=ft.FontWeight.BOLD, color=ft.Colors.GREEN_600)],
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                        ),
                        ft.Container(
                            padding=ft.Padding(6, 4, 6, 4),
                            border_radius=6,
                            bgcolor=ft.Colors.GREY_100,
                            content=ft.Text(
                                f"📄 PDF saved in: {os.path.basename(pdf_path)}" if pdf_path else "📄 PDF saved in Downloads/VendorInvoices",
                                size=10,
                                color=ft.Colors.GREY_700
                            )
                        )
                    ]
                )
            ),
            actions=[
                ft.FilledButton("WhatsApp", icon=ft.Icons.SEND, url=wa_url, style=ft.ButtonStyle(bgcolor=ft.Colors.GREEN_600), on_click=on_whatsapp_click),
                ft.OutlinedButton("Copy Text", icon=ft.Icons.COPY, on_click=on_copy_click),
                ft.TextButton("New Bill", on_click=lambda e: utils.close_dialog(page, dialog))
            ],
            actions_alignment=ft.MainAxisAlignment.END
        )
        utils.open_dialog(page, dialog)

    def handle_save_invoice(action_type: str = "save"):
        inv_data, items_data = validate_and_collect_data()
        if not inv_data:
            return

        inv_id = database.create_invoice(
            invoice_number=inv_data["invoice_number"],
            customer_name=inv_data["customer_name"],
            customer_phone=inv_data["customer_phone"],
            items=items_data,
            discount=inv_data["discount"],
            tax=inv_data["tax"],
            payment_mode=inv_data["payment_mode"]
        )

        current_shop = database.get_shop_settings()
        pdf_path = pdf_service.generate_pdf_invoice(current_shop, inv_data, items_data)

        if action_type == "whatsapp":
            wa_text = utils.generate_whatsapp_bill_text(current_shop, inv_data, items_data)
            wa_url = utils.get_whatsapp_share_url(inv_data["customer_phone"], wa_text)
            utils.open_url(page, wa_url)
            show_receipt_modal(inv_data, items_data, pdf_path)
            utils.show_snack_bar(page, "✅ Invoice saved & opening WhatsApp!")
        else:
            show_receipt_modal(inv_data, items_data, pdf_path)
            utils.show_snack_bar(page, f"✅ Invoice #{inv_data['invoice_number']} saved successfully!")

        if on_invoice_created:
            on_invoice_created()

        reset_bill()

    # Load initial menu catalog (starts without any blank items)
    load_quick_menu()

    # Main Billing View UI Container
    return ft.Container(
        padding=ft.Padding(12, 8, 12, 8),
        content=ft.Column(
            scroll=ft.ScrollMode.AUTO,
            spacing=12,
            controls=[
                # Top Shop Banner & Invoice Meta
                ft.Card(
                    elevation=2,
                    content=ft.Container(
                        padding=12,
                        content=ft.Row(
                            controls=[
                                ft.Column([
                                    ft.Text(shop_settings.get("shop_name", "MY SHOP"), size=17, weight=ft.FontWeight.BOLD),
                                    date_text,
                                ], spacing=2),
                                ft.Container(
                                    content=inv_number_text,
                                    padding=ft.Padding(8, 4, 8, 4),
                                    border_radius=8,
                                    bgcolor=ft.Colors.BLUE_50
                                )
                            ],
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                        )
                    )
                ),

                # Quick Add Menu Section
                ft.ExpansionTile(
                    title=ft.Text("⚡ Quick Tap Menu / Catalog", size=14, weight=ft.FontWeight.W_600),
                    subtitle=ft.Text("Tap any item to add instantly to bill", size=11, color=ft.Colors.GREY_600),
                    leading=ft.Icon(ft.Icons.FASTFOOD, color=ft.Colors.ORANGE_500),
                    expanded=True,
                    controls=[
                        ft.Container(
                            padding=8,
                            content=quick_menu_row
                        )
                    ]
                ),

                # Customer Details (Collapsible / Clean)
                ft.ExpansionTile(
                    title=ft.Text("👤 Customer Details (Optional)", size=13, weight=ft.FontWeight.W_600),
                    leading=ft.Icon(ft.Icons.PERSON_OUTLINE, color=ft.Colors.BLUE_500),
                    controls=[
                        ft.Container(
                            padding=10,
                            content=ft.Column(
                                spacing=8,
                                controls=[cust_name_field, cust_phone_field]
                            )
                        )
                    ]
                ),

                # Line Items Section Header
                ft.Row(
                    controls=[
                        ft.Text("Invoice Items", size=15, weight=ft.FontWeight.BOLD),
                        ft.FilledButton(
                            "+ Custom Item",
                            icon=ft.Icons.ADD,
                            style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=8)),
                            on_click=lambda e: add_item_row()
                        )
                    ],
                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                ),

                # Dynamic Items List or Empty Placeholder
                items_container,

                # Billing Summary Card
                ft.Card(
                    elevation=2,
                    bgcolor=ft.Colors.SURFACE_CONTAINER_HIGHEST,
                    content=ft.Container(
                        padding=14,
                        content=ft.Column(
                            spacing=10,
                            controls=[
                                ft.Row(
                                    controls=[
                                        ft.Text("Subtotal:", size=14),
                                        subtotal_text
                                    ],
                                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                                ),
                                ft.Row(
                                    controls=[
                                        discount_field,
                                        payment_mode_dropdown
                                    ],
                                    spacing=10
                                ),
                                ft.Divider(thickness=1),
                                ft.Row(
                                    controls=[
                                        ft.Text("Grand Total:", size=18, weight=ft.FontWeight.BOLD),
                                        grand_total_text
                                    ],
                                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                                )
                            ]
                        )
                    )
                ),

                # Action Buttons
                ft.Column(
                    spacing=8,
                    controls=[
                        ft.FilledButton(
                            "💬 Save & Send WhatsApp Bill",
                            icon=ft.Icons.SEND,
                            style=ft.ButtonStyle(
                                bgcolor=ft.Colors.GREEN_600,
                                shape=ft.RoundedRectangleBorder(radius=10),
                                padding=ft.Padding(0, 12, 0, 12)
                            ),
                            width=float("inf"),
                            on_click=lambda e: handle_save_invoice("whatsapp")
                        ),
                        ft.Row(
                            controls=[
                                ft.FilledTonalButton(
                                    "💾 Save Invoice",
                                    icon=ft.Icons.CHECK,
                                    expand=True,
                                    style=ft.ButtonStyle(
                                        shape=ft.RoundedRectangleBorder(radius=10),
                                        padding=ft.Padding(0, 12, 0, 12)
                                    ),
                                    on_click=lambda e: handle_save_invoice("save")
                                ),
                                ft.IconButton(
                                    icon=ft.Icons.REFRESH,
                                    tooltip="Clear Bill",
                                    on_click=lambda e: reset_bill()
                                )
                            ],
                            spacing=8
                        )
                    ]
                ),

                ft.Container(height=25)
            ]
        )
    )
