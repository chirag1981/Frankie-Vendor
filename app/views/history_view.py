"""
Invoice History View: View past bills, search by customer or bill number,
view item breakdowns, re-print PDF, and reshare via WhatsApp.
"""

from datetime import datetime
import os
import webbrowser
import flet as ft
from typing import Dict, Any
from app import database, pdf_service, utils


def create_history_view(page: ft.Page) -> ft.Control:
    """Builds the Invoice History View with search and analytics."""
    shop_settings = database.get_shop_settings()
    currency_symbol = shop_settings.get("currency", "₹")

    # KPI summary metrics
    today_sales_text = ft.Text("₹0.00", size=18, weight=ft.FontWeight.BOLD, color=ft.Colors.GREEN_600)
    today_count_text = ft.Text("0 Bills", size=12, color=ft.Colors.GREY_600)
    total_sales_text = ft.Text("₹0.00", size=18, weight=ft.FontWeight.BOLD, color=ft.Colors.BLUE_600)
    total_count_text = ft.Text("0 Bills", size=12, color=ft.Colors.GREY_600)

    invoices_list_column = ft.Column(spacing=8)

    def refresh_summary():
        stats = database.get_sales_summary()
        today_sales_text.value = f"{currency_symbol}{stats['today_sales']:.2f}"
        today_count_text.value = f"{stats['today_bills']} Bills Today"
        total_sales_text.value = f"{currency_symbol}{stats['total_sales']:.2f}"
        total_count_text.value = f"{stats['total_bills']} Total Bills"
        try:
            today_sales_text.update()
            today_count_text.update()
            total_sales_text.update()
            total_count_text.update()
        except Exception:
            pass

    def show_invoice_details(inv_id: int):
        full_inv = database.get_invoice_by_id(inv_id)
        if not full_inv:
            return

        current_shop = database.get_shop_settings()
        wa_text = utils.generate_whatsapp_bill_text(current_shop, full_inv, full_inv.get("items", []))
        wa_url = utils.get_whatsapp_share_url(full_inv.get("customer_phone", ""), wa_text)

        items_display = []
        for idx, it in enumerate(full_inv.get("items", []), 1):
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

        def reshare_wa(e):
            utils.open_url(page, wa_url)
            utils.show_snack_bar(page, "💬 Opening WhatsApp...")

        def copy_text(e):
            utils.copy_to_clipboard(page, wa_text)
            utils.show_snack_bar(page, "📋 Bill copied to clipboard! You can paste anywhere.")

        def reprint_pdf(e):
            pdf_path = pdf_service.generate_pdf_invoice(current_shop, full_inv, full_inv.get("items", []))
            utils.show_snack_bar(page, f"📄 PDF saved in Downloads: {os.path.basename(pdf_path)}")

        def confirm_delete_inv(e):
            database.delete_invoice(inv_id)
            utils.close_dialog(page, dialog)
            load_invoices()
            refresh_summary()
            utils.show_snack_bar(page, f"🗑️ Invoice #{full_inv['invoice_number']} deleted.")

        dialog = ft.AlertDialog(
            title=ft.Row([
                ft.Text(f"Invoice {full_inv['invoice_number']}", weight=ft.FontWeight.BOLD, size=16),
                ft.Container(
                    content=ft.Text(full_inv.get("payment_mode", "Cash"), size=11, color=ft.Colors.WHITE),
                    bgcolor=ft.Colors.BLUE_600,
                    padding=ft.Padding(8, 2, 8, 2),
                    border_radius=12
                )
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            content=ft.Container(
                width=350,
                content=ft.Column(
                    tight=True,
                    spacing=8,
                    controls=[
                        ft.Text(f"Date: {full_inv['created_at']}", size=12, color=ft.Colors.GREY_600),
                        ft.Text(
                            f"Customer: {full_inv['customer_name'] or 'Walk-in'}" + (f" ({full_inv['customer_phone']})" if full_inv.get("customer_phone") else ""),
                            size=12
                        ),
                        ft.Divider(),
                        ft.Text("Items:", weight=ft.FontWeight.BOLD, size=13),
                        ft.Column(controls=items_display, spacing=4),
                        ft.Divider(),
                        ft.Row(
                            [ft.Text("Subtotal:", size=12), ft.Text(f"{currency_symbol}{full_inv['subtotal']:.2f}", size=12)],
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                        ),
                        ft.Row(
                            [ft.Text("Discount:", size=12), ft.Text(f"-{currency_symbol}{full_inv['discount']:.2f}", size=12)],
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                        ) if full_inv['discount'] > 0 else ft.Container(),
                        ft.Row(
                            [ft.Text("Grand Total:", size=15, weight=ft.FontWeight.BOLD), ft.Text(f"{currency_symbol}{full_inv['grand_total']:.2f}", size=16, weight=ft.FontWeight.BOLD, color=ft.Colors.GREEN_600)],
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                        ),
                    ]
                )
            ),
            actions=[
                ft.FilledButton("WhatsApp", icon=ft.Icons.SEND, url=wa_url, style=ft.ButtonStyle(bgcolor=ft.Colors.GREEN_600), on_click=reshare_wa),
                ft.OutlinedButton("Copy Text", icon=ft.Icons.COPY, on_click=copy_text),
                ft.IconButton(icon=ft.Icons.PICTURE_AS_PDF, tooltip="Save PDF", on_click=reprint_pdf),
                ft.IconButton(icon=ft.Icons.DELETE_OUTLINE, tooltip="Delete Invoice", icon_color=ft.Colors.RED_400, on_click=confirm_delete_inv),
                ft.TextButton("Close", on_click=lambda e: utils.close_dialog(page, dialog))
            ],
            actions_alignment=ft.MainAxisAlignment.END
        )
        utils.open_dialog(page, dialog)

    def load_invoices(query: str = ""):
        invoices_list_column.controls.clear()
        invoices = database.get_invoices(search_query=query, limit=50)

        if not invoices:
            invoices_list_column.controls.append(
                ft.Container(
                    alignment=ft.Alignment(0, 0),
                    padding=20,
                    content=ft.Column(
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                        controls=[
                            ft.Icon(ft.Icons.RECEIPT_LONG_OUTLINED, size=48, color=ft.Colors.GREY_400),
                            ft.Text("No invoices found.", color=ft.Colors.GREY_600, size=14)
                        ]
                    )
                )
            )
        else:
            for inv in invoices:
                card = ft.Card(
                    elevation=1,
                    shape=ft.RoundedRectangleBorder(radius=10),
                    content=ft.ListTile(
                        leading=ft.CircleAvatar(
                            content=ft.Icon(ft.Icons.RECEIPT, size=18, color=ft.Colors.WHITE),
                            bgcolor=ft.Colors.PRIMARY
                        ),
                        title=ft.Row([
                            ft.Text(inv["invoice_number"], weight=ft.FontWeight.BOLD, size=14),
                            ft.Text(f"{currency_symbol}{inv['grand_total']:.2f}", weight=ft.FontWeight.BOLD, size=15, color=ft.Colors.GREEN_600)
                        ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                        subtitle=ft.Text(
                            f"{inv['created_at'][:16]} • {inv.get('customer_name') or 'Walk-in'} ({inv['item_count']} items)",
                            size=11,
                            color=ft.Colors.GREY_600
                        ),
                        trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT, color=ft.Colors.GREY_400),
                        on_click=lambda e, i_id=inv["id"]: show_invoice_details(i_id)
                    )
                )
                invoices_list_column.controls.append(card)

        try:
            invoices_list_column.update()
        except Exception:
            pass

    search_field = ft.TextField(
        hint_text="Search by invoice #, customer name...",
        prefix_icon=ft.Icons.SEARCH,
        dense=True,
        border_radius=10,
        expand=True,
        on_change=lambda e: load_invoices(e.control.value)
    )

    # Initial load
    load_invoices()

    return ft.Container(
        padding=ft.Padding(12, 8, 12, 8),
        content=ft.Column(
            scroll=ft.ScrollMode.AUTO,
            spacing=12,
            controls=[
                # KPI Tiles
                ft.Row(
                    controls=[
                        ft.Card(
                            elevation=2,
                            expand=True,
                            content=ft.Container(
                                padding=12,
                                content=ft.Column(
                                    spacing=2,
                                    controls=[
                                        ft.Text("Today's Sales", size=11, color=ft.Colors.GREY_700),
                                        today_sales_text,
                                        today_count_text
                                    ]
                                )
                            )
                        ),
                        ft.Card(
                            elevation=2,
                            expand=True,
                            content=ft.Container(
                                padding=12,
                                content=ft.Column(
                                    spacing=2,
                                    controls=[
                                        ft.Text("Total Revenue", size=11, color=ft.Colors.GREY_700),
                                        total_sales_text,
                                        total_count_text
                                    ]
                                )
                            )
                        )
                    ],
                    spacing=8
                ),

                # Search and Filter
                ft.Row([
                    search_field,
                    ft.IconButton(
                        icon=ft.Icons.REFRESH,
                        on_click=lambda e: (refresh_summary(), load_invoices(search_field.value))
                    )
                ]),

                ft.Text("Recent Invoices", size=15, weight=ft.FontWeight.BOLD),

                # Invoices List
                invoices_list_column,

                ft.Container(height=20)
            ]
        )
    )
