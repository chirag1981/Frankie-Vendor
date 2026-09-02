"""
PDF Invoice and Thermal Receipt Generator using modern fpdf2 APIs.
"""

from datetime import datetime
import os
from typing import Any, Dict, List
from fpdf import FPDF
from fpdf.enums import XPos, YPos


class ModernInvoicePDF(FPDF):
    """Custom styled FPDF subclass for clean vendor invoices."""

    def __init__(self, shop_name: str = "VENDOR INVOICE", *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.shop_name = shop_name

    def header(self) -> None:
        # Top brand banner
        self.set_fill_color(33, 150, 243)  # Material Blue
        self.rect(0, 0, 210, 8, "F")
        self.ln(5)

    def footer(self) -> None:
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(128, 128, 128)
        self.cell(0, 10, f"Page {self.page_no()}/{{nb}} | Powered by Quick Vendor Invoice", align="C")


def get_pdf_output_dir() -> str:
    """Returns the best storage directory for PDFs across Android and Desktop."""
    # Check if Android Public Downloads is available
    android_public_downloads = "/storage/emulated/0/Download/VendorInvoices"
    try:
        if os.path.exists("/storage/emulated/0/Download"):
            os.makedirs(android_public_downloads, exist_ok=True)
            return android_public_downloads
    except Exception:
        pass

    # App-specific local fallback
    local_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "invoices_pdf")
    os.makedirs(local_dir, exist_ok=True)
    return local_dir


def generate_pdf_invoice(
    shop_settings: Dict[str, Any],
    invoice: Dict[str, Any],
    items: List[Dict[str, Any]],
    output_dir: str = ""
) -> str:
    """
    Generates a professional A4 / A5 PDF receipt and returns the file path.
    """
    if not output_dir:
        output_dir = get_pdf_output_dir()
    os.makedirs(output_dir, exist_ok=True)

    filename = f"Invoice_{invoice.get('invoice_number', 'bill')}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    filepath = os.path.join(output_dir, filename)

    pdf = ModernInvoicePDF(shop_name=shop_settings.get("shop_name", "VENDOR INVOICE"), orientation="P", unit="mm", format=(148, 210))
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()

    currency = shop_settings.get("currency", "Rs.")
    if currency == "₹":
        currency = "Rs."

    # --- Header Section ---
    pdf.set_font("Helvetica", "B", 16)
    pdf.set_text_color(25, 30, 45)
    pdf.cell(0, 8, shop_settings.get("shop_name", "VENDOR INVOICE").upper(), new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="C")

    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(90, 90, 90)
    if shop_settings.get("address"):
        pdf.cell(0, 4, shop_settings["address"], new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="C")
    if shop_settings.get("phone"):
        pdf.cell(0, 4, f"Phone: {shop_settings['phone']}", new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="C")

    pdf.ln(3)
    pdf.set_draw_color(220, 220, 220)
    pdf.line(10, pdf.get_y(), 138, pdf.get_y())
    pdf.ln(4)

    # --- Invoice Info Metadata ---
    pdf.set_font("Helvetica", "B", 9)
    pdf.set_text_color(40, 40, 40)
    pdf.cell(64, 5, f"Invoice: {invoice.get('invoice_number', 'N/A')}", new_x=XPos.RIGHT, new_y=YPos.TOP)
    pdf.cell(64, 5, f"Date: {str(invoice.get('created_at', ''))[:16]}", new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="R")

    if invoice.get("customer_name") or invoice.get("customer_phone"):
        pdf.set_font("Helvetica", "", 9)
        cust_str = f"Customer: {invoice.get('customer_name', 'Walk-in Customer')}"
        if invoice.get("customer_phone"):
            cust_str += f" ({invoice['customer_phone']})"
        pdf.cell(0, 5, cust_str, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    pdf.ln(3)

    # --- Table Header ---
    pdf.set_fill_color(240, 244, 248)
    pdf.set_text_color(30, 41, 59)
    pdf.set_font("Helvetica", "B", 9)
    pdf.cell(10, 7, "#", border=0, fill=True, align="C")
    pdf.cell(60, 7, "ITEM DESCRIPTION", border=0, fill=True)
    pdf.cell(18, 7, "QTY", border=0, fill=True, align="C")
    pdf.cell(20, 7, "RATE", border=0, fill=True, align="R")
    pdf.cell(20, 7, "TOTAL", border=0, fill=True, align="R")
    pdf.ln(7)

    # --- Line Items ---
    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(51, 65, 85)
    pdf.set_draw_color(241, 245, 249)

    for idx, item in enumerate(items, 1):
        name = item.get("item_name", "Item")
        qty = item.get("quantity", 1)
        qty_str = f"{int(qty)}" if float(qty).is_integer() else f"{qty:.2f}"
        rate = float(item.get("unit_price", 0))
        total = float(item.get("line_total", float(qty) * rate))

        # zebra row
        fill = (idx % 2 == 0)
        if fill:
            pdf.set_fill_color(248, 250, 252)
        else:
            pdf.set_fill_color(255, 255, 255)

        pdf.cell(10, 6, str(idx), fill=True, align="C")
        pdf.cell(60, 6, name[:28], fill=True)
        pdf.cell(18, 6, qty_str, fill=True, align="C")
        pdf.cell(20, 6, f"{rate:.2f}", fill=True, align="R")
        pdf.cell(20, 6, f"{total:.2f}", fill=True, align="R")
        pdf.ln(6)

    pdf.set_draw_color(203, 213, 225)
    pdf.line(10, pdf.get_y(), 138, pdf.get_y())
    pdf.ln(3)

    # --- Totals Section ---
    pdf.set_font("Helvetica", "", 9)
    subtotal = float(invoice.get("subtotal", 0))
    discount = float(invoice.get("discount", 0))
    tax = float(invoice.get("tax", 0))
    grand_total = float(invoice.get("grand_total", 0))

    pdf.cell(80, 5, "", new_x=XPos.RIGHT, new_y=YPos.TOP)
    pdf.cell(25, 5, "Subtotal:", align="R")
    pdf.cell(23, 5, f"{currency} {subtotal:.2f}", new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="R")

    if discount > 0:
        pdf.cell(80, 5, "", new_x=XPos.RIGHT, new_y=YPos.TOP)
        pdf.cell(25, 5, "Discount:", align="R")
        pdf.cell(23, 5, f"- {currency} {discount:.2f}", new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="R")

    if tax > 0:
        pdf.cell(80, 5, "", new_x=XPos.RIGHT, new_y=YPos.TOP)
        pdf.cell(25, 5, "Tax/GST:", align="R")
        pdf.cell(23, 5, f"+ {currency} {tax:.2f}", new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="R")

    pdf.set_font("Helvetica", "B", 11)
    pdf.set_text_color(16, 185, 129)  # Green
    pdf.cell(80, 7, f"Paid via: {invoice.get('payment_mode', 'Cash')}", new_x=XPos.RIGHT, new_y=YPos.TOP)
    pdf.cell(25, 7, "Grand Total:", align="R")
    pdf.cell(23, 7, f"{currency} {grand_total:.2f}", new_x=XPos.LMARGIN, new_y=YPos.NEXT, align="R")

    pdf.output(filepath)
    return filepath
