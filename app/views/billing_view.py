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
            on_change=lambda e: self._on_change()
        )

        self.qty_field = ft.TextField(
            value=str(int(qty) if float(qty).is_integer() else qty),
            keyboard_type=ft.KeyboardType.NUMBER,
            width=55,
            dense=True,
            text_align=ft.TextAlign.CENTER,
            border_radius=8,
            on_change=lambda e: self._on_change()
        )

        self.price_field = ft.TextField(
            value=f"{price:.0f}" if float(price).is_integer() else f"{price:.2f}",
            keyboard_type=ft.KeyboardType.NUMBER,
            width=70,
            dense=True,
            text_align=ft.TextAlign.RIGHT,
            border_radius=8,
            on_change=lambda e: self._on_change()
        )

        self.line_total_text = ft.Text(
            "₹0.00",
            size=14,
            weight=ft.FontWeight.BOLD,
            width=75,
            text_align=ft.TextAlign.RIGHT,
            color=ft.Colors.PRIMARY
        )

        self.minus_btn = ft.IconButton(
            icon=ft.Icons.REMOVE_CIRCLE_OUTLINE,
            icon_size=18,
            tooltip="Decrease Qty",
            on_click=self._decrease_qty
        )

        self.plus_btn = ft.IconButton(
            icon=ft.Icons.ADD_CIRCLE_OUTLINE,
            icon_size=18,
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
                padding=8,
                content=ft.Column(
                    spacing=6,
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
                                ft.Text("×", size=14, color=ft.Colors.GREY_600),
                                self.price_field,
                                ft.Text("=", size=14, color=ft.Colors.GREY_600),
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
                self.qty_field.update()
                self._on_change()
        except ValueError:
            pass

    def _increase_qty(self, e):
        try:
            val = float(self.qty_field.value or 0)
            self.qty_field.value = str(int(val + 1) if (val + 1).is_integer() else (val + 1))
            self.qty_field.update()
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
        size=15,
        weight=ft.FontWeight.BOLD,
        color=ft.Colors.PRIMARY
    )
    date_text = ft.Text(
        datetime.now().strftime("%d-%b-%Y %I:%M %p"),
        size=12,
        color=ft.Colors.GREY_600
    )

    # Customer inputs
    cust_name_field = ft.TextField(
        label="Customer Name (Optional)",
        prefix_icon=ft.Icons.PERSON_OUTLINE,
        dense=True,
        border_radius=8,
        capitalization=ft.TextCapitalization.CHARACTERS,
        expand=True
    )
    cust_phone_field = ft.TextField(
        label="Phone (for WhatsApp Bill)",
        prefix_icon=ft.Icons.PHONE_ANDROID,
        keyboard_type=ft.KeyboardType.PHONE,
        dense=True,
        border_radius=8,
        expand=True
    )

    # Item Rows Column
    items_column = ft.Column(spacing=8)

    # Quick Menu Catalog items chips
    quick_menu_row = ft.Row(wrap=True, spacing=6)

    # Totals Display
    subtotal_text = ft.Text("₹0.00", size=14, weight=ft.FontWeight.W_500)
    discount_field = ft.TextField(
        value="0",
        label="Discount (₹)",
        keyboard_type=ft.KeyboardType.NUMBER,
        dense=True,
        width=110,
        border_radius=8,
        on_change=lambda e: recalculate_totals()
    )
    payment_mode_dropdown = ft.Dropdown(
        label="Payment",
        dense=True,
        width=110,
        border_radius=8,
        value="Cash",
        options=[
            ft.DropdownOption("Cash"),
            ft.DropdownOption("UPI / Online"),
            ft.DropdownOption("Card"),
            ft.DropdownOption("Due / Credit"),
        ]
    )
    grand_total_text = ft.Text(
        "₹0.00",
        size=26,
        weight=ft.FontWeight.BOLD,
        color=ft.Colors.GREEN_600
    )

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
            recalculate_totals()

    def add_item_row(name: str = "", qty: float = 1.0, price: float = 0.0):
        # Check if item with exact name already exists, if so just increase qty!
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
        add_item_row()  # add 1 empty row
        cust_name_field.value = ""
        cust_phone_field.value = ""
        discount_field.value = "0"
        payment_mode_dropdown.value = "Cash"
        inv_number_text.value = f"Invoice: {database.get_next_invoice_number()}"
        date_text.value = datetime.now().strftime("%d-%b-%Y %I:%M %p")
        page.update()
        recalculate_totals()

    def validate_and_collect_data():
        items_data = []
        for ctrl in items_column.controls:
            if isinstance(ctrl, ItemRowControl):
                data = ctrl.get_data()
                if data["item_name"] and data["quantity"] > 0:
                    items_data.append(data)

        if not items_data:
            utils.show_snack_bar(page, "⚠️ Please add at least 1 item with name and price.")
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

        if action_type == "pdf":
            # Generate PDF
            pdf_path = pdf_service.generate_pdf_invoice(current_shop, inv_data, items_data)
            utils.show_snack_bar(
                page,
                text=f"✅ Invoice saved & PDF generated:\n{os.path.basename(pdf_path)}",
                action="Open PDF",
                on_action=lambda e: os.startfile(pdf_path) if hasattr(os, "startfile") else None
            )
        elif action_type == "whatsapp":
            # Generate WhatsApp Text and Open Share link
            wa_text = utils.generate_whatsapp_bill_text(current_shop, inv_data, items_data)
            wa_url = utils.get_whatsapp_share_url(inv_data["customer_phone"], wa_text)
            utils.open_url(page, wa_url)
            utils.show_snack_bar(page, "✅ Invoice saved! Opening WhatsApp...")
        else:
            utils.show_snack_bar(page, f"✅ Invoice #{inv_data['invoice_number']} saved successfully!")

        if on_invoice_created:
            on_invoice_created()

        reset_bill()

    # Initialize with 1 empty item row & load quick menu
    add_item_row()
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
                        content=ft.Column(
                            spacing=4,
                            controls=[
                                ft.Row(
                                    controls=[
                                        ft.Column([
                                            ft.Text(shop_settings.get("shop_name", "MY SHOP"), size=18, weight=ft.FontWeight.BOLD),
                                            date_text,
                                        ]),
                                        ft.Container(
                                            content=inv_number_text,
                                            padding=6,
                                            border_radius=8,
                                            bgcolor=ft.Colors.BLUE_50
                                        )
                                    ],
                                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                                )
                            ]
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

                # Customer Details Card
                ft.Card(
                    elevation=1,
                    content=ft.Container(
                        padding=10,
                        content=ft.Column(
                            spacing=8,
                            controls=[
                                ft.Text("Customer Details (Optional)", size=12, weight=ft.FontWeight.BOLD, color=ft.Colors.GREY_700),
                                ft.Row([cust_name_field, cust_phone_field], spacing=8)
                            ]
                        )
                    )
                ),

                # Line Items Section Header
                ft.Row(
                    controls=[
                        ft.Text("Invoice Items", size=15, weight=ft.FontWeight.BOLD),
                        ft.FilledButton(
                            "Add Custom Item",
                            icon=ft.Icons.ADD,
                            style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=8)),
                            on_click=lambda e: add_item_row()
                        )
                    ],
                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                ),

                # Dynamic Items List
                items_column,

                # Billing Summary Card
                ft.Card(
                    elevation=3,
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
                                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN
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
                                ft.OutlinedButton(
                                    "📄 Save & PDF",
                                    icon=ft.Icons.PICTURE_AS_PDF,
                                    expand=True,
                                    style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=10)),
                                    on_click=lambda e: handle_save_invoice("pdf")
                                ),
                                ft.FilledTonalButton(
                                    "💾 Save Only",
                                    icon=ft.Icons.CHECK,
                                    expand=True,
                                    style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=10)),
                                    on_click=lambda e: handle_save_invoice("save")
                                ),
                                ft.IconButton(
                                    icon=ft.Icons.REFRESH,
                                    tooltip="Reset Bill",
                                    on_click=lambda e: reset_bill()
                                )
                            ],
                            spacing=8
                        )
                    ]
                ),

                ft.Container(height=20)  # bottom padding for mobile navigation bar
            ]
        )
    )
