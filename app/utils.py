"""
Utility functions for text formatting, WhatsApp bill generator, and calculations.
"""

from typing import Any, Dict, List
import urllib.parse


def format_currency(amount: float, symbol: str = "₹") -> str:
    """Formats numeric amount into currency representation."""
    return f"{symbol}{amount:,.2f}"


def generate_whatsapp_bill_text(
    shop_settings: Dict[str, Any],
    invoice: Dict[str, Any],
    items: List[Dict[str, Any]]
) -> str:
    """
    Generates a clean, readable text receipt formatted specifically for WhatsApp messaging.
    """
    currency = shop_settings.get("currency", "₹")
    shop_name = shop_settings.get("shop_name", "SHOP RECEIPT")
    phone = shop_settings.get("phone", "")
    upi_id = shop_settings.get("upi_id", "")
    footer = shop_settings.get("footer_note", "Thank you for your business!")

    lines = []
    lines.append(f"🧾 *{shop_name}*")
    if phone:
        lines.append(f"📞 Contact: {phone}")
    lines.append("────────────────────────")
    lines.append(f"📄 *Invoice #:* {invoice.get('invoice_number', 'N/A')}")
    lines.append(f"📅 *Date:* {invoice.get('created_at', 'N/A')}")
    if invoice.get("customer_name"):
        lines.append(f"👤 *Customer:* {invoice['customer_name']}")
    lines.append("────────────────────────")
    lines.append("*ITEMS & CHARGES:*")

    for idx, item in enumerate(items, 1):
        name = item.get("item_name", "Item")
        qty = item.get("quantity", 1)
        # format quantity cleanly (e.g. 1 instead of 1.0)
        qty_str = f"{int(qty)}" if float(qty).is_integer() else f"{qty:.2f}"
        price = float(item.get("unit_price", 0))
        total = float(item.get("line_total", float(qty) * price))
        lines.append(f"{idx}. {name}")
        lines.append(f"   {qty_str} x {currency}{price:.2f} = *{currency}{total:.2f}*")

    lines.append("────────────────────────")
    lines.append(f"Subtotal: {currency}{float(invoice.get('subtotal', 0)):.2f}")
    if float(invoice.get("discount", 0)) > 0:
        lines.append(f"Discount: -{currency}{float(invoice['discount']):.2f}")
    if float(invoice.get("tax", 0)) > 0:
        lines.append(f"Tax/GST: +{currency}{float(invoice['tax']):.2f}")

    lines.append(f"💰 *TOTAL AMOUNT: {currency}{float(invoice.get('grand_total', 0)):.2f}*")
    lines.append(f"💳 Payment Mode: {invoice.get('payment_mode', 'Cash')}")

    if upi_id:
        lines.append(f"\n📲 *Pay via UPI:* `{upi_id}`")

    if footer:
        lines.append(f"\n✨ _{footer}_")

    return "\n".join(lines)


def get_whatsapp_share_url(phone: str, message: str) -> str:
    """
    Creates a direct WhatsApp API link with encoded text.
    If phone number is provided, targets that number. Otherwise opens generic WhatsApp share.
    """
    clean_phone = "".join(filter(str.isdigit, phone or ""))
    # If phone is 10 digits (India), prefix 91
    if len(clean_phone) == 10:
        clean_phone = f"91{clean_phone}"

    encoded_msg = urllib.parse.quote(message)
    if clean_phone:
        return f"https://wa.me/{clean_phone}?text={encoded_msg}"
    return f"https://api.whatsapp.com/send?text={encoded_msg}"


def open_url(page: Any, url: str) -> None:
    """Launches a URL seamlessly on Android (opens WhatsApp app) and Desktop/Web (opens browser)."""
    import webbrowser
    # 1. Native Flet / Flutter client launcher (Triggers WhatsApp Intent on Android)
    if hasattr(page, "launch_url"):
        try:
            page.launch_url(url, web_popup_window_name="_blank")
        except Exception:
            pass
    # 2. Web browser fallback for desktop testing
    try:
        webbrowser.open(url)
    except Exception:
        pass


def show_snack_bar(page: Any, text: str, action: str = None, on_action: Any = None) -> None:
    """Displays a SnackBar notification safely using page overlay."""
    import flet as ft
    sb = ft.SnackBar(
        content=ft.Text(text),
        open=True,
        action=action,
        on_action=on_action
    )
    if hasattr(page, "overlay"):
        page.overlay.append(sb)
    try:
        page.update()
    except Exception:
        pass


def open_dialog(page: Any, dialog: Any) -> None:
    """Opens an AlertDialog safely using page overlay."""
    dialog.open = True
    if hasattr(page, "overlay") and dialog not in page.overlay:
        page.overlay.append(dialog)
    try:
        page.update()
    except Exception:
        pass


def close_dialog(page: Any, dialog: Any) -> None:
    """Closes an AlertDialog."""
    dialog.open = False
    try:
        page.update()
    except Exception:
        pass

