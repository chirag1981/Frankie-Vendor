"""
Helper utilities: Currency formatting, WhatsApp text generation, and cross-platform UI helpers.
"""

from typing import Dict, List, Any
import urllib.parse
import os


def format_currency(amount: float, symbol: str = "₹") -> str:
    """Formats numeric amount into clean currency string (e.g. ₹150.00)."""
    try:
        val = float(amount or 0.0)
        return f"{symbol}{val:,.2f}"
    except (ValueError, TypeError):
        return f"{symbol}0.00"


def generate_whatsapp_bill_text(
    shop_settings: Dict[str, Any],
    invoice: Dict[str, Any],
    items: List[Dict[str, Any]]
) -> str:
    """
    Constructs a clean, structured, formatted WhatsApp receipt with emojis.
    """
    shop_name = shop_settings.get("shop_name", "OUR SHOP").upper()
    phone = shop_settings.get("phone", "")
    footer_note = shop_settings.get("footer_note", "Thank you for visiting!").strip()
    currency = shop_settings.get("currency", "₹")

    inv_number = invoice.get("invoice_number", "N/A")
    date_str = invoice.get("created_at", "")
    cust_name = invoice.get("customer_name", "Valued Customer")
    payment_mode = invoice.get("payment_mode", "Cash")
    subtotal = float(invoice.get("subtotal", 0.0))
    discount = float(invoice.get("discount", 0.0))
    grand_total = float(invoice.get("grand_total", 0.0))

    lines = [
        f"🧾 *{shop_name}*",
    ]
    if phone:
        lines.append(f"📞 Contact: {phone}")
    lines.append("────────────────────────")
    lines.append(f"📄 *Invoice #:* {inv_number}")
    if date_str:
        lines.append(f"📅 *Date:* {date_str}")
    if cust_name and cust_name != "VALUED CUSTOMER":
        lines.append(f"👤 *Customer:* {cust_name}")
    lines.append("────────────────────────")
    lines.append("*ITEMS & CHARGES:*")

    for idx, it in enumerate(items, start=1):
        name = it.get("item_name", "Item")
        qty = it.get("quantity", 1)
        price = it.get("unit_price", 0.0)
        line_tot = it.get("line_total", 0.0)
        qty_str = str(int(qty) if float(qty).is_integer() else qty)
        lines.append(f"{idx}. {name}")
        lines.append(f"   {qty_str} x {currency}{price:.2f} = *{currency}{line_tot:.2f}*")

    lines.append("────────────────────────")
    lines.append(f"Subtotal: {currency}{subtotal:.2f}")
    if discount > 0:
        lines.append(f"Discount: -{currency}{discount:.2f}")
    lines.append(f"💰 *TOTAL AMOUNT: {currency}{grand_total:.2f}*")
    lines.append(f"💳 Payment Mode: {payment_mode}")

    if footer_note:
        lines.append("")
        lines.append(f"✨ _{footer_note}_")

    return "\n".join(lines)


def get_whatsapp_share_url(phone: str, message: str) -> str:
    """
    Creates a universal direct WhatsApp URL compatible with Android App, iOS, and Web.
    """
    clean_phone = "".join(filter(str.isdigit, phone or ""))
    # If phone is 10 digits (India), prefix 91
    if len(clean_phone) == 10:
        clean_phone = f"91{clean_phone}"

    encoded_msg = urllib.parse.quote(message)
    if clean_phone:
        return f"https://api.whatsapp.com/send?phone={clean_phone}&text={encoded_msg}"
    return f"https://api.whatsapp.com/send?text={encoded_msg}"


def open_url(page: Any, url: str) -> None:
    """Launches a URL seamlessly on Android (opens WhatsApp app directly) and Desktop/Web (opens browser)."""
    import webbrowser
    import flet as ft

    # 1. Primary: Flet UrlLauncher Service with EXTERNAL_APPLICATION mode for Android/iOS
    if hasattr(page, "overlay"):
        launcher = None
        for ctrl in getattr(page, "overlay", []):
            if isinstance(ctrl, ft.UrlLauncher):
                launcher = ctrl
                break
        if not launcher:
            launcher = ft.UrlLauncher()
            page.overlay.append(launcher)
            page.update()
        try:
            launcher.launch_url(url, mode=ft.LaunchMode.EXTERNAL_APPLICATION)
            return
        except Exception as err:
            print(f"[UrlLauncher Warning]: {err}")

    # 2. Secondary: Native Page.launch_url
    if hasattr(page, "launch_url"):
        try:
            page.launch_url(url, web_popup_window_name="_blank")
            return
        except Exception:
            try:
                page.launch_url(url)
                return
            except Exception:
                pass

    # 3. Desktop OS browser fallback
    try:
        webbrowser.open_new_tab(url)
    except Exception:
        try:
            webbrowser.open(url)
        except Exception:
            pass


def share_pdf_file(page: Any, pdf_path: str, message: str = "") -> None:
    """Shares the actual PDF file directly to WhatsApp / Android apps."""
    import flet as ft
    if hasattr(page, "overlay") and pdf_path and os.path.exists(pdf_path):
        share_service = None
        for ctrl in getattr(page, "overlay", []):
            if isinstance(ctrl, ft.Share):
                share_service = ctrl
                break
        if not share_service:
            share_service = ft.Share()
            page.overlay.append(share_service)
            page.update()
        try:
            share_service.share_files(
                [ft.ShareFile(pdf_path)],
                text=message,
                title="Invoice PDF"
            )
            return
        except Exception:
            pass


def copy_to_clipboard(page: Any, text: str) -> None:
    """Copies text to the system clipboard across Android, Web, and Desktop."""
    try:
        page.clipboard = text
        page.update()
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
    if hasattr(page, "update"):
        page.update()


def open_dialog(page: Any, dialog: Any) -> None:
    """Opens an AlertDialog safely using page overlay."""
    dialog.open = True
    if hasattr(page, "overlay"):
        if dialog not in page.overlay:
            page.overlay.append(dialog)
    if hasattr(page, "update"):
        page.update()


def close_dialog(page: Any, dialog: Any) -> None:
    """Closes an AlertDialog safely."""
    dialog.open = False
    if hasattr(page, "update"):
        page.update()
